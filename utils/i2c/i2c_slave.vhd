library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_slave is
generic
(
  ADDRESS_LEN: integer := 7
);

port
(
  -- main system clock for synchronous operation
  clk: in std_logic;

  -- module reset : active high
  reset: in std_logic;

  -- I2C signals
  scl: in std_logic;
  sda: inout std_logic;

  -- data to TX
  dt: in std_logic_vector(7 downto 0);

  -- data RXed
  dr: out std_logic_vector(7 downto 0);

  -- high when I2C is selected and active
  active: out std_logic;

  -- i2c busy
  busy: out std_logic;

  -- high when read transaction, low for write transaction
  rw: out std_logic;

  -- slave address 
  address: in std_logic_vector(ADDRESS_LEN - 1 downto 0);

  -- 8 bit byte mark 
  byte_mark: out std_logic
);
end i2c_slave;

architecture Behavioral of i2c_slave is
type state_type is (s_idle, s_start, s_addr, s_rw, s_addr_ack, s_data, s_data_ack);

signal state_reg, state_next: state_type;

-- keep sample data for 3 clocks for various purposes
signal scl_sample: std_logic_vector(2 downto 0);
signal sda_sample: std_logic_vector(2 downto 0);

signal bit_ndx, bit_ndx_next: integer range 0 to 7;

signal addr_rx, addr_rx_next: std_logic_vector(ADDRESS_LEN - 1 downto 0);
signal rx_buf, rx_buf_next: std_logic_vector(7 downto 0);

signal rw_reg, rw_reg_next: std_logic;

signal drv_low, drv_low_next: std_logic;

signal sclk_begin, sclk_end, rx_sample: std_logic;

signal start_cond, stop_cond: std_logic;
signal is_my_addr: std_logic;

signal byte_mark_reg, byte_mark_next: std_logic;

signal read_end_reg, read_end_next: std_logic;
begin

  ----------------------------------------------
  -- synchronous state logic & signal sampling
  ----------------------------------------------
  process(clk, reset)
  begin
    if reset = '1' then
      scl_sample <= (others => '1');
      sda_sample <= (others => '1');
      state_reg <= s_idle;
      bit_ndx <= 0;
      addr_rx <= (others => '0');
      rx_buf <= (others => '0');
      rw_reg <= '0';
      drv_low <= '0';
      byte_mark_reg <= '0';
      read_end_reg <= '0';
    elsif rising_edge(clk) then
      scl_sample <= scl_sample(1 downto 0) & scl;
      sda_sample <= sda_sample(1 downto 0) & sda;

      state_reg <= state_next;
      bit_ndx <= bit_ndx_next;
      addr_rx <= addr_rx_next;
      rx_buf <= rx_buf_next;
      rw_reg <= rw_reg_next;
      drv_low <= drv_low_next;
      byte_mark_reg <= byte_mark_next;
      read_end_reg <= read_end_next;
    end if;
  end process;

  ----------------------------------------------
  -- main SM
  ----------------------------------------------
  process(state_reg, start_cond, stop_cond, bit_ndx, sclk_end, read_end_reg)
  begin
    state_next <= state_reg;

    if stop_cond = '1' then
      -- if stop condition occurs for any reason, just return to idle
      state_next <= s_idle;
    elsif start_cond = '1' then
      -- if start condition occurs for any reason, just return to s_addr
      state_next <= s_start;
    elsif sclk_end = '1' then
      case state_reg is
        when s_start =>
          state_next <= s_addr;

        when s_addr =>
          if bit_ndx = (ADDRESS_LEN - 1) then
            state_next <= s_rw;
          end if;

        when s_rw =>
          state_next <= s_addr_ack;

        when s_addr_ack =>
          state_next <= s_data;

        when s_data =>
          if bit_ndx = 7 then
            state_next <= s_data_ack;
          end if;

        when s_data_ack =>
          if read_end_reg = '1' then
            -- got NAK from the sender in read transaction,
            -- which means it's the end of transaction
            state_next <= s_idle;
          else
            state_next <= s_data;
          end if; 

        when others =>
          -- nothing to do

      end case;
    end if;
  end process;

  ----------------------------------------------
  -- rx logic SM
  ----------------------------------------------
  process(state_reg, start_cond, stop_cond, bit_ndx,
          rx_sample, sda_sample, rw_reg, rx_buf, addr_rx, sclk_end,
          read_end_reg)
  begin
    bit_ndx_next <= bit_ndx;
    addr_rx_next <= addr_rx;
    rw_reg_next <= rw_reg;
    rx_buf_next <= rx_buf;
    read_end_next <= read_end_reg;

    if start_cond = '1' or stop_cond = '1' then
      bit_ndx_next <= 0;
      rw_reg_next <= '0';
      addr_rx_next <= (others => '0');
      rx_buf_next <= (others => '0');
      read_end_next <= '0';
    else
      case state_reg is
        when s_addr =>
          if rx_sample = '1' then
            addr_rx_next <= addr_rx(ADDRESS_LEN - 2 downto 0) & sda_sample(0);
          end if;

          if sclk_end = '1' then
            if bit_ndx = (ADDRESS_LEN - 1) then
              bit_ndx_next <= 0;
            else
              bit_ndx_next <= bit_ndx + 1;
            end if;
          end if;

        when s_rw =>
          if rx_sample = '1' then
            rw_reg_next <= sda_sample(0);
          end if;

        when s_addr_ack =>
          if sclk_end = '1' then
            bit_ndx_next <= 0;
          end if;

        when s_data =>
          if rx_sample = '1' and rw_reg = '0' then
            -- write operation so receive data
            rx_buf_next <= rx_buf(6 downto 0) & sda_sample(0);
          end if;

          if sclk_end = '1' then
            if bit_ndx = 7 then
              bit_ndx_next <= 0;
            else
              bit_ndx_next <= bit_ndx + 1;
            end if;
          end if;

        when s_data_ack =>
          if rx_sample = '1' and rw_reg = '1' then
            -- read ack from the sender
            read_end_next <= sda_sample(0); -- high is NAK
          end if;

        when others =>
      end case;
    end if;
  end process;

  ---------------------------------------------------------
  -- byte mark SM. always at rx sample point of ACK state
  ---------------------------------------------------------
  process(state_reg, rx_sample, byte_mark_reg)
  begin
    byte_mark_next <= '0';
    if rx_sample = '1' and (state_reg = s_addr_ack or state_reg = s_data_ack) then
      byte_mark_next <= '1';
    end if;
  end process;

  ----------------------------------------------
  -- tx logic SM
  ----------------------------------------------
  process(state_reg, start_cond, stop_cond, bit_ndx,
          rw_reg, drv_low, is_my_addr, sclk_begin, sclk_end, dt)
  begin
    drv_low_next <= drv_low;

    if start_cond = '1' or stop_cond = '1' or is_my_addr = '0' then
      drv_low_next <= '0';
    else
      case state_reg is
        when s_addr_ack =>
          if sclk_begin = '1' then
            drv_low_next <= '1';
          elsif sclk_end = '1' then
            drv_low_next <= '0';
          end if;

        when s_data =>
          if rw_reg = '1' then
            -- read operation so send data
            if sclk_begin = '1' then
              drv_low_next <= (not dt(7 - bit_ndx));
            elsif sclk_end = '1' then
              drv_low_next <= '0';
            end if;
          end if;

        when s_data_ack =>
          if rw_reg = '0' then
            -- write operation so give ack
            if sclk_begin = '1' then
              drv_low_next <= '1';
            elsif sclk_end = '1' then
              drv_low_next <= '0';
            end if;
          end if;

        when others =>
      end case;
    end if;
  end process;

  ----------------------------------------------
  -- internal wires
  ----------------------------------------------
  -- SCLK begin point, one clock after SCL falling edge
  sclk_begin <=  '1' when scl_sample = "100" else
                 '0';

  -- SCLK end point, at falling edge
  sclk_end <= '1' when scl_sample = "110" else
              '0';

  -- RX sample point, one clock after SCL rising edge
  rx_sample <= '1' when scl_sample = "011" else
               '0';

  -- start condition, SDA high to low when SCL is high
  --start_cond <= '1' when (sda_sample(1 downto 0) = "10") and (scl_sample(1 downto 0) = "11") else
  start_cond <= '1' when (sda_sample = "110") and (scl_sample = "111") else
                '0';

  -- stop condition, SDA low to high when SCL is high
  --stop_cond <= '1' when (sda_sample(1 downto 0) = "01") and (scl_sample(1 downto 0) = "11") else
  stop_cond <= '1' when (sda_sample = "001") and (scl_sample = "111") else
               '0';

  is_my_addr <= '1' when addr_rx = address else
                '0';

  ----------------------------------------------
  -- outputs
  ----------------------------------------------
  busy <= '0' when state_reg = s_idle else
          '1';

  -- high output should be driven by bus pull up
  -- low output should be driven by slave
  -- if no output, bus should not be driven(same as high output)
  -- sda goes high by pull up when master relinquishes bus
  sda <= '0' when drv_low = '1' else
         'Z';

  dr <= rx_buf;

  rw <= rw_reg;

  active <= '1' when (state_reg /= s_idle) and (is_my_addr = '1') else
            '0'; 

  byte_mark <= byte_mark_reg;

end Behavioral;

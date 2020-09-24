library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is
port
(
  clk, reset: in std_logic;
  s_ss, s_clk, s_mosi: in std_logic;
  s_miso: out std_logic;
  spi_rx: out std_logic_vector(7 downto 0);
  spi_tx: in std_logic_vector(7 downto 0);
  byte_rdy_tick: out std_logic;
  spi_busy: out std_logic
);
end spi_slave;

architecture arch of spi_slave is
  type state_type is (idle, data);

  signal state_reg, state_next: state_type;
  signal n_reg, n_next: unsigned(2 downto 0);             -- counter for number of data rxed
  signal b_reg, b_next: std_logic_vector(7 downto 0);     -- SPI rx data buffer
  signal t_reg, t_next: std_logic;                        -- SPI tx data
  signal br_reg, br_next: std_logic;

  signal sclk_rising: std_logic; 
  signal sclk_falling: std_logic; 
begin
  --============================================================================
  -- SPI clock rising/falling edge detector
  --============================================================================
  spi_clk_detector: entity work.edge_detector(arch)
  port map
  (
    clk => clk,
    reset => reset,
    level => s_clk,
    rising => sclk_rising,
    falling => sclk_falling
  );

  --============================================================================
  -- FSMD state & data registers
  --============================================================================
  process(clk, reset)
  begin
    if reset = '1'
    then
      state_reg <= idle;
      n_reg <= (others => '0');
      b_reg <= (others => '0');
      t_reg <= '0';
      br_reg <= '0';
    elsif rising_edge(clk)
    then
      state_reg <= state_next;
      n_reg <= n_next;
      b_reg <= b_next;
      t_reg <= t_next;
      br_reg <= br_next;
    end if;
  end process;

  --============================================================================
  -- next-state logic & data path functional units/routing
  --============================================================================
  process(state_reg, n_reg, b_reg, t_reg, s_ss, sclk_rising, sclk_falling, s_mosi, spi_tx)
  begin
    state_next <= state_reg;
    n_next <= n_reg;
    b_next <= b_reg;
    t_next <= t_reg;

    br_next <= '0';

    case state_reg is
      when idle =>
        if s_ss = '0'
        then
          state_next <= data;
          n_next <= (others => '0');
          t_next <= '0';
        end if;

      when data =>
        if s_ss = '1'
        then
          state_next <= idle;
        else
          if sclk_rising = '1'
          then
            -- TX data
            t_next <= spi_tx(7 - to_integer(n_reg));
          elsif sclk_falling = '1'
          then
            -- sample rx data
            b_next <= b_reg(6 downto 0) & s_mosi;
            if n_reg = 7
            then
              n_next <= (others => '0');
              br_next <= '1';
            else
              n_next <= n_reg + 1;
            end if;
          end if;
        end if;
    end case;
  end process;

  spi_rx <= b_reg;
  s_miso <= t_reg when state_reg /= idle else
            'Z';
  spi_busy <= '1' when state_reg /= idle else
              '0';
  byte_rdy_tick <= br_reg;
end arch;

--============================================================================
-- testbench
--============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity spi_slave_testbench is
end spi_slave_testbench;

architecture tb_arch of spi_slave_testbench is
  constant T: time := 20ns;
  constant T2: time := 40ns;
  constant TX_PATTERN: std_logic_vector(15 downto 0) := "1010101010101010";

  signal clk: std_logic;
  signal reset: std_logic;
  signal s_ss: std_logic;
  signal s_clk: std_logic;
  signal s_mosi: std_logic;
  signal s_miso: std_logic;
  signal spi_rx: std_logic_vector(7 downto 0);
  signal spi_tx: std_logic_vector(7 downto 0);
  signal bready: std_logic;
  signal busy: std_logic;
begin
  -- instantiate the circuit under test
  uut: entity work.spi_slave(arch)
  port map
  (
    clk => clk,
    reset => reset,
    s_ss => s_ss,
    s_clk => s_clk,
    s_mosi => s_mosi,
    s_miso => s_miso,
    spi_rx => spi_rx,
    spi_tx => spi_tx,
    byte_rdy_tick => bready,
    spi_busy => busy
  );

  -- clock. 20ns running forever
  process
  begin
    clk <= '0';
    wait for T/2;
    clk <= '1';
    wait for T/2;
  end process;

  -- reset asserted for T*3
  reset <= '1', '0' after T*3;

  process
  begin
    s_ss <= '1';
    s_clk <= '0';
    s_mosi <= '0';

    spi_tx <= (others => '0');

    wait until falling_edge(reset);

    -- chip select
    s_ss <= '0';
    wait for T2;

    for i in 0 to 15 loop
      -- clock rising
      s_clk <= '1';
      -- TX
      s_mosi <= TX_PATTERN(15 - i);
      wait for T2;

      -- clock falling
      s_clk <= '0';
      wait for T2;

    end loop;

    -- chip unselect
    wait for T2;
    s_ss <= '1';
    wait for T2;
  end process;
end tb_arch;

library IEEE;
use IEEE.std_logic_1164.all;

entity led_controller2 is
port
(
  clk: in std_logic;
  reset: in std_logic;
  leds: out std_logic_vector(7 downto 0);
  spi_rx_data: in std_logic_vector(7 downto 0);
  spi_tx_data: out std_logic_vector(7 downto 0);
  spi_byte_rdy: in std_logic;
  spi_busy: in std_logic
);
end led_controller2;

architecture arch of led_controller2 is
  type state_type is (wait_for_command, wait_for_address, wait_for_data);
  type register_type is (version_register, led_register, def_register);

  signal state_reg, state_next: state_type;
  signal sel_reg, sel_reg_next: register_type;

  signal is_write_cmd_reg, is_write_cmd_next: std_logic;

  signal led_reg, led_reg_next: std_logic_vector(7 downto 0);
  signal ver_reg, ver_reg_next: std_logic_vector(7 downto 0);
  signal def_reg, def_reg_next: std_logic_vector(7 downto 0);
begin
  --============================================================================
  -- Commands
  -- 00000001 : Read Command
  -- 00000010 : Write Command
  --
  -- Registers
  -- 00000000 : version register
  -- 00000001 : led control register
  --============================================================================

  --============================================================================
  -- FSMD state & data registers
  --============================================================================
  process(clk, reset)
  begin
    if reset = '1'
    then
      state_reg <= wait_for_command;
      is_write_cmd_reg <= '0';

      led_reg <= (others => '0');
      ver_reg <= "00000001";
      def_reg <= (others => '0');

      sel_reg <= def_register;
    elsif rising_edge(clk)
    then
      state_reg <= state_next;
      sel_reg <= sel_reg_next;
      is_write_cmd_reg <= is_write_cmd_next;

      ver_reg <= ver_reg_next;
      def_reg <= def_reg_next;
      led_reg <= led_reg_next;
    end if;
  end process;

  --============================================================================
  -- next-state logic & data path functional units/routing
  --============================================================================
  process(state_reg, led_reg, ver_reg, def_reg, sel_reg, is_write_cmd_reg, spi_rx_data, spi_byte_rdy, spi_busy)
  begin
    state_next <= state_reg;
    is_write_cmd_next <= is_write_cmd_reg;

    ver_reg_next <= ver_reg;
    def_reg_next <= def_reg;
    led_reg_next <= led_reg;

    sel_reg_next <= sel_reg;

    if spi_busy = '0'
    then
      state_next <= wait_for_command;
      sel_reg_next <= def_register;
    elsif spi_byte_rdy = '1'
    then
      case state_reg is
        when wait_for_command =>
          if spi_rx_data = "00000010"
          then
            is_write_cmd_next <= '1';
          else
            is_write_cmd_next <= '0';
          end if;
          state_next <= wait_for_address;

        when wait_for_address =>
          case spi_rx_data is
            when "00000000" =>
              sel_reg_next <= version_register;

            when "00000001" =>
              sel_reg_next <= led_register;

            when others =>
              sel_reg_next <= def_register;
          end case;
          state_next <= wait_for_data;

        when wait_for_data =>
          state_next <= wait_for_command;
          if is_write_cmd_reg = '1'
          then
            case sel_reg is
              when led_register =>
                led_reg_next <= spi_rx_data;

              when others =>
                -- nothing to do

            end case;
          end if;
      end case;
    end if;
  end process;

  leds <= led_reg;

  with sel_reg select
  spi_tx_data <= ver_reg when version_register,
                 led_reg when led_register,
                 def_reg when others;

end arch;

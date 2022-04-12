library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_controller is
port
(
  clk: in std_logic;
  reset: in std_logic;
  dr: in std_logic_vector(7 downto 0);
  dt: out std_logic_vector(7 downto 0);
  rw: in std_logic;
  byte_mark: in std_logic;
  i2c_active: in std_logic;
  leds: out std_logic_vector(7 downto 0)
);
end led_controller;

architecture Behavioral of led_controller is
type state_type is (s_idle, s_read, s_write);

signal state_reg, state_next: state_type;
signal led_reg, led_reg_next: std_logic_vector(7 downto 0);

begin

  process(clk, reset)
  begin
    if reset = '1' then
      state_reg <= s_idle;
      led_reg <= (others => '0');
    elsif rising_edge(clk) then
      state_reg <= state_next;
      led_reg <= led_reg_next;
    end if;
  end process;

  process(state_reg, i2c_active, byte_mark, rw, led_reg, dr)
  begin
    state_next <= state_reg;
    led_reg_next <= led_reg;

    if i2c_active = '0' then
      state_next <= s_idle;
    else
      if byte_mark = '1' then
        case state_reg is
          when s_idle =>
            if rw = '1' then
              state_next <= s_read;
            else
              state_next <= s_write;
            end if;

          when s_read =>
            state_next <= s_idle;

          when s_write =>
            state_next <= s_idle;
            led_reg_next <= dr;
        end case;
      end if;
    end if;
  end process;

  leds <= led_reg;
  dt <= led_reg;

end Behavioral;

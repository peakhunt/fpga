library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity mojo_blink_top is
port
(
  clk_50: in std_logic;
  rst_n: in std_logic;
  leds: out std_logic_vector(7 downto 0)
);
end mojo_blink_top;

architecture arch of mojo_blink_top is
  signal reset: std_logic;
  signal clk: std_logic;
  signal t_cnt: integer range 0 to 31;
  signal clk_div: std_logic;

begin
  -- make reset active high
  reset <= not rst_n;
  clk <= clk_50;
  
  clk_div1: entity work.clock_divider(Behavioral)
  generic map
  (
    MAX => 1000000
  )
  port map
  (
    clk => clk,
    reset => reset,
    clk_out => clk_div
  );

  process(clk_div,reset)
  begin
    if reset = '1' then
      t_cnt <= 0;
    elsif rising_edge(clk_div) then
      t_cnt <= t_cnt + 1;
    end if;
  end process;
  
  with t_cnt select
    leds <= "00000000" when 0,
            "00000001" when 1,
            "00000011" when 2,
            "00000111" when 3,
            "00001111" when 4,
            "00011111" when 5,
            "00111111" when 6,
            "01111111" when 7,
            "11111111" when 8,
            "11111110" when 9,
            "11111100" when 10,
            "11111000" when 11,
            "11110000" when 12,
            "11100000" when 13,
            "11000000" when 14,
            "10000000" when 15,
            "00000000" when 16,
            "10000000" when 17,
            "11000000" when 18,
            "11100000" when 19,
            "11110000" when 20,
            "11111000" when 21,
            "11111100" when 22,
            "11111110" when 23,
            "11111111" when 24,
            "01111111" when 25,
            "00111111" when 26,
            "00011111" when 27,
            "00001111" when 28,
            "00000111" when 29,
            "00000011" when 30,
            "00000001" when 31,
            "00000000" when others;
end arch;

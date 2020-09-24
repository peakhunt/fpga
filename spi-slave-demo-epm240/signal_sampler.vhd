library ieee;
use ieee.std_logic_1164.all;

entity signal_sampler is
port
(
  clk: in std_logic;
  reset: in std_logic;
  in_ss: in std_logic;
  in_clk: in std_logic;
  in_mosi: in std_logic;
  out_ss: out std_logic;
  out_clk: out std_logic;
  out_mosi: out std_logic
);
end signal_sampler;

architecture arch of signal_sampler is
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      out_ss <= '1';
      out_clk <= '0';
      out_mosi <= '0';
    elsif rising_edge(clk)
    then
      out_ss <= in_ss;
      out_clk <= in_clk;
      out_mosi <= in_mosi;
    end if;
  end process;
end arch;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:47:41 03/14/2022 
-- Design Name: 
-- Module Name:    clock_divider - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_divider is
generic
(
  MAX: integer := 25000
);

port
(
  clk: in std_logic;
  reset: in std_logic;
  clk_out: out std_logic
);
end clock_divider;

architecture Behavioral of clock_divider is
signal count: integer range 1 to MAX := 1;
signal tmp: std_logic := '0';
begin

  process(clk, reset)
  begin
    if (reset = '1') then
      count <= 1;
      tmp <= '0';
    elsif rising_edge(clk) then
      if (count = MAX) then
        tmp <= not tmp;
        count <= 1;
      else
        count <= count + 1;
      end if;
    end if;
  end process;
  
  clk_out <= tmp;
end Behavioral;

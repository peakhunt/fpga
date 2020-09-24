library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity simple_counter is
	port
	(
		CLOCK_5 : in std_logic;
		counter_out : out std_logic_vector(31 downto 0)
	);
end simple_counter;

architecture my_counter of simple_counter is
	signal t_cnt : unsigned(31 downto 0);
begin
	process (CLOCK_5)
	begin
		if rising_edge(CLOCK_5)
		then
			t_cnt <= t_cnt + 1;
		end if;
	end process;
	
	counter_out <= std_logic_vector(t_cnt);
end my_counter;
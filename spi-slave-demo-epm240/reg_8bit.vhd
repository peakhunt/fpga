library IEEE;
use IEEE.std_logic_1164.all;

-- entity
entity reg_8bit is
port (
	D : in std_logic_vector(7 downto 0);
	R : in std_logic;
	CLK : in std_logic;
	Q : out std_logic_vector(7 downto 0)
);
end reg_8bit;

-- architecture
architecture syn of reg_8bit is
begin
	process (R,CLK)
	begin
		if (R = '1')
		then
			Q <= "00000000";
		elsif (rising_edge(CLK))
		then
			Q <= D;
		end if;
	end process;
end syn;

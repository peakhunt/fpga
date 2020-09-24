library IEEE;
use IEEE.std_logic_1164.all;


entity my_first_fpga is
	port
	(
		clock_50 : in std_logic;
		led: out std_logic_vector(3 downto 0);
		key0: in std_logic
	);
end my_first_fpga;

architecture syn of my_first_fpga is
	component mega_pll
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component;
	
	component simple_counter
		port
		(
			CLOCK_5 : in std_logic;
			counter_out : out std_logic_vector(31 downto 0)
		);
	end component;
	
	component my_lpm_mux
		port
		(
			data0x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
			data1x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
			sel		: IN STD_LOGIC ;
			result		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
		);
	end component;

	signal pll_clock: std_logic;
	signal counter: std_logic_vector(31 downto 0);
begin

	pll0 : mega_pll
	port map
	(
		inclk0 => clock_50,
		c0 => pll_clock
	);
	
	cnt0: simple_counter
	port map
	(
		CLOCK_5 => pll_clock,
		counter_out => counter
	);
	
	mux: my_lpm_mux
	port map
	(
		data0x => counter(24 downto 21),
		-- data1x => counter(26 downto 23),
		data1x => counter(22 downto 19),
		result => led,
		sel => key0
	);
end syn;
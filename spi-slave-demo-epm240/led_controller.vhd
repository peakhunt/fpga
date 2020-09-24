library IEEE;
use IEEE.std_logic_1164.all;

entity led_controller is
port
(
	clk: in std_logic;			-- system main clock XXX SPI clock
	reset: in std_logic;		-- async reset
		
	leds: out std_logic_vector(7 downto 0);
	spi_rx_data: in std_logic_vector(7 downto 0);
	spi_tx_data: out std_logic_vector(7 downto 0);
	spi_byte_rdy: in std_logic;
	spi_busy: in std_logic
);
end led_controller;

architecture syn of led_controller is
	type state_type is
	(
		WAITING_FOR_COMMAND,
		WAITING_FOR_ADDRESS_FOR_READ_CMD,
		WAITING_FOR_ADDRESS_FOR_WRITE_CMD,
		EXECUTING_VERSION_READ_CMD,
		EXECUTING_LED_READ_CMD,
		WAITING_FOR_DATA_FOR_LED_WRITE_CMD,	
		WAITING_FOR_DATA_FOR_OTHER_CMD
	);
	signal led_out: std_logic_vector(7 downto 0) := "00000000";
	signal state: state_type;
	
	--signal fsm_clk: std_logic := '0';
	
	component reg_8bit
	port
	(
		D : in std_logic_vector(7 downto 0);
		R : in std_logic;
		CLK : in std_logic;
		Q : out std_logic_vector(7 downto 0)
	);
	end component;
	
	signal ver_sig : std_logic_vector(7 downto 0);
	signal def_sig : std_logic_vector(7 downto 0);
	
	signal led_reg_in: std_logic_vector(7 downto 0);
	
	signal bready: std_logic;
	signal prev_bready: std_logic;
	signal bready_rising: std_logic;
begin

	process(clk, reset)
	begin
		if reset = '1'
		then 
			bready <= '0';
			prev_bready <= '0';
		elsif rising_edge(clk)
		then
			prev_bready <= bready;
			bready <= spi_byte_rdy;
		end if;
	end process;
	
	bready_rising <= not prev_bready and bready;
	
	ver_reg: reg_8bit
	port map
	(
		D => "00000001",
		R => reset,
		CLK => clk,
		Q => ver_sig
	);
	
	def_reg: reg_8bit
	port map
	(
		D => "00000000",
		R => reset,
		CLK => clk,
		Q => def_sig
	);
	
	--
	-- FSM synchronization and reset handling
	--
	sync_proc: process(reset, clk, spi_busy)
	begin
		if reset = '1'
		then
			state <= WAITING_FOR_COMMAND;
			led_reg_in <= "00000000";
		elsif spi_busy = '0'
		then
			state <= WAITING_FOR_COMMAND;
		elsif rising_edge(clk)
		then
			if bready_rising = '1'
			then
				case state is
				when WAITING_FOR_COMMAND =>
					case spi_rx_data is
						when "00000001" =>	-- read command
							state <= WAITING_FOR_ADDRESS_FOR_READ_CMD;
							
						when "00000010" =>	-- write command
							state <= WAITING_FOR_ADDRESS_FOR_WRITE_CMD;
							
						when others =>
							state <= WAITING_FOR_COMMAND;
					end case;
					
				when WAITING_FOR_ADDRESS_FOR_READ_CMD =>
					case spi_rx_data is
						when "00000000" =>	-- version register
							state <= EXECUTING_VERSION_READ_CMD;
							
						when "00000001" =>	-- led control register
							state <= EXECUTING_LED_READ_CMD;
							
						when others =>
							state <= WAITING_FOR_COMMAND;
					end case;
					
				when WAITING_FOR_ADDRESS_FOR_WRITE_CMD =>
					case spi_rx_data is
						when "00000000" => -- version register
							state <= WAITING_FOR_DATA_FOR_OTHER_CMD;
							
						when "00000001" => -- led control register
							state <= WAITING_FOR_DATA_FOR_LED_WRITE_CMD;
						
						when others =>
							state <= WAITING_FOR_DATA_FOR_OTHER_CMD;
					end case;
					
				when EXECUTING_VERSION_READ_CMD =>
					state <= WAITING_FOR_COMMAND;
					
				when EXECUTING_LED_READ_CMD =>
					state <= WAITING_FOR_COMMAND;
					
				when WAITING_FOR_DATA_FOR_LED_WRITE_CMD =>
					led_reg_in <= spi_rx_data;
					state <= WAITING_FOR_COMMAND;
					
				when WAITING_FOR_DATA_FOR_OTHER_CMD =>
					state <= WAITING_FOR_COMMAND;
					
				end case;
			end if;
		end if;
	end process sync_proc;
	
	--
	-- signal mapping
	--
	with state select
	spi_tx_data <=	  ver_sig when EXECUTING_VERSION_READ_CMD,
                    led_reg_in when EXECUTING_LED_READ_CMD,
                    def_sig when others;
	leds <= led_reg_in;
end syn;

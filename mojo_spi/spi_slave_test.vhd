--============================================================================
-- testbench
--============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_slave_testbench is
end spi_slave_testbench;

architecture tb_arch of spi_slave_testbench is

constant T: time := 20ps;
constant S: time := 80ps;
constant C: time := 0ps;

signal clk: std_logic;
signal reset: std_logic;
signal miso: std_logic;
signal mosi: std_logic;
signal sclk: std_logic;
signal cs_n: std_logic;
signal dt: std_logic_vector(7 downto 0);
signal dr: std_logic_vector(7 downto 0);
signal dready: std_logic;
signal active: std_logic;

begin

  uut: entity work.spi_slave(Behavioral)
  generic map
  (
    DATA_WIDTH => 8
  )
  port map
  (
    clk => clk,
    reset => reset,
    miso => miso,
    mosi => mosi,
    sclk => sclk,
    cs_n => cs_n,
    dt => dt,
    dr => dr,
    dready => dready,
    active => active
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
    dt <= (others => '0');
    cs_n <= '1';
    mosi <= '0';
    sclk <= '0';

    wait until falling_edge(reset);
    wait for 100ns;

    cs_n <= '0';
    wait for C;

    -- rx 10101010
    -- tx 01011100
    dt <= "01011100";

    -- bit 7
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 6
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 5
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 4
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 3
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 2
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 1
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 0
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;
    
    -- rx 10010110
    -- tx 01011100
    dt <= "10100101";

    -- bit 7
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 6
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 5
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 4
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 3
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 2
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 1
    mosi <= '1';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    -- bit 0
    mosi <= '0';
    sclk <= '1';
    wait for S;
    sclk <= '0';
    wait for S;

    wait for C;
    cs_n <= '1';

  end process;
end tb_arch;

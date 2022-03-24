--============================================================================
-- testbench
--============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mojo_blink_top_testbench is
end mojo_blink_top_testbench;

architecture tb_arch of mojo_blink_top_testbench is
constant T: time := 20ps;
constant S: time := 80ps;
constant C: time := 40ps;

signal clk: std_logic;
signal rst_n: std_logic;
signal miso: std_logic;
signal mosi: std_logic;
signal sclk: std_logic;
signal cs_n: std_logic;
signal leds: std_logic_vector(7 downto 0);

signal td1: std_logic_vector(15 downto 0) := "0000001010101010";
signal td2: std_logic_vector(15 downto 0) := "0000000101010101";

begin
  uut: entity work.mojo_blink_top(arch)
  port map
  (
    clk_50 => clk,
    rst_n => rst_n,
    leds => leds,
    spi_miso => miso,
    spi_mosi => mosi,
    spi_clk => sclk,
    spi_cs_n => cs_n
  );

  -- clock. 20ns running forever
  process
  begin
    clk <= '0';
    wait for T/2;
    clk <= '1';
    wait for T/2;
  end process;

  process
  begin
    cs_n <= '1';
    mosi <= '0';
    sclk <= '0';

    wait for 10ns;

    -- led write
    -- "00000010 11110000"
    cs_n <= '0';
    wait for C;

    for I in 0 to 15 loop
      mosi <= td1(15 - I);
      sclk <= '1';
      wait for S;
      sclk <= '0';
      wait for S;
    end loop;

    cs_n <= '1';
    wait for C;

    cs_n <= '0';
    wait for C;

    -- then led read back
    -- "00000001 11111111"
    for I in 0 to 15 loop
      mosi <= td2(15 - I);
      sclk <= '1';
      wait for S;
      sclk <= '0';
      wait for S;
    end loop;

    cs_n <= '1';
  end process;

end tb_arch;

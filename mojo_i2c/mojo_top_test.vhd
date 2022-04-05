--============================================================================
-- testbench
--============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mojo_top_testbench is
end mojo_top_testbench;

architecture tb_arch of mojo_top_testbench is
constant T: time := 20ps;
constant S: time := 200ps;

signal clk: std_logic;
signal rst_n: std_logic;
signal scl: std_logic;
signal sda: std_logic;
signal leds: std_logic_vector(7 downto 0) := "10101010";

--signal td1: std_logic_vector(8 downto 0) := "10010111Z";
--signal td1: std_logic_vector(17 downto 0) := "10010111ZZZZZZZZZ0"; 
signal td1: std_logic_vector(17 downto 0) := "10010110Z10101010Z"; 

signal read_back: std_logic;
begin
  uut: entity work.mojo_top(arch)
  port map
  (
    clk_50 => clk,
    rst_n => rst_n,
    leds => leds,
    i2c_scl => scl,
    i2c_sda => sda
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
    rst_n <= '1';

    scl <= '1';
    sda <= '1';
    wait for 10ns;

    -- start condition
    sda <= '0';  -- high to low transition while SCL is high
    wait for S;
    scl <= '0';

    --
    -- data transmission
    --
    for I in 1 to td1'LENGTH loop
      sda <= td1(td1'LENGTH - I);
      wait for S;

      scl <= '1';
      wait for S;

      read_back <= sda;

      scl <= '0';
    end loop;

    wait for S;
    scl <= '1';

    wait for S;

    -- stop condition
    sda <= '0';
    scl <= '1';
    wait for S;
    sda <= '1'; -- low to high transition while SCL is high
  end process;

end tb_arch;

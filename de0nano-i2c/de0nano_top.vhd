library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity de0nano_top is
port
(
  clk_50: in std_logic;
  rst_n: in std_logic;
  leds: out std_logic_vector(7 downto 0);
  i2c_scl: in std_logic;
  i2c_sda: inout std_logic
);
end de0nano_top;

architecture arch of de0nano_top is
signal reset: std_logic;
signal reset_comb: std_logic;
signal clk: std_logic;
signal startup_reset: std_logic;

signal dt: std_logic_vector(7 downto 0);
signal dr: std_logic_vector( 7 downto 0);
signal rw: std_logic;

signal byte_mark: std_logic;
signal active: std_logic;
begin

  clk <= clk_50;

  ---------------------------------------------------------
  -- start-up reset
  ---------------------------------------------------------
  process(clk)
    variable counter: integer range 0 to 3 := 0;
  begin
    if rising_edge(clk) then
      if counter = 3 then
        startup_reset  <= '0';
      else
        startup_reset <= '1';
        counter := counter + 1;
      end if;
    end if;
  end process;

  ---------------------------------------------------------
  -- reset logic
  ---------------------------------------------------------
  reset_comb <= (not rst_n) or startup_reset;
  process(clk)
  begin
    if rising_edge(clk) then
      reset <= reset_comb;
    end if;
  end process;

  ---------------------------------------------------------
  -- component instantiation
  ---------------------------------------------------------
  i2c1: entity work.i2c_slave(Behavioral)
  generic map
  (
    ADDRESS_LEN => 7
  )
  port map
  (
    clk => clk,
    reset => reset,
    scl => i2c_scl,
    sda => i2c_sda,
    dt => dt,
    dr => dr,
    active => active,
    busy => open,
    rw => rw,
    address => "1001011",
    byte_mark => byte_mark
  );

  lc1: entity work.led_controller(Behavioral)
  port map
  (
    clk => clk,
    reset => reset,
    dr => dr,
    dt => dt,
    rw => rw,
    byte_mark => byte_mark,
    i2c_active => active,
    leds => leds
  );
end arch;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity mojo_blink_top is
port
(
  clk_50: in std_logic;
  rst_n: in std_logic;
  leds: out std_logic_vector(7 downto 0);
  spi_miso: out std_logic;
  spi_mosi: in std_logic;
  spi_clk: in std_logic;
  spi_cs_n: in std_logic
);
end mojo_blink_top;

architecture arch of mojo_blink_top is
  signal reset: std_logic;

  signal spi_rx: std_logic_vector(7 downto 0);
  signal spi_tx: std_logic_vector(7 downto 0);
  signal spi_dready: std_logic;
  signal spi_active: std_logic;

  signal clk: std_logic;
  signal startup_reset: std_logic;

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
  reset <= (not rst_n) or startup_reset;

  ---------------------------------------------------------
  -- component instantiation
  ---------------------------------------------------------
  sslave1: entity work.spi_slave(Behavioral)
  generic map
  (
    DATA_WIDTH => 8
  )
  port map
  (
    clk => clk,
    reset => reset,
    miso => spi_miso,
    mosi => spi_mosi,
    sclk => spi_clk,
    cs_n => spi_cs_n,
    dt => spi_tx,
    dr => spi_rx,
    dready => spi_dready,
    active => spi_active
  );

  shandelr1: entity work.spi_slave_handler(Behavioral)
  port map
  (
    clk => clk,
    reset => reset,
    dout => spi_tx,
    din => spi_rx,
    dready => spi_dready,
    active => spi_active,
    leds => leds
  );

end arch;

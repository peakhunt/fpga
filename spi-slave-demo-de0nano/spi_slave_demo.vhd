library ieee;
use ieee.std_logic_1164.all;

entity spi_slave_demo is
port
(
  clk_50: in std_logic;
  reset: in std_logic;
  s_ss: in std_logic;
  s_clk: in std_logic;
  s_mosi: in std_logic;
  s_miso: out std_logic;
  leds: out std_logic_vector(7 downto 0)
);
end spi_slave_demo;

architecture arch of spi_slave_demo is
  signal spi_ss, spi_clk, spi_mosi: std_logic;

  signal startup_rst: std_logic;
  signal sys_rst: std_logic;
  
  signal spi_rx: std_logic_vector(7 downto 0);
  signal spi_tx: std_logic_vector(7 downto 0);

  signal spi_byte_rdy: std_logic;
  signal spi_busy: std_logic;

  signal gclk: std_logic;
begin
  pll_clock: entity work.altpll_100
  port map
  (
    inclk0 => clk_50,
    c0 => gclk
  );

  reset_proc: process(gclk)
    variable counter: integer range 0 to 255 := 0;
  begin
    if rising_edge(gclk)
    then
      if counter < 16
      then
        startup_rst <= '1';
        counter := counter + 1;
      else
        startup_rst <= '0';
      end if;
    end if;
  end process reset_proc;
  sys_rst <= startup_rst or reset;

  sampler: entity work.signal_sampler(arch)
  port map
  (
    clk => gclk,
    reset => sys_rst,
    in_ss => s_ss,
    in_clk => s_clk,
    in_mosi => s_mosi,
    out_ss => spi_ss,
    out_clk => spi_clk,
    out_mosi => spi_mosi
  );

  spi_slave1: entity work.spi_slave(arch)
  port map
  (
    clk => gclk,
    reset => sys_rst,
    s_ss => spi_ss,
    s_clk => spi_clk,
    s_mosi => spi_mosi,
    s_miso => s_miso,
    spi_rx => spi_rx,
    spi_tx => spi_tx,
    byte_rdy_tick => spi_byte_rdy,
    spi_busy => spi_busy
  );

  led_ctrl: entity work.led_controller2(arch)
  port map
  (
    clk => gclk,
    reset => sys_rst,
    leds => leds,
    spi_rx_data => spi_rx,
    spi_tx_data => spi_tx,
    spi_byte_rdy => spi_byte_rdy,
    spi_busy => spi_busy
  );
end arch;

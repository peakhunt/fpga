library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_demo is
port
(
  clk: in std_logic;
  rx: in std_logic;
  tx: out std_logic
);
end uart_demo;

architecture arch of uart_demo is
  signal reset: std_logic;

  signal rx_sample: std_logic := '1';
  signal rx_data: std_logic_vector(7 downto 0);
  signal tx_data: std_logic_vector(7 downto 0);
  signal rx_fifo_empty: std_logic;
begin

  -- start-up reset counter
  process(clk)
    variable counter: integer range 0 to 255 := 0;
  begin
    if rising_edge(clk)
    then
      if counter < 16
      then
        reset <= '1';
        counter := counter + 1;
      else
        reset <= '0';
      end if;
    end if;
  end process;

  -- rx signal sampling
  process(clk, reset)
  begin
    if reset = '1'
    then
      rx_sample <= '1';
    elsif rising_edge(clk)
    then
      rx_sample <= rx;
    end if;
  end process;

  uart_loop: entity work.uart(str_arch)
  port map
  (
    clk => clk,
    reset => reset,
    rd_uart => not rx_fifo_empty,
    wr_uart => not rx_fifo_empty,
    rx => rx_sample,
    w_data => tx_data,
    tx_full => open,
    rx_empty => rx_fifo_empty,
    r_data => rx_data,
    tx => tx
  );

  tx_data <= rx_data;
end arch;

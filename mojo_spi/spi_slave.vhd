----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:30:55 03/16/2022 
-- Design Name: 
-- Module Name:    spi_slave - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_slave is
generic
(
  DATA_WIDTH: integer := 8
);

port
(
  -- main system clock for synchronous operation
  clk: in std_logic;

  -- module reset : active high
  reset: in std_logic;

  -- SPI slave wires
  miso: out std_logic;
  mosi: in std_logic;
  sclk: in std_logic;
  cs_n: in std_logic;

  -- data to tx for spi slave
  dt: in std_logic_vector(DATA_WIDTH - 1 downto 0);

  -- data rxed by spi slave
  dr: out std_logic_vector(DATA_WIDTH - 1 downto 0);

  -- rx data ready signal
  dready: out std_logic;

  -- SPI transaction active
  active: out std_logic
);
end spi_slave;

architecture Behavioral of spi_slave is

-- to manage internal state machine
signal bit_ndx, bit_ndx_next: integer range 0 to DATA_WIDTH - 1;
signal data_received, data_received_next: std_logic_vector(DATA_WIDTH - 1 downto 0);
signal data_ready, data_ready_next: std_logic;

signal sclk_sample: std_logic_vector(1 downto 0);

signal sclk_falling, sclk_rising: std_logic;

signal s_mosi: std_logic;
signal spi_active: std_logic;

signal tx_bit, tx_bit_next: std_logic;

begin
  ----------------------------------------
  -- synchronous state logic & signal sampling
  ----------------------------------------
  process(clk, reset)
  begin
    if reset = '1' then
      bit_ndx <= 0;
      data_received <= (others => '0');
      data_ready <= '0';

      s_mosi <= '0';
      spi_active <= '0';
      sclk_sample <= "00";

      tx_bit <= '0';
    elsif rising_edge(clk) then
      bit_ndx <= bit_ndx_next;
      data_received <= data_received_next;

      data_ready <= data_ready_next;

      s_mosi <= mosi;
      spi_active <= not cs_n;
      sclk_sample <= sclk_sample(0) & sclk;

      tx_bit <= tx_bit_next;
    end if;
  end process;

  sclk_falling <= '1' when sclk_sample = "10" else
                  '0';

  sclk_rising <= '1' when sclk_sample = "01" else
                 '0';

  ----------------------------------------
  -- bit ndx SM
  ----------------------------------------
  process(spi_active, sclk_falling, bit_ndx)
  begin
    bit_ndx_next <= bit_ndx;
    if spi_active = '0' then
      bit_ndx_next <= 0;
    elsif sclk_falling = '1' then
      if bit_ndx = (DATA_WIDTH - 1) then
        bit_ndx_next <= 0;
      else
        bit_ndx_next <= bit_ndx + 1;
      end if;
    end if;
  end process;

  ----------------------------------------
  -- data ready SM
  ----------------------------------------
  process(spi_active, sclk_falling, bit_ndx, data_ready)
  begin
    data_ready_next <= '0';
    if spi_active = '1' and sclk_falling = '1' and bit_ndx = (DATA_WIDTH-1) then
      data_ready_next <= '1';
    end if;
  end process;

  ----------------------------------------
  -- rx data SM
  ----------------------------------------
  process(spi_active, sclk_falling, data_received, s_mosi)
  begin
    data_received_next <= data_received;
    if spi_active = '0' then
      data_received_next <= (others => '0');
    elsif spi_active = '1' and sclk_falling = '1' then
      data_received_next <= data_received(DATA_WIDTH - 2 downto 0) & s_mosi;
    end if;
  end process;

  ----------------------------------------
  -- tx data SM
  ----------------------------------------
  process(sclk_rising, bit_ndx, dt, tx_bit)
  begin
    tx_bit_next <= tx_bit;
    if sclk_rising = '1' then
      tx_bit_next <= dt(DATA_WIDTH - 1 - bit_ndx);
    end if;
  end process;

  ---------------------------------------------------------------------
  -- module outputs
  --
  ---------------------------------------------------------------------
  -- rx byte ready
  dready <= data_ready;

  -- SPI transaction active
  active <= spi_active;

  -- data received
  dr <= data_received;

  -- tx data: MSB first
  miso <= tx_bit when spi_active = '1' else
          'Z';
end Behavioral;

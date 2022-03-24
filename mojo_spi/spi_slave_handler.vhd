----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:43:59 03/16/2022 
-- Design Name: 
-- Module Name:    spi_slave_handler - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_slave_handler is
port
(
  -- main system clock for synchronous operation
  clk: in std_logic;

  -- module reset : active high
  reset: in std_logic;

  -- data to tx for SPI slave
  dout: out std_logic_vector(7 downto 0);

  -- data rxed by SPI slave
  din: in std_logic_vector(7 downto 0);

  -- rx data ready signal
  dready: in std_logic;

  -- SPI transaction active
  active: in std_logic;

  -- LEDs
  leds: out std_logic_vector(7 downto 0)
);
end spi_slave_handler;

architecture Behavioral of spi_slave_handler is
----------------------------------------------------------
-- init : initialization
-- s0 : idle. waiting for command
-- cmd_read 
-- cmd_write
----------------------------------------------------------
type state_type is (s0, cmd_read, cmd_write);

signal state_reg: state_type;
signal state_next: state_type;

signal led_reg, led_reg_next: std_logic_vector(7 downto 0);
signal bad_reg: std_logic_vector(7 downto 0);
signal def_reg: std_logic_vector(7 downto 0);
signal reg_sel, reg_sel_next: std_logic_vector(1 downto 0);

signal dready_trigger: std_logic;

begin
  --dready_trigger <= dready;

  ------------------------------------------------------------------
  -- state register
  ------------------------------------------------------------------
  process(clk, reset)
  begin
    if (reset = '1') then
      state_reg <= s0;
      reg_sel <= "00";
      led_reg <= (others => '0');
      bad_reg <= "10001000";
      def_reg <= "11111111";
      dready_trigger <= '0';
    elsif rising_edge(clk) then
      state_reg <= state_next;
      reg_sel <= reg_sel_next;
      led_reg <= led_reg_next;
      dready_trigger <= dready;
    end if;
  end process;

  ------------------------------------------------------------------
  -- next state logic 
  ------------------------------------------------------------------
  process(state_reg, dready_trigger, active, din, state_reg, reg_sel, led_reg)
  begin
    state_next <= state_reg;
    reg_sel_next <= reg_sel;
    led_reg_next <= led_reg;

    case state_reg is
      when s0 => -- waiting for command
        if active = '0' then
          state_next <= s0;
          reg_sel_next <= "00";
        elsif dready_trigger = '1' then
          -- decode command
          case din is
            when "00000001" =>  -- read command
              state_next <= cmd_read;
              reg_sel_next <= "01";

            when "00000010" =>  -- write command
              state_next <= cmd_write;
              reg_sel_next <= "11";

            when others     =>
              state_next <= s0;
              reg_sel_next <= "10";
          end case;
        end if;

      when cmd_read =>
        if active = '0' then
          state_next <= s0;
          reg_sel_next <= "00";
        elsif dready_trigger = '1' then
          -- read complete
          state_next <= s0;
          reg_sel_next <= "00";
        end if;

      when cmd_write =>
        if active = '0' then
          state_next <= s0;
          reg_sel_next <= "00";
        elsif dready_trigger = '1' then
          -- decode data
          led_reg_next <= din;
          state_next <= s0;
          reg_sel_next <= "00";
        end if;
    end case;
  end process;

  dout <= led_reg when reg_sel = "01" else
          bad_reg when reg_sel = "10" else
          def_reg;

  leds <= led_reg;
end Behavioral;

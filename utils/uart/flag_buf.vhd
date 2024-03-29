library ieee;
use ieee.std_logic_1164.all;

entity flag_buf is
generic
(
  W: integer := 8
);

port
(
  clk, reset: in std_logic;
  clr_flag, set_flag: in std_logic;
  din: in std_logic_vector(W-1 downto 0);
  dout: out std_logic_vector(W-1 downto 0);
  flag: out std_logic
);
end flag_buf;

architecture arch of flag_buf is
  signal buf_reg, buf_next: std_logic_vector(W-1 downto 0);
  signal flag_reg, flag_next: std_logic;
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      buf_reg <= (others => '0');
      flag_reg <= '0';
    elsif rising_edge(clk)
    then
      buf_reg <= buf_next;
      flag_reg <= flag_next;
    end if;
  end process;

  process(buf_reg, flag_reg, set_flag, clr_flag, din)
  begin
    buf_next <= buf_reg;
    flag_next <= flag_reg;

    if set_flag = '1'
    then
      buf_next <= din;
      flag_next <= '1';
    elsif clr_flag = '1'
    then
      flag_next <= '0';
    end if;
  end process;

  dout <= buf_reg;
  flag <= flag_reg;
end arch;

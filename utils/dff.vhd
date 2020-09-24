library ieee;
use ieee.std_logic_1164.all;

entity d_ff is
port
(
  clk: in std_logic;
  d: in std_logic;
  q: out std_logic
);
end d_ff;

architecture arch of d_ff is
begin
  process(clk)
  begin
    if rising_edge(clk)
    then
      q <= d;
    end if;
  end process;
end arch;


library ieee;
use ieee.std_logic_1164.all;

entity d_ff_reset is
port
(
  clk: in std_logic;
  reset: in std_logic;
  d: in std_logic;
  q: out std_logic
);
end d_ff_reset;

architecture arch of d_ff_reset is
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      q <= '0';
    elsif rising_edge(clk)
    then
      q <= d;
    end if;
  end process;
end arch;

library ieee;
use ieee.std_logic_1164.all;

entity d_ff_en is
port
(
  clk: in std_logic;
  reset: in std_logic;
  en: in std_logic;
  d: in std_logic;
  q: out std_logic
);
end d_ff_en;

architecture arch of d_ff_en is
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      q <= '0';
    elsif rising_edge(clk)
    then
      if en = '1'
      then
        q <= d;
      end if;
    end if;
  end process;
end arch;

architecture two_seg_arch of d_ff_en is
  signal r_reg, r_next: std_logic;
begin
  process(clk, reset)
  begin
    if reset = '1' then
      r_reg <= '0';
    elsif rising_edge(clk)
    then
      r_reg <= r_next;
    end if;
  end process;

  r_next <= d when en = '1' else
            r_reg;
  q <= r_reg;
end two_seg_arch;

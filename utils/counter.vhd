library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity free_run_bin_counter is
generic
(
  N: integer := 8
);

port
(
  clk: in std_logic;
  reset: in std_logic;
  max_tick: out std_logic;
  q: out std_logic_vector(N-1 downto 0)
);
end free_run_bin_counter;

architecture arch of free_run_bin_counter is
  signal r_reg: unsigned(N-1 downto 0);
  signal r_next: unsigned(N-1 downto 0);
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      r_reg <= (others => '0');
    elsif rising_edge(clk)
    then
      r_reg <= r_next;
    end if;
  end process;

  r_next <= r_reg + 1;
  q <= std_logic_vector(r_reg);
  max_tick <= '1' when r_reg = (2**N-1) else
              '0';
end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity univ_bin_counter is
generic
(
  N: integer := 8
);

port
(
  clk, reset: in std_logic;
  syn_clr, load, en, up: in std_logic;
  d: in std_logic_vector(N-1 downto 0);
  max_tick, min_tick: out std_logic;
  q: out std_logic_vector(N-1 downto 0)
);
end univ_bin_counter;

architecture arch of univ_bin_counter is
  signal r_reg: unsigned(N-1 downto 0);
  signal r_next: unsigned(N-1 downto 0);
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      r_reg <= (others => '0');
    elsif rising_edge(clk)
    then
      r_reg <= r_next;
    end if;
  end process;

  r_next <= (others => '0') when syn_clr = '1' else
            unsigned(d)     when load = '1' else
            r_reg + 1       when en = '1' and up = '1' else
            r_reg -1        when en = '1' and up = '0' else
            r_reg;

  q <= std_logic_vector(r_reg);
  max_tick <= '1' when r_reg = (2**N-1) else '0';
  min_tick <= '1' when r_reg = 0 else '0';
end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mod_m_counter is
generic
(
  N: integer := 4;        -- number of bits = ceiling(log2M)
  M: integer := 10        -- mod-M
);

port
(
  clk, reset: in std_logic;
  max_tick: out std_logic;
  q: out std_logic_vector(N-1 downto 0)
);
end mod_m_counter;

architecture arch of mod_m_counter is
  signal r_reg: unsigned(N-1 downto 0);
  signal r_next: unsigned(N-1 downto 0);
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      r_reg <= (others => '0');
    elsif rising_edge(clk)
    then
      r_reg <= r_next;
    end if;
  end process;

  r_next <= (others => '0') when r_reg = (M-1) else
            r_reg + 1;

  q <= std_logic_vector(r_reg);
  max_tick <= '1' when r_reg = (M-1) else
              '0';
end arch;

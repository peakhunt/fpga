library ieee;
use ieee.std_logic_1164.all;

entity reg_reset is
port
(
  clk: in std_logic;
  reset: in std_logic;
  d: in std_logic_vector(7 downto 0);
  q: out std_logic_vector(7 downto 0)
);
end reg_reset;

architecture arch of reg_reset is
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      q <= (others => '0');
    elsif rising_edge(clk)
    then
      q <= d;
    end if;
  end process;
end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
generic
(
  B: integer := 8;  -- number of bits
  W: integer := 2   -- number of address bits
);

port
(
  clk: in std_logic;
  reset: in std_logic;
  wr_en: in std_logic;
  w_addr: in std_logic_vector(W-1 downto 0);
  r_addr: in std_logic_vector(W-1 downto 0);
  w_data: in std_logic_vector(B-1 downto 0);
  r_data: out std_logic_vector(B-1 downto 0)
);
end reg_file;

architecture arch of reg_file is
  type reg_file_type is array(2**W-1 downto 0) of
    std_logic_vector(B-1 downto 0);
  signal array_reg: reg_file_type;
begin
  process(clk, reset)
  begin
    if reset = '1'
    then
      array_reg <= (others => (others => '0'));
    elsif rising_edge(clk)
    then
      if wr_en = '1'
      then
        array_reg(to_integer(unsigned(w_addr))) <= w_data;
      end if;
    end if;
  end process;

  r_data <= array_reg(to_integer(unsigned(r_addr)));
end arch;

library ieee;
use ieee.std_logic_1164.all;

entity univ_shift_reg is
generic
(
  N: integer := 8
);

port
(
  clk: in std_logic;
  reset: in std_logic;
  ctrl: in std_logic_vector(1 downto 0);
  d: in std_logic_vector(N-1 downto 0);
  q: out std_logic_vector(N-1 downto 0)
);
end univ_shift_reg;

architecture arch of univ_shift_reg is
  signal r_reg: std_logic_vector(N-1 downto 0);
  signal r_next: std_logic_vector(N-1 downto 0);
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

  with ctrl select
    r_next <=
      r_reg                           when "00",      -- no op
      r_reg(N-1 downto 0) & d(0)      when "01",      -- shift left
      d(N-1) & r_reg(N-1 downto 1)    when "10",      -- shoft right
      d                               when others;    -- load

  q <= r_reg;
end arch;

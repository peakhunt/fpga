library ieee;
use ieee.std_logic_1164.all;

entity redge_detector is
port
(
  clk: in std_logic;
  reset: in std_logic;
  level: in std_logic;
  tick: out std_logic
);
end redge_detector;

architecture moore_arch of redge_detector is
  type state_type is (zero, edge, one);
  signal state_reg, state_next: state_type;
begin
  -- state register
  process(clk, reset)
  begin
    if reset = '1'
    then
      state_reg <= zero;
    elsif rising_edge(clk)
    then
      state_reg <= state_next;
    end if;
  end process;

  -- next-state/output logic
  process(state_reg, level)
  begin
    state_next <= state_reg;
    tick <= '0';

    case state_reg is
      when zero =>
        if level = '1'
        then
          state_next <= edge;
        end if;

      when edge =>
        tick <= '1';
        if level = '1'
        then
          state_next <= one;
        else
          state_next <= zero;
        end if;

      when one =>
        if level = '0'
        then
          state_next <= zero;
        end if;
    end case;
  end process;
end moore_arch;

architecture mearly_arch of redge_detector is
  type state_type is (zero, one);
  signal state_reg, state_next: state_type;
begin
  -- state register
  process(clk, reset)
  begin
    if reset = '1'
    then
      state_reg <= zero;
    elsif rising_edge(clk)
    then
      state_reg <= state_next;
    end if;
  end process;

  -- next-state/output logic
  process(state_reg, level)
  begin
    state_next <= state_reg;
    tick <= '0';

    case state_reg is
      when zero => 
        if level = '1'
        then
          state_next <= one;
          tick <= '1';
        end if;

      when one =>
        if level = '0'
        then
          state_next <= zero;
        end if;
    end case;
  end process;
end mearly_arch;

architecture gate_level_arch of redge_detector is
  signal delay_reg: std_logic;
begin
  -- delay register
  process(clk, reset)
  begin
    if reset = '1'
    then
      delay_reg <= '0';
    elsif rising_edge(clk)
    then
      delay_reg <= level;
    end if;
  end process;

  -- decoding logic
  tick <= (not delay_reg) and level;
end architecture;

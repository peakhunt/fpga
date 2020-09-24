library ieee;
use ieee.std_logic_1164.all;

entity fsm_eg is
port
(
  clk: in std_logic;
  reset: in std_logic;
  a: in std_logic;
  b: in std_logic;
  y0: out std_logic;
  y1: out std_logic;
);
end fsm_eg;

architecture syn of fsm_eg is
  type eg_state_type is (s0, s1, s2);

  signal state_reg: eg_state_type;
  signal state_next: eg_state_type;
begin

  --============================================================================
  -- state register
  --============================================================================
  process(clk, reset)
  begin
    if reset = '1'
    then
      state_reg <= s0;
    elsif rising_edge(clk)
    then
      state_reg <= state_next;
    end if;
  end process;

  --============================================================================
  -- next state logic
  --============================================================================
  process(state_reg, a, b)
  begin
    case state_reg is
      when s0 =>
        if a = '1'
        then
          if b = '1'
          then
            state_next <= s2;
          else
            state_next <= s1;
          end if;
        else
          state_next <= s0;
        end if;

      when s1 =>
        if a = '1'
        then
          state_next <= s0;
        else
          state_next <= s1;
        end if;

      when s2 =>
        state_next <= s0;

    end case;
  end process;

  --============================================================================
  -- Moore output logic
  --============================================================================
  process(state_reg)
  begin
    case state_reg is
      when s0|s2 =>
        y1 <= '0';

      when s1 =>
        y1 <= '1';

    end case;
  end process;

  --============================================================================
  -- Mealy output logic
  --============================================================================
  process(state_reg, a, b)
  begin
    case state_reg is
      when s0 =>
        if a = '1' and b = '1'
        then
          y0 <= '1';
        else
          y0 <= '0';
        end if;

      when s1 | s2 =>
        y0 <= '0';

    end case;
  end process;
end syn;

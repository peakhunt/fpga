library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
port
(
  clk: in std_logic;
  reset: in std_logic;
  sw: in std_logic;
  db: out std_logic
);
end debouncer;

architecture arch of debouncer is
  constant N: integer := 19;      -- 10ms at 50Mhz clock
  signal q_reg, q_next: unsigned(N-1 downto 0);
  signal m_tick: std_logic;

  type debouncer_state_type is (zero, wait1_1, wait1_2, wait1_3, one, wait0_1, wait0_2, wait0_3);
  signal state_reg, state_next: debouncer_state_type;
begin

  --============================================================================
  -- counter to generate 10ms tick
  -- 2*^19 * 20ns = 10ms
  --============================================================================
  process(clk, reset)
  begin
    if rising_edge(clk)
    then
      q_reg <= q_next;
    end if;
  end process;

  --============================================================================
  -- next state logic
  --============================================================================
  q_next <= q_reg + 1;

  --============================================================================
  -- internal tick
  --============================================================================
  m_tick <= '1' when q_reg = 0 else
            '0';

  --============================================================================
  -- debouncing FSM
  --============================================================================
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

  process(state_reg, sw, m_tick)
  begin
    state_next <= state_reg;
    db <= '0';

    case state_reg is
      when zero =>
        if sw = '1' then
          state_next <= wait1_1;
        end if;

      when wait1_1 =>
        if sw = '0'
        then
          state_next <= zero;
        else
          if m_tick = '1'
          then
            state_next <= wait1_2;
          end if;
        end if;

      when wait1_2 =>
        if sw = '0'
        then
          state_next <= zero;
        else
          if m_tick = '1'
          then
            state_next <= wait1_3;
          end if;
        end if;

      when wait1_3 =>
        if sw = '0'
        then
          state_next <= zero;
        else
          if m_tick = '1'
          then
            state_next <= one;
          end if;
        end if;

      when one =>
        db <= '1';
        if sw = '0'
        then
          state_next <= wait0_1;
        end if;

      when wait0_1 =>
        db <= '1';
        if sw = '1'
        then
          state_next <= one;
        else
          if m_tick <= '1'
          then
            state_next <= wait0_2;
          end if;
        end if;

      when wait0_2 =>
        db <= '1';
        if sw = '1'
        then
          state_next <= one;
        else
          if m_tick <= '1'
          then
            state_next <= wait0_3;
          end if;
        end if;

      when wait0_3 =>
        db <= '1';
        if sw = '1'
        then
          state_next <= one;
        else
          if m_tick <= '1'
          then
            state_next <= zero;
          end if;
        end if;
    end case;
  end process;
end arch;

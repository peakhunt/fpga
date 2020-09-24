library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
port
(
  clk: in std_logic;
  reset: in std_logic;
  level: in std_logic;
  rising: out std_logic;
  falling: out std_logic
);
end edge_detector;

architecture arch of edge_detector is
  type state_type is (zero, redge, fedge, one);
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
    rising <= '0';
    falling <= '0';

    case state_reg is
      when zero =>
        if level = '1'
        then
          state_next <= redge;
        end if;

      when redge =>
        rising <= '1';
        if level = '1'
        then
          state_next <= one;
        else
          state_next <= zero;
        end if;

      when one =>
        if level = '0'
        then
          state_next <= fedge;
        end if;

      when fedge =>
        falling <= '1';
        if level = '0'
        then
          state_next <= zero;
        else
          state_next <= one;
        end if;

    end case;
  end process;
end arch;

--============================================================================
-- testbench
--============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity edge_detector_testbench is
end edge_detector_testbench;

architecture tb_arch of edge_detector_testbench is
  constant T: time := 20ns;

  signal clk: std_logic;
  signal reset: std_logic;
  signal level: std_logic;
  signal rising: std_logic;
  signal falling: std_logic;
begin
  uut: entity work.edge_detector(arch)
  port map
  (
    clk => clk,
    reset => reset,
    level => level,
    rising => rising,
    falling => falling
  );

  -- clock. 20ns running forever
  process
  begin
    clk <= '0';
    wait for T/2;
    clk <= '1';
    wait for T/2;
  end process;

  -- reset asserted for T*3
  reset <= '1', '0' after T*3;

  process
  begin
    level <= '0';
    wait until falling_edge(reset);

    wait for 100ns;
    level <= '1';
    wait for 100ns;
    level <= '0';
    wait for 100ns;
    level <= '1';
    wait for 100ns;
  end process;
end tb_arch;

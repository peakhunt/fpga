library ieee;

use ieee.std_logic_1164.all;

entity debouncer_demo is
port
(
  clk_50: in std_logic;
  btn: in std_logic;
  led: out std_logic
);
end entity;

architecture syn of debouncer_demo is
  component debouncer
  port
  (
    clk: in std_logic;
    reset: in std_logic;
    sw: in std_logic;
    db: out std_logic
  );
  end component;

  component debouncer2
  port
  (
    clk: in std_logic;
    reset: in std_logic;
    sw: in std_logic;
    db_level: out std_logic;
    db_tick: out std_logic
  );
  end component;

  signal startup_reset: std_logic;
  signal btn_in : std_logic;
  signal led_out: std_logic;
begin

  reset_proc: process(clk_50)
    variable counter: integer range 0 to 255 := 0;
  begin
    if rising_edge(clk_50)
    then
      if counter < 16
      then
        startup_reset <= '1';
        counter := counter + 1;
      else
        startup_reset <= '0';
      end if;
    end if;
  end process reset_proc;

  process(clk_50, startup_reset)
  begin
    if startup_reset = '1'
    then
      btn_in <= '0';
    elsif rising_edge(clk_50)
    then
      btn_in <= not btn;
    end if;
  end process;
  
  --db1: debouncer
  --port map
  --(
  --  clk => clk_50,
  --  reset => startup_reset,
  --  sw => btn_in,
  --  db => led_out
  --);

  db2: debouncer2
  port map
  (
    clk => clk_50,
    reset => startup_reset,
    sw => btn_in,
    db_level => led_out,
    db_tick => open
  );


  led <= not led_out;
end syn;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_pattern_tester is
    port (
        clk             : in    std_logic;
        reset_n         : in    std_logic;
        app_ready       : in    std_logic;
        app_rd_valid    : in    std_logic;
        app_rd_data     : in    std_logic_vector(15 downto 0);
        app_rd_req      : out   std_logic;
        app_wr_req      : out   std_logic;
        app_addr        : out   std_logic_vector(23 downto 0);
        app_wr_data     : out   std_logic_vector(15 downto 0);
        test_success    : out   std_logic; 
        test_fail       : out   std_logic; 
        test_busy       : out   std_logic;
        test_write      : out   std_logic;
        test_read       : out   std_logic;
        test_valid      : out   std_logic
    );
end entity;

architecture rtl of sdram_pattern_tester is

    type state_type is (ST_IDLE, ST_WRITE_CMD, ST_WRITE_WAIT, ST_READ_CMD, ST_READ_WAIT, ST_DONE, ST_DEAD_LOCK);
    signal state : state_type;

    constant MAX_ADDR     : unsigned(23 downto 0) := to_unsigned(16777215, 24);
    
    signal addr_cnt       : unsigned(23 downto 0);
    signal success_reg    : std_logic := '0';
    signal fail_reg       : std_logic := '0';
    signal writing_reg    : std_logic := '0';
    signal reading_reg    : std_logic := '0';
    signal blink_cnt      : unsigned(24 downto 0) := (others => '0');

begin

    test_success <= success_reg;
    test_fail    <= fail_reg;
    test_write   <= writing_reg;
    test_read    <= reading_reg;
    test_valid   <= app_rd_valid;
    test_busy    <= blink_cnt(23); 

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            blink_cnt <= (others => '0');
        elsif rising_edge(clk) then
            if state /= ST_DEAD_LOCK then
                blink_cnt <= blink_cnt + 1;
            end if;
        end if;
    end process;

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state        <= ST_IDLE;
            addr_cnt     <= (others => '0');
            app_wr_req   <= '0';
            app_rd_req   <= '0';
            app_addr     <= (others => '0');
            app_wr_data  <= (others => '0');
            fail_reg     <= '0';
            success_reg  <= '0';
            writing_reg  <= '0';
            reading_reg  <= '0';
        elsif rising_edge(clk) then
            app_wr_req <= '0';
            app_rd_req <= '0';

            case state is
                when ST_IDLE =>
                    if app_ready = '1' then
                        state    <= ST_WRITE_CMD;
                        addr_cnt <= (others => '0');
                        writing_reg <= '1';
                    end if;

                when ST_WRITE_CMD =>
                    if app_ready = '1' then
                        app_wr_req  <= '1';
                        app_addr    <= std_logic_vector(addr_cnt);
                        app_wr_data <= std_logic_vector(addr_cnt(15 downto 0));
                        state       <= ST_WRITE_WAIT;
                    end if;

                when ST_WRITE_WAIT =>
                    if app_ready = '1' then
                        if addr_cnt = MAX_ADDR then
                            state    <= ST_READ_CMD; 
                            addr_cnt <= (others => '0');
                            writing_reg <= '0';
                            reading_reg <= '1';
                        else
                            addr_cnt <= addr_cnt + 1;
                            state    <= ST_WRITE_CMD; 
                        end if;
                    end if;

                when ST_READ_CMD =>
                    if app_ready = '1' then
                        app_rd_req <= '1';
                        app_addr   <= std_logic_vector(addr_cnt);
                        state      <= ST_READ_WAIT;
                    end if;

                when ST_READ_WAIT =>
                    if app_rd_valid = '1' then
                        if app_rd_data /= std_logic_vector(addr_cnt(15 downto 0)) then
                            state    <= ST_DEAD_LOCK;
                            fail_reg <= '1';
                        else
                            if addr_cnt = MAX_ADDR then
                                state <= ST_DONE;
                                reading_reg <= '0';
                            else
                                addr_cnt <= addr_cnt + 1;
                                state    <= ST_READ_CMD; 
                            end if;
                        end if;
                    end if;

                when ST_DONE =>
                    success_reg <= not success_reg;
                    state       <= ST_IDLE;

                when ST_DEAD_LOCK =>
                    app_wr_req <= '0';
                    app_rd_req <= '0';
                    fail_reg   <= '1';

                when others =>
                    state <= ST_IDLE;
            end case;
        end if;
    end process;

end architecture;

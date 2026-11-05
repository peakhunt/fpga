library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_controller is
    port (
        clk             : in    std_logic;
        reset_n         : in    std_logic;

        app_rd_req      : in    std_logic;
        app_wr_req      : in    std_logic;
        app_addr        : in    std_logic_vector(23 downto 0);
        app_wr_data     : in    std_logic_vector(15 downto 0);

        app_rd_data     : out   std_logic_vector(15 downto 0);
        app_rd_valid    : out   std_logic;
        app_ready       : out   std_logic;

        DRAM_ADDR       : out   std_logic_vector(12 downto 0);
        DRAM_BA         : out   std_logic_vector(1 downto 0);
        DRAM_CS_N       : out   std_logic;
        DRAM_RAS_N      : out   std_logic;
        DRAM_CAS_N      : out   std_logic;
        DRAM_WE_N       : out   std_logic;
        DRAM_DQM        : out   std_logic_vector(1 downto 0);
        DRAM_DQ         : inout std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of sdram_controller is

    ----------------------------------------------------------------
    -- SDRAM commands
    ----------------------------------------------------------------
    constant CMD_MRS : std_logic_vector(3 downto 0) := "0000";
    constant CMD_REF : std_logic_vector(3 downto 0) := "0001";
    constant CMD_PRE : std_logic_vector(3 downto 0) := "0010";
    constant CMD_ACT : std_logic_vector(3 downto 0) := "0011";
    constant CMD_WR  : std_logic_vector(3 downto 0) := "0100";
    constant CMD_RD  : std_logic_vector(3 downto 0) := "0101";
    constant CMD_NOP : std_logic_vector(3 downto 0) := "0111";

    ----------------------------------------------------------------
    -- 100 MHz clock
    ----------------------------------------------------------------
    constant CNT_100US    : integer := 10000;

    constant CNT_TRP      : integer := 3;
    constant CNT_TRFC     : integer := 8;
    constant CNT_TMRD     : integer := 3;
    constant CNT_TRCD     : integer := 3;

    constant REF_INTERVAL : integer := 750;

    ----------------------------------------------------------------
    -- State machine
    ----------------------------------------------------------------
    type state_type is (
        ST_INIT_WAIT,
        ST_INIT_PRE,
        ST_INIT_REF1,
        ST_INIT_REF2,
        ST_INIT_MRS,
        ST_IDLE,
        ST_REFRESH,
        ST_ACTIVATE,

        -- WRITE
        ST_WRITE_SETUP,
        ST_WRITE_CMD,
        ST_WRITE_HOLD,

        -- READ
        ST_READ_CMD,
        ST_READ_WAIT,

        ST_PRECHARGE
    );

    signal state : state_type;

    ----------------------------------------------------------------
    -- Timers
    ----------------------------------------------------------------
    signal timer       : integer range 0 to 10005;
    signal ref_timer   : integer range 0 to 800;
    signal ref_pending : std_logic;

    ----------------------------------------------------------------
    -- Latched application request
    ----------------------------------------------------------------
    signal req_write   : std_logic;
    signal req_addr    : std_logic_vector(23 downto 0);
    signal req_wr_data : std_logic_vector(15 downto 0);

    ----------------------------------------------------------------
    -- Address decode
    --
    -- 32 MB SDRAM
    -- 16M words x 16 bit
    --
    -- BA  = 2 bits
    -- ROW = 13 bits
    -- COL = 9 bits
    ----------------------------------------------------------------
    signal bank_addr : std_logic_vector(1 downto 0);
    --signal row_addr  : std_logic_vector(12 downto 0);
    signal col_addr  : std_logic_vector(8 downto 0);

    ----------------------------------------------------------------
    -- SDRAM output registers
    ----------------------------------------------------------------
    signal cmd_reg : std_logic_vector(3 downto 0);

    signal dq_out  : std_logic_vector(15 downto 0);
    signal dq_oe   : std_logic;

    ----------------------------------------------------------------
    -- READ latency
    --
    -- CAS latency = 3
    ----------------------------------------------------------------
    signal rd_latency_cnt : unsigned(2 downto 0);

    ----------------------------------------------------------------
    -- Pending request latch
    --
    -- app_rd_req / app_wr_req are 1-clock pulses. If the controller
    -- is busy with REFRESH when the pulse arrives, it must not be lost.
    ----------------------------------------------------------------
    signal pend       : std_logic;
    signal pend_write : std_logic;
    signal pend_addr  : std_logic_vector(23 downto 0);
    signal pend_data  : std_logic_vector(15 downto 0);

begin

    ----------------------------------------------------------------
    -- Address decode
    ----------------------------------------------------------------
    bank_addr <= req_addr(23 downto 22);
    --row_addr  <= req_addr(21 downto 9);
    col_addr  <= req_addr(8 downto 0);

    ----------------------------------------------------------------
    -- DQ bus
    ----------------------------------------------------------------
    DRAM_DQ <= dq_out when dq_oe = '1'
               else (others => 'Z');

    ----------------------------------------------------------------
    -- No byte masking
    ----------------------------------------------------------------
    DRAM_DQM <= "00";

    ----------------------------------------------------------------
    -- Command output
    --
    -- cmd_reg =
    -- CS_N RAS_N CAS_N WE_N
    ----------------------------------------------------------------
    DRAM_CS_N  <= cmd_reg(3);
    DRAM_RAS_N <= cmd_reg(2);
    DRAM_CAS_N <= cmd_reg(1);
    DRAM_WE_N  <= cmd_reg(0);

    ----------------------------------------------------------------
    -- Refresh timer
    ----------------------------------------------------------------
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            ref_timer   <= 0;
            ref_pending <= '0';

        elsif rising_edge(clk) then

            if ref_timer >= REF_INTERVAL then
                ref_timer   <= 0;
                ref_pending <= '1';
            else
                ref_timer <= ref_timer + 1;
            end if;

            if state = ST_REFRESH then
                ref_pending <= '0';
            end if;

        end if;
    end process;

    ----------------------------------------------------------------
    -- Main SDRAM controller
    ----------------------------------------------------------------
    process(clk, reset_n)
    begin

        if reset_n = '0' then

            state <= ST_INIT_WAIT;

            timer <= 0;

            cmd_reg <= CMD_NOP;

            DRAM_ADDR <= (others => '0');
            DRAM_BA   <= "00";

            dq_out <= (others => '0');
            dq_oe  <= '0';

            req_write   <= '0';
            req_addr    <= (others => '0');
            req_wr_data <= (others => '0');

            rd_latency_cnt <= (others => '0');

            pend       <= '0';
            pend_write <= '0';
            pend_addr  <= (others => '0');
            pend_data  <= (others => '0');

            app_rd_data  <= (others => '0');
            app_rd_valid <= '0';
            app_ready    <= '0';

        elsif rising_edge(clk) then

            --------------------------------------------------------
            -- Default
            --------------------------------------------------------
            app_rd_valid <= '0';

            --------------------------------------------------------
            -- Latch request in ANY state (never lose a 1-clk pulse).
            -- ST_IDLE may clear 'pend' below; that later assignment wins.
            --------------------------------------------------------
            if (app_wr_req = '1' or app_rd_req = '1') and pend = '0' then
                pend       <= '1';
                pend_write <= app_wr_req;
                pend_addr  <= app_addr;
                pend_data  <= app_wr_data;
            end if;

            case state is

                -- POWER-UP WAIT
                when ST_INIT_WAIT =>

                    cmd_reg <= CMD_NOP;
                    dq_oe   <= '0';
                    app_ready <= '0';

                    if timer >= CNT_100US then

                        timer <= 0;
                        state <= ST_INIT_PRE;

                    else

                        timer <= timer + 1;

                    end if;


                -- PRECHARGE ALL
                when ST_INIT_PRE =>

                    cmd_reg <= CMD_PRE;

                    DRAM_ADDR <= (others => '0');

                    -- A10 = 1 : all banks
                    DRAM_ADDR(10) <= '1';

                    DRAM_BA <= "00";

                    timer <= 0;

                    state <= ST_INIT_REF1;


                -- WAIT tRP then REFRESH #1
                when ST_INIT_REF1 =>

                    cmd_reg <= CMD_NOP;

                    if timer >= CNT_TRP - 1 then

                        cmd_reg <= CMD_REF;

                        timer <= 0;
                        state <= ST_INIT_REF2;

                    else

                        timer <= timer + 1;

                    end if;


                -- WAIT tRFC then REFRESH #2
                when ST_INIT_REF2 =>

                    cmd_reg <= CMD_NOP;

                    if timer >= CNT_TRFC - 1 then

                        cmd_reg <= CMD_REF;

                        timer <= 0;
                        state <= ST_INIT_MRS;

                    else

                        timer <= timer + 1;

                    end if;


                -- WAIT tRFC then MODE REGISTER SET
                when ST_INIT_MRS =>

                    cmd_reg <= CMD_NOP;

                    if timer >= CNT_TRFC - 1 then

                        ------------------------------------------------
                        -- Mode Register
                        --
                        -- A6:A4 = 011 -> CAS latency 3
                        -- Sequential burst
                        -- Burst length = 1
                        ------------------------------------------------
                        cmd_reg <= CMD_MRS;

                        DRAM_ADDR <= "0000000110000";
                        DRAM_BA   <= "00";

                        timer <= 0;
                        state <= ST_IDLE;

                    else

                        timer <= timer + 1;

                    end if;


                -- IDLE
                when ST_IDLE =>

                    cmd_reg <= CMD_NOP;

                    dq_oe <= '0';

                    DRAM_ADDR <= (others => '0');
                    DRAM_BA   <= "00";

                    ------------------------------------------------
                    -- tMRD wait after MRS
                    ------------------------------------------------
                    if timer < CNT_TMRD then

                        timer <= timer + 1;
                        app_ready <= '0';

                    else

                        ------------------------------------------------
                        -- Refresh has priority
                        ------------------------------------------------
                        if ref_pending = '1' then

                            cmd_reg <= CMD_REF;

                            timer <= 0;
                            app_ready <= '0';

                            state <= ST_REFRESH;

                        elsif pend = '1' then

                            ------------------------------------------------
                            -- SERVICE LATCHED REQUEST (read or write)
                            ------------------------------------------------
                            pend <= '0';

                            req_write   <= pend_write;
                            req_addr    <= pend_addr;
                            req_wr_data <= pend_data;

                            DRAM_BA   <= pend_addr(23 downto 22);
                            DRAM_ADDR <= pend_addr(21 downto 9);

                            cmd_reg <= CMD_ACT;

                            timer <= 0;
                            app_ready <= '0';

                            state <= ST_ACTIVATE;

                        else

                            ------------------------------------------------
                            -- Nothing pending.
                            -- If a request pulse is arriving this very clock,
                            -- it is being latched now: do not raise ready.
                            ------------------------------------------------
                            if app_wr_req = '1' or app_rd_req = '1' then
                                app_ready <= '0';
                            else
                                app_ready <= '1';
                            end if;

                        end if;

                    end if;


                -- REFRESH
                when ST_REFRESH =>

                    cmd_reg <= CMD_NOP;
                    dq_oe   <= '0';

                    if timer >= CNT_TRFC - 1 then

                        timer <= 0;
                        state <= ST_IDLE;

                    else

                        timer <= timer + 1;

                    end if;


                -- AFTER ACTIVATE
                when ST_ACTIVATE =>

                    cmd_reg <= CMD_NOP;

                    if timer >= CNT_TRCD - 1 then

                        timer <= 0;

                        if req_write = '1' then

                            ------------------------------------------------
                            -- IMPORTANT:
                            --
                            -- Prepare DQ BEFORE WRITE command.
                            --
                            -- This is the key fix.
                            ------------------------------------------------
                            dq_out <= req_wr_data;
                            dq_oe  <= '1';

                            DRAM_BA <= bank_addr;

                            DRAM_ADDR <= (others => '0');
                            DRAM_ADDR(8 downto 0) <= col_addr;

                            -- A10 = 0 : no auto precharge
                            DRAM_ADDR(10) <= '0';

                            state <= ST_WRITE_SETUP;

                        else

                            ------------------------------------------------
                            -- READ command
                            ------------------------------------------------
                            DRAM_BA <= bank_addr;

                            DRAM_ADDR <= (others => '0');
                            DRAM_ADDR(8 downto 0) <= col_addr;

                            -- A10 = 0
                            DRAM_ADDR(10) <= '0';

                            cmd_reg <= CMD_RD;

                            rd_latency_cnt <= (others => '0');

                            state <= ST_READ_CMD;

                        end if;

                    else

                        timer <= timer + 1;

                    end if;


                -- WRITE DATA SETUP
                --
                -- DQ is already driven here.
                -- One complete controller clock passes before
                -- WRITE command is asserted.
                when ST_WRITE_SETUP =>

                    cmd_reg <= CMD_NOP;

                    dq_out <= req_wr_data;
                    dq_oe  <= '1';

                    state <= ST_WRITE_CMD;


                -- WRITE COMMAND
                when ST_WRITE_CMD =>

                    ------------------------------------------------
                    -- DQ is already valid BEFORE this command.
                    ------------------------------------------------
                    cmd_reg <= CMD_WR;

                    dq_out <= req_wr_data;
                    dq_oe  <= '1';

                    timer <= 0;

                    state <= ST_WRITE_HOLD;


                -- WRITE HOLD
                when ST_WRITE_HOLD =>

                    cmd_reg <= CMD_NOP;

                    dq_out <= req_wr_data;
                    dq_oe  <= '1';

                    ------------------------------------------------
                    -- Hold DQ for a couple clocks after WRITE
                    ------------------------------------------------
                    if timer >= 2 then

                        dq_oe <= '0';

                        timer <= 0;

                        state <= ST_PRECHARGE;

                    else

                        timer <= timer + 1;

                    end if;


                -- READ COMMAND
                when ST_READ_CMD =>

                    ------------------------------------------------
                    -- RD command was already registered in
                    -- ST_ACTIVATE.
                    --
                    -- Keep NOP while waiting for CAS latency.
                    ------------------------------------------------
                    cmd_reg <= CMD_NOP;

                    dq_oe <= '0';

                    if rd_latency_cnt = 3 then

                        ------------------------------------------------
                        -- CAS latency = 3
                        --
                        -- Capture SDRAM data here.
                        ------------------------------------------------
                        app_rd_data  <= DRAM_DQ;
                        app_rd_valid <= '1';

                        rd_latency_cnt <= (others => '0');

                        timer <= 0;

                        state <= ST_PRECHARGE;

                    else

                        rd_latency_cnt <= rd_latency_cnt + 1;

                    end if;


                -- PRECHARGE
                when ST_PRECHARGE =>

                    dq_oe <= '0';
                    if timer = 0 then

                        cmd_reg <= CMD_PRE;

                        DRAM_ADDR <= (others => '0');

                        -- PRECHARGE ALL
                        DRAM_ADDR(10) <= '1';

                        DRAM_BA <= "00";

                        timer <= 1;

                    elsif timer >= CNT_TRP then

                        cmd_reg <= CMD_NOP;

                        timer <= 0;

                        state <= ST_IDLE;

                    else

                        cmd_reg <= CMD_NOP;

                        timer <= timer + 1;

                    end if;

                when others =>

                    state <= ST_IDLE;
                    timer <= 0;
                    cmd_reg <= CMD_NOP;
                    dq_oe <= '0';

            end case;

        end if;

    end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity de0_nano_top is
    port (
        CLOCK_50   : in    std_logic;
        KEY        : in    std_logic_vector(1 downto 0);
        LED        : out   std_logic_vector(7 downto 0);
        
        DRAM_CLK   : out   std_logic;
        DRAM_CKE   : out   std_logic;
        DRAM_CS_N  : out   std_logic;
        DRAM_RAS_N : out   std_logic;
        DRAM_CAS_N : out   std_logic;
        DRAM_WE_N  : out   std_logic;
        DRAM_BA    : out   std_logic_vector(1 downto 0);
        DRAM_ADDR  : out   std_logic_vector(12 downto 0);
        DRAM_DQ    : inout std_logic_vector(15 downto 0);
        
        DRAM_U_DQM : out   std_logic;
        DRAM_D_LQM : out   std_logic
    );
end entity;

architecture rtl of de0_nano_top is

    component sdram_pll is
        port (
            areset   : in  std_logic := '0';
            inclk0   : in  std_logic := '0';
            c0       : out std_logic;        -- 100MHz, Phase 0 (FPGA 내부 구동용)
            c1       : out std_logic;        -- 100MHz, Phase -3ns (SDRAM 외부 핀 출력용)
            locked   : out std_logic
        );
    end component;

    component sdram_ddio is
        port (
            aclr      : in  std_logic := '0';
            datain_h  : in  std_logic_vector(0 downto 0);
            datain_l  : in  std_logic_vector(0 downto 0);
            outclock  : in  std_logic;
            dataout   : out std_logic_vector(0 downto 0)
        );
    end component;

    component sdram_controller is
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
    end component;

    component sdram_pattern_tester is
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
    end component;

    signal clk_sys        : std_logic;
    signal clk_sdram_out  : std_logic;
    signal pll_locked     : std_logic;
    signal sys_reset_n    : std_logic;

    signal app_rd_req     : std_logic;
    signal app_wr_req     : std_logic;
    signal app_addr       : std_logic_vector(23 downto 0);
    signal app_wr_data    : std_logic_vector(15 downto 0);
    signal app_rd_data    : std_logic_vector(15 downto 0);
    signal app_rd_valid   : std_logic;
    signal app_ready      : std_logic;

    signal t_success      : std_logic;
    signal t_fail         : std_logic;
    signal t_busy         : std_logic;
    signal t_write        : std_logic;
    signal t_read         : std_logic;
    signal t_valid        : std_logic;
    
    signal dqm_bus        : std_logic_vector(1 downto 0);
    
    signal ddio_dataout   : std_logic_vector(0 downto 0);

begin

    sys_reset_n <= KEY(0) and pll_locked;

    DRAM_CKE  <= '1'; 
    
    DRAM_CLK  <= ddio_dataout(0);
    
    DRAM_U_DQM <= dqm_bus(1);
    DRAM_D_LQM <= dqm_bus(0);

    LED(0) <= t_success;          
    LED(1) <= t_fail;             
    LED(2) <= t_busy;             
    LED(3) <= t_write;
    LED(4) <= t_read;
    LED(5) <= t_valid;
    LED(7 downto 6) <= "00";   

    u_pll : sdram_pll
        port map (
            areset => '0',
            inclk0 => CLOCK_50,
            c0     => clk_sys,        
            c1     => clk_sdram_out,  
            locked => pll_locked
        );

    u_sdram_clk_ddio : sdram_ddio
        port map (
            aclr        => not sys_reset_n,
            datain_h(0) => '1',
            datain_l(0) => '0',
            outclock    => clk_sdram_out,
            dataout     => ddio_dataout
        );

    u_sdram_ctrl : sdram_controller
        port map (
            clk             => clk_sys,
            reset_n         => sys_reset_n,
            app_rd_req      => app_rd_req,
            app_wr_req      => app_wr_req,
            app_addr        => app_addr,
            app_wr_data     => app_wr_data,
            app_rd_data     => app_rd_data,
            app_rd_valid    => app_rd_valid,
            app_ready       => app_ready,
            DRAM_ADDR       => DRAM_ADDR,
            DRAM_BA         => DRAM_BA,
            DRAM_CS_N       => DRAM_CS_N,
            DRAM_RAS_N      => DRAM_RAS_N,
            DRAM_CAS_N      => DRAM_CAS_N,
            DRAM_WE_N       => DRAM_WE_N,
            DRAM_DQM        => dqm_bus,
            DRAM_DQ         => DRAM_DQ
        );

    u_pattern_tester : sdram_pattern_tester
        port map (
            clk             => clk_sys,
            reset_n         => sys_reset_n,
            app_ready       => app_ready,
            app_rd_valid    => app_rd_valid,
            app_rd_data     => app_rd_data,
            app_rd_req      => app_rd_req,
            app_wr_req      => app_wr_req,
            app_addr        => app_addr,
            app_wr_data     => app_wr_data,
            test_success    => t_success,
            test_fail       => t_fail,
            test_busy       => t_busy,
            test_write      => t_write,
            test_read       => t_read,
            test_valid      => t_valid
        );

end architecture;

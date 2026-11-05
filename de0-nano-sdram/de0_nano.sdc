create_clock -name {CLK_50_INPUT} -period 20.000ns [get_ports CLOCK_50]

derive_pll_clocks
derive_clock_uncertainty

create_generated_clock -name clk_ext_sdram \
    -source [get_pins {u_pll|altpll_component|auto_generated|pll1|clk[1]}] \
    [get_ports DRAM_CLK]

# 
# optimal values
#
#set_input_delay -clock {clk_ext_sdram} -max 5.900 [get_ports DRAM_DQ[*]]
#set_input_delay -clock {clk_ext_sdram} -min 2.800 [get_ports DRAM_DQ[*]]
#set_output_delay -clock {clk_ext_sdram} -max 2.000 [get_ports DRAM_DQ[*]]
#set_output_delay -clock {clk_ext_sdram} -min -1.000 [get_ports DRAM_DQ[*]]
#set_output_delay -clock {clk_ext_sdram} -max 2.000 [get_ports DRAM_ADDR[*]]
#set_output_delay -clock {clk_ext_sdram} -min -1.000 [get_ports DRAM_ADDR[*]]
#set_output_delay -clock {clk_ext_sdram} -max 2.000 [get_ports {DRAM_BA[*] DRAM_CAS_N DRAM_RAS_N DRAM_CKE DRAM_CS_N DRAM_WE_N}]
#set_output_delay -clock {clk_ext_sdram} -min -1.000 [get_ports {DRAM_BA[*] DRAM_CAS_N DRAM_RAS_N DRAM_CKE DRAM_CS_N DRAM_WE_N}]
#set_output_delay -clock {clk_ext_sdram} -max 0 [get_ports {DRAM_BA[*] DRAM_CAS_N DRAM_RAS_N DRAM_CKE DRAM_CS_N DRAM_WE_N}]
#set_output_delay -clock {clk_ext_sdram} -min 0 [get_ports {DRAM_BA[*] DRAM_CAS_N DRAM_RAS_N DRAM_CKE DRAM_CS_N DRAM_WE_N}]
set_input_delay -clock {clk_ext_sdram} -max 5.700 [get_ports DRAM_DQ[*]]
set_input_delay -clock {clk_ext_sdram} -min 2.300 [get_ports DRAM_DQ[*]]
set_output_delay -clock {clk_ext_sdram} -max 1.700 [get_ports DRAM_DQ[*]]
set_output_delay -clock {clk_ext_sdram} -min -1.000 [get_ports DRAM_DQ[*]]
set_output_delay -clock {clk_ext_sdram} -max 1.700 [get_ports DRAM_ADDR[*]]
set_output_delay -clock {clk_ext_sdram} -min -1.000 [get_ports DRAM_ADDR[*]]
set_output_delay -clock {clk_ext_sdram} -max 1.700 [get_ports {DRAM_BA[*] DRAM_CAS_N DRAM_RAS_N DRAM_CKE DRAM_CS_N DRAM_WE_N}]
set_output_delay -clock {clk_ext_sdram} -min -1.000 [get_ports {DRAM_BA[*] DRAM_CAS_N DRAM_RAS_N DRAM_CKE DRAM_CS_N DRAM_WE_N}]
#
# just to kill warnings
#
#set_false_path -from [get_ports {DRAM_DQ[*]}]
#set_false_path -to [get_ports {DRAM_DQ[*] DRAM_ADDR[*] DRAM_BA[*] DRAM_CAS_N DRAM_RAS_N DRAM_CKE DRAM_CS_N DRAM_WE_N}]

set_false_path -from [get_ports KEY*]
set_false_path -to [get_ports LED*]

set_max_delay -from [get_ports DRAM_DQ[*]] -to [get_registers {*sdram_controller*app_rd_data[*]}] 15.000

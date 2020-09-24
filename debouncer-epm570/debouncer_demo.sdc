create_clock -period 20.000 -name clk_50 [get_ports clk_50]
derive_clock_uncertainty

set_input_delay -clock { clk_50 } 0 [ get_ports { btn } ]
set_output_delay -clock { clk_50 } 0 [ get_ports { led } ]
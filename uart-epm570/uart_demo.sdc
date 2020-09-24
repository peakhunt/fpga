create_clock -period 20 -name clk [get_ports clk]
derive_clock_uncertainty

set_input_delay -clock clk 0 [get_ports {rx}]
set_output_delay -clock clk 0 [get_ports {tx}]
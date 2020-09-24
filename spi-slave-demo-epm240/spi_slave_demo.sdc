create_clock -period 20 -name gclk [get_ports {clk_50}]
derive_clock_uncertainty

set_input_delay -clock {gclk} 5 [get_ports {s_ss s_clk s_mosi}]

set_input_delay -clock {gclk} 5 [get_ports {reset}]

set_output_delay -clock {gclk} 5 [get_ports {s_miso}]

set_output_delay -clock {gclk} 0 [get_ports {leds[0] leds[1] leds[2] leds[3] leds[4] leds[5] leds[6] leds[7]}]

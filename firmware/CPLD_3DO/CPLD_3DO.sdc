create_clock -period 80 clk12
set_input_delay 40 -clock [get_clocks clk12] [get_ports hsync]



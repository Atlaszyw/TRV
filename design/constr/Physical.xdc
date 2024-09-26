set_property -dict { PACKAGE_PIN T26 IOSTANDARD LVCMOS33 } [get_ports clk_i]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports rst_ni]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports succ]

set_property IOSTANDARD LVCMOS33 [get_ports tx]
set_property PACKAGE_PIN F21 [get_ports tx]

set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PACKAGE_PIN E21 [get_ports rx]

#set_property IOSTANDARD LVCMOS33 [get_ports {gpio_out[*]}]
#set_property PACKAGE_PIN J19 [get_ports {gpio_out[0]}]
#set_property PACKAGE_PIN H19 [get_ports {gpio_out[1]}]
#set_property PACKAGE_PIN L17 [get_ports {gpio_out[2]}]
#set_property PACKAGE_PIN L18 [get_ports {gpio_out[3]}]
#set_property PACKAGE_PIN K19 [get_ports {gpio_out[4]}]
#set_property PACKAGE_PIN K20 [get_ports {gpio_out[5]}]
#set_property PACKAGE_PIN H21 [get_ports {gpio_out[6]}]
#set_property PACKAGE_PIN J18 [get_ports {gpio_out[7]}]
#set_property PACKAGE_PIN H20 [get_ports {gpio_out[8]}]
#set_property PACKAGE_PIN G20 [get_ports {gpio_out[9]}]

#set_property IOSTANDARD LVCMOS33 [get_ports scl_o]
#set_property PACKAGE_PIN M22 [get_ports scl_o]
#set_property PULLUP true [get_ports scl_o]

#set_property IOSTANDARD LVCMOS33 [get_ports sda_io]
#set_property PACKAGE_PIN N22 [get_ports sda_io]
#set_property PULLUP true [get_ports sda_io]

#set_property IOSTANDARD LVCMOS33 [get_ports uart_debug_pin]
#set_property PACKAGE_PIN J17 [get_ports uart_debug_pin]

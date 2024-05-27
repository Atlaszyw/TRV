# Ê±ÖÓÔ¼Êø50MHz
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports clk_i];

# ¸´Î»Òý½Å
set_property IOSTANDARD LVCMOS33 [get_ports rst_ni]
set_property PACKAGE_PIN F20 [get_ports rst_ni]

# ³ÌÐòÖ´ÐÐ³É¹¦Ö¸Ê¾Òý½Å
# set_property IOSTANDARD LVCMOS33 [get_ports succ]
# set_property PACKAGE_PIN F19 [get_ports succ]

# ´®¿Ú·¢ËÍÒý½Å
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_pin]
set_property PACKAGE_PIN G16 [get_ports uart_tx_pin]

# ´®¿Ú½ÓÊÕÒý½Å
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_pin]
set_property PACKAGE_PIN G15 [get_ports uart_rx_pin]

# PWM Òý½Å
set_property IOSTANDARD LVCMOS33 [get_ports pwm_o[0]]
set_property PACKAGE_PIN E21 [get_ports pwm_o[0]]

set_property IOSTANDARD LVCMOS33 [get_ports pwm_o[1]]
set_property PACKAGE_PIN D20 [get_ports pwm_o[1]]

set_property IOSTANDARD LVCMOS33 [get_ports pwm_o[2]]
set_property PACKAGE_PIN C20 [get_ports pwm_o[2]]

# GPIOÒý½Å
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_out[*]}]
set_property PACKAGE_PIN J5 [get_ports {gpio_out[0]}]
set_property PACKAGE_PIN M3 [get_ports {gpio_out[1]}]
set_property PACKAGE_PIN J6 [get_ports {gpio_out[2]}]
set_property PACKAGE_PIN H5 [get_ports {gpio_out[3]}]
set_property PACKAGE_PIN G4 [get_ports {gpio_out[4]}]
set_property PACKAGE_PIN K6 [get_ports {gpio_out[5]}]
set_property PACKAGE_PIN K3 [get_ports {gpio_out[6]}]
set_property PACKAGE_PIN H4 [get_ports {gpio_out[7]}]
set_property PACKAGE_PIN M2 [get_ports {gpio_out[8]}]
set_property PACKAGE_PIN N4 [get_ports {gpio_out[9]}]
set_property PACKAGE_PIN L5 [get_ports {gpio_out[10]}]
set_property PACKAGE_PIN L4 [get_ports {gpio_out[11]}]
set_property PACKAGE_PIN M16 [get_ports {gpio_out[12]}]
set_property PACKAGE_PIN M17 [get_ports {gpio_out[13]}]
set_property PACKAGE_PIN B20 [get_ports {gpio_out[14]}]
set_property PACKAGE_PIN D17 [get_ports {gpio_out[15]}]

# I2C Òý½Å
set_property IOSTANDARD LVCMOS33 [get_ports scl_o]
set_property PACKAGE_PIN M22 [get_ports scl_o]
set_property PULLUP true [get_ports scl_o]

set_property IOSTANDARD LVCMOS33 [get_ports sda_io]
set_property PACKAGE_PIN N22 [get_ports sda_io]
set_property PULLUP true [get_ports sda_io]

# Debug Òý½Å
set_property IOSTANDARD LVCMOS33 [get_ports uart_debug_pin]
set_property PACKAGE_PIN M13 [get_ports uart_debug_pin]

# Define Clocks
create_clock -name "Clk_50_Meg"   \
             -period 20ns         \
             -waveform {0ns 10ns} \
             [get_ports Clk]
             
derive_pll_clocks -create_base_clocks -use_net_name             
#-------------------------------------------------------------------------------
                       
# Calculate Clock Uncertainties
derive_clock_uncertainty
#-------------------------------------------------------------------------------

# Ignore Timing Path
set_false_path -from [get_ports     nReset] \
               -to   [get_registers tnReset]

set_false_path -from [get_ports     nButtons*] \
               -to   [get_registers *]

set_false_path -from [get_ports     nLED*] \
               -to   [get_registers *]

set_false_path -from [get_registers *] \
               -to   [get_ports     nLED*]

#set_false_path -from [get_clocks Clk*] \
#               -to   [get_clocks PLL*]
#-------------------------------------------------------------------------------
               
# Minimum Delays
# set_min_delay -from [get_ports RS232_Rx] \
#              -to   [get_ports RS232_Tx] \
#              0us
#
#set_min_delay -from [get_ports nButton*] \
#              -to   [get_ports nLED*]    \
#              0us
#
#set_min_delay -from [get_registers Counter*] \
#              -to   [get_ports     nLED*]    \
#              0us
#-------------------------------------------------------------------------------
               
# Maximum Delays
#set_max_delay -from [get_ports RS232_Rx] \
#              -to   [get_ports RS232_Tx] \
#              1us
#
#set_max_delay -from [get_ports nButton*] \
#              -to   [get_ports nLED*]    \
#              1us
#
#set_max_delay -from [get_registers Counter*] \
#              -to   [get_ports     nLED*]    \
#              1us
#-------------------------------------------------------------------------------


set_global_assignment -entity "Rx_PLL" -library "lib_Rx_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "Rx_PLL" -library "lib_Rx_PLL" -name IP_TOOL_VERSION "13.1"
set_global_assignment -entity "Rx_PLL" -library "lib_Rx_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_Rx_PLL" -name SPD_FILE [file join $::quartus(sip_path) "Rx_PLL.spd"]

set_global_assignment -library "lib_Rx_PLL" -name MISC_FILE [file join $::quartus(sip_path) "Rx_PLL_sim/Rx_PLL.vo"]

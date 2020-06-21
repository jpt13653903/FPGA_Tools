set_global_assignment -entity "Tx_PLL" -library "lib_Tx_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "Tx_PLL" -library "lib_Tx_PLL" -name IP_TOOL_VERSION "13.1"
set_global_assignment -entity "Tx_PLL" -library "lib_Tx_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_Tx_PLL" -name SPD_FILE [file join $::quartus(sip_path) "Tx_PLL.spd"]

set_global_assignment -library "lib_Tx_PLL" -name MISC_FILE [file join $::quartus(sip_path) "Tx_PLL_sim/Tx_PLL.vo"]

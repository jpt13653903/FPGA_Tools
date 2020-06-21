set_global_assignment -entity "Clock_Recovery_PLL" -library "lib_Clock_Recovery_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "Clock_Recovery_PLL" -library "lib_Clock_Recovery_PLL" -name IP_TOOL_VERSION "13.1"
set_global_assignment -entity "Clock_Recovery_PLL" -library "lib_Clock_Recovery_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_Clock_Recovery_PLL" -name SPD_FILE [file join $::quartus(sip_path) "Clock_Recovery_PLL.spd"]

set_global_assignment -library "lib_Clock_Recovery_PLL" -name MISC_FILE [file join $::quartus(sip_path) "Clock_Recovery_PLL_sim/Clock_Recovery_PLL.vo"]

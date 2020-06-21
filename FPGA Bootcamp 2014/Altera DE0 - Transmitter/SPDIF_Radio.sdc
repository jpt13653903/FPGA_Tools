# Define Clocks
create_clock -name     "Clk_50_Meg" \
             -period   20ns         \
             -waveform {0ns 10ns}   \
             [get_ports Clk]

derive_pll_clocks -create_base_clocks -use_net_name             

derive_clock_uncertainty
#-------------------------------------------------------------------------------

# JTAG
create_clock -name tck -period "10MHz" [get_ports altera_reserved_tck]

set_clock_groups -exclusive -group [get_clocks tck]

set_input_delay  -clock tck 20 [get_ports altera_reserved_tdi]
set_input_delay  -clock tck 20 [get_ports altera_reserved_tms]
set_output_delay -clock tck 20 [get_ports altera_reserved_tdo]
#-------------------------------------------------------------------------------

set_false_path                \
 -from [get_clocks Sound_Clk] \
 -to   [get_clocks *altera_pll*]

set_false_path                 \
 -from [get_registers *tReset] \
 -to   [get_registers *Reset]

set_false_path                \
 -from [get_registers *Reset] \
 -to   [get_registers *tnReset]

set_false_path                               \
 -from [get_registers *SPDIF_Encoder1|SPDIF] \
 -to   [get_registers *SPDIF_Decoder1|pSPDIF]

set_false_path                    \
 -from [get_registers *Control1*] \
 -to   [get_registers *Audio_Player1*]

set_false_path                          \
 -from [get_registers *SPDIF_Decoder1*] \
 -to   [get_registers *Audio_Player1*]

set_false_path -from [get_ports UART_RX*] -to [get_registers *]
set_false_path -from [get_ports nReset*]  -to [get_registers *]
set_false_path -from [get_ports Switch*]  -to [get_registers *]
set_false_path -from [get_ports Button*]  -to [get_registers *]
set_false_path -from [get_ports GPIO*  ]  -to [get_registers *]
set_false_path -from [get_ports HSMC*  ]  -to [get_registers *]

set_false_path -from [get_ports nReset*] -to [get_ports *]
set_false_path -from [get_ports Switch*] -to [get_ports *]
set_false_path -from [get_ports Button*] -to [get_ports *]
set_false_path -from [get_ports GPIO*  ] -to [get_ports *]
set_false_path -from [get_ports HSMC*  ] -to [get_ports *]

set_false_path -from [get_registers *] -to [get_ports SevenSegment*]
set_false_path -from [get_registers *] -to [get_ports Green*]
set_false_path -from [get_registers *] -to [get_ports Red*]
set_false_path -from [get_registers *] -to [get_ports UART_TX*]
set_false_path -from [get_registers *] -to [get_ports GPIO*]
set_false_path -from [get_registers *] -to [get_ports HSMC*]
set_false_path -from [get_registers *] -to [get_ports SPDIF*]

set_false_path -from [get_ports *] -to [get_ports SevenSegment*]
set_false_path -from [get_ports *] -to [get_ports Green*]
set_false_path -from [get_ports *] -to [get_ports Red*]
set_false_path -from [get_ports *] -to [get_ports UART_TX*]
set_false_path -from [get_ports *] -to [get_ports GPIO*]
set_false_path -from [get_ports *] -to [get_ports HSMC*]
set_false_path -from [get_ports *] -to [get_ports SPDIF*]
#-------------------------------------------------------------------------------

set_multicycle_path                        \
 -from [get_registers *SPDIF_Decoder*Raw*] \
 -to   [get_registers *]                   \
 -setup 10
set_multicycle_path                        \
 -from [get_registers *SPDIF_Decoder*Raw*] \
 -to   [get_registers *]                   \
 -hold 9

set_multicycle_path                             \
 -from [get_registers *]                        \
 -to   [get_registers *LevelFilter*SoundLevel*] \
 -setup 10
set_multicycle_path                             \
 -from [get_registers *]                        \
 -to   [get_registers *LevelFilter*SoundLevel*] \
 -hold 9
#-------------------------------------------------------------------------------

# Create a virtual clock with the same period as the state-machine clock

create_clock -name SD_Clk -period 22.222222ns

# Assume a period of 20 ns (25 MHz clock) -- real clock is slightly slower
# The minimum register to pin delay can be 0 ns, so set min to 0 ns
# The maximum delay must be 15 ns, so set max to
# 20 ns (period) - 15 ns (max delay) = 5 ns

set_output_delay -clock SD_Clk -min 0ns [get_ports SD_*]
set_output_delay -clock SD_Clk -max 5ns [get_ports SD_*]

# Same clock as above.  The minimum delay is the 0 ns set above, plus the
# board delay (500 ps), plus the minimum output delay of the SD_Card (0 ns).
# The maximum delay is the clock delay (15 ns set above) plus board delay
# (1 ns) plus maximum output delay of the SD_Card (14 ns) = 30 ns.

set_input_delay -clock SD_Clk -min 500ps [get_ports SD_*]
set_input_delay -clock SD_Clk -max  30ns [get_ports SD_*]

# This is obviously impossible, but the system only latches every second clock:

set_multicycle_path -from [get_ports SD_*] -to [get_registers *] -setup 2
set_multicycle_path -from [get_ports SD_*] -to [get_registers *] -hold  1
#-------------------------------------------------------------------------------


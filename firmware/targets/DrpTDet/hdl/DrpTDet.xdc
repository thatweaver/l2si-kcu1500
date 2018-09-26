set_property PACKAGE_PIN AV39 [get_ports {timingRefClkN}]
set_property PACKAGE_PIN AV38 [get_ports {timingRefClkP}]
set_property PACKAGE_PIN AU46 [get_ports {timingRxN}]
set_property PACKAGE_PIN AU45 [get_ports {timingRxP}]
set_property PACKAGE_PIN AU41 [get_ports {timingTxN}]
set_property PACKAGE_PIN AU40 [get_ports {timingTxP}]

create_clock -period 5.38 -name timingRefClkP [get_ports {timingRefClkP}]

set_property -dict {PACKAGE_PIN AP24 IOSTANDARD LVDS_18} [get_ports sda]
set_property -dict {PACKAGE_PIN AN24 IOSTANDARD LVDS_18} [get_ports scl]
set_property -dict {PACKAGE_PIN AL24 IOSTANDARD LVDS_18} [get_ports i2c_rst_l]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[0]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}] \
                 -group [get_clocks -include_generated_clocks {timingRefClkP}]
set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[1]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}] \
                 -group [get_clocks -include_generated_clocks {timingRefClkP}]
set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[2]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}] \
                 -group [get_clocks -include_generated_clocks {timingRefClkP}]
set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[3]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}] \
                 -group [get_clocks -include_generated_clocks {timingRefClkP}]

create_generated_clock -name clk200_0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name tdetClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT2}]

set_clock_groups -asynchronous \
                 -group [get_clocks {clk200_0}] \
                 -group [get_clocks {axilClk0}] \
                 -group [get_clocks {tdetClk0}]

create_generated_clock -name clk200_1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous \
                 -group [get_clocks {clk200_1}] \
                 -group [get_clocks {axilClk1}]

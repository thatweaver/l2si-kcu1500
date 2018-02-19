##############################################################################
## This file is part of 'axi-pcie-core'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'axi-pcie-core', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

######################
# FLASH: Constraints #
######################

set_property -dict {PACKAGE_PIN AL27 IOSTANDARD LVCMOS18} [get_ports emcClk]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_emcClk/O]

####################
# PCIe Constraints #
####################

##########
# System #
##########

set_property -dict {PACKAGE_PIN AW25 IOSTANDARD LVCMOS18} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN AY25 IOSTANDARD LVCMOS18} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN BA27 IOSTANDARD LVCMOS18} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN BA28 IOSTANDARD LVCMOS18} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN BB26 IOSTANDARD LVCMOS18} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN BB27 IOSTANDARD LVCMOS18} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN BA25 IOSTANDARD LVCMOS18} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN BB25 IOSTANDARD LVCMOS18} [get_ports {led[7]}]

set_property -dict {PACKAGE_PIN BC26 IOSTANDARD LVCMOS18} [get_ports {swDip[0]}]
set_property -dict {PACKAGE_PIN BC27 IOSTANDARD LVCMOS18} [get_ports {swDip[1]}]
set_property -dict {PACKAGE_PIN BE25 IOSTANDARD LVCMOS18} [get_ports {swDip[2]}]
set_property -dict {PACKAGE_PIN BF25 IOSTANDARD LVCMOS18} [get_ports {swDip[3]}]

set_property -dict {PACKAGE_PIN AV24 IOSTANDARD LVDS_25} [get_ports userClkP]
set_property -dict {PACKAGE_PIN AW24 IOSTANDARD LVDS_25} [get_ports userClkN]

##########################################
# QSFP[0] ports located in the core area #
##########################################

set_property -dict {PACKAGE_PIN AM21 IOSTANDARD LVCMOS18} [get_ports qsfp0RstL]
set_property -dict {PACKAGE_PIN AM22 IOSTANDARD LVCMOS18} [get_ports qsfp0LpMode]
set_property -dict {PACKAGE_PIN AP21 IOSTANDARD LVCMOS18} [get_ports qsfp0ModPrsL]
set_property -dict {PACKAGE_PIN AL21 IOSTANDARD LVCMOS18} [get_ports qsfp0ModSelL]

##########################################
# QSFP[1] ports located in the core area #
##########################################

set_property -dict {PACKAGE_PIN AU24 IOSTANDARD LVCMOS18} [get_ports qsfp1RstL]
set_property -dict {PACKAGE_PIN AR22 IOSTANDARD LVCMOS18} [get_ports qsfp1LpMode]
set_property -dict {PACKAGE_PIN AR23 IOSTANDARD LVCMOS18} [get_ports qsfp1ModPrsL]
set_property -dict {PACKAGE_PIN AT24 IOSTANDARD LVCMOS18} [get_ports qsfp1ModSelL]

##########
# Clocks #
##########

create_clock -period 6.400 -name userClkP [get_ports userClkP]
create_clock -period 11.111 -name emcClk [get_ports emcClk]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[0]}] \
                 -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[1]}] \
                 -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}]


######################################
# BITSTREAM: .bit file Configuration #
######################################
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_MODE SPIx8 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]
set_property BITSTREAM.STARTUP.LCK_CYCLE NoWait [current_design]
set_property BITSTREAM.STARTUP.MATCH_CYCLE NoWait [current_design]


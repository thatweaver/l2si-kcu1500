##############################################################################
## This file is part of 'axi-pcie-core'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'axi-pcie-core', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

###########
# QSFP[1] #
###########

set_property PACKAGE_PIN AR37 [get_ports {qsfp1RefClkN[0]}]
set_property PACKAGE_PIN AR36 [get_ports {qsfp1RefClkP[0]}]
set_property PACKAGE_PIN AN36 [get_ports {qsfp1RefClkP[1]}]
set_property PACKAGE_PIN AN37 [get_ports {qsfp1RefClkN[1]}]
set_property PACKAGE_PIN AK44 [get_ports {qsfp1RxN[3]}]
set_property PACKAGE_PIN AK43 [get_ports {qsfp1RxP[3]}]
set_property PACKAGE_PIN AK39 [get_ports {qsfp1TxN[3]}]
set_property PACKAGE_PIN AK38 [get_ports {qsfp1TxP[3]}]
set_property PACKAGE_PIN AL46 [get_ports {qsfp1RxN[2]}]
set_property PACKAGE_PIN AL45 [get_ports {qsfp1RxP[2]}]
set_property PACKAGE_PIN AL41 [get_ports {qsfp1TxN[2]}]
set_property PACKAGE_PIN AL40 [get_ports {qsfp1TxP[2]}]
set_property PACKAGE_PIN AM44 [get_ports {qsfp1RxN[1]}]
set_property PACKAGE_PIN AM43 [get_ports {qsfp1RxP[1]}]
set_property PACKAGE_PIN AM39 [get_ports {qsfp1TxN[1]}]
set_property PACKAGE_PIN AM38 [get_ports {qsfp1TxP[1]}]
set_property PACKAGE_PIN AN46 [get_ports {qsfp1RxN[0]}]
set_property PACKAGE_PIN AN45 [get_ports {qsfp1RxP[0]}]
set_property PACKAGE_PIN AN41 [get_ports {qsfp1TxN[0]}]
set_property PACKAGE_PIN AN40 [get_ports {qsfp1TxP[0]}]

##########
# Clocks #
##########

create_clock -period 6.400 -name qsfp1RefClkP0 [get_ports {qsfp1RefClkP[0]}]
create_clock -period 6.400 -name qsfp1RefClkP1 [get_ports {qsfp1RefClkP[1]}]
# create_clock -period 8.000 -name qsfp1RefClkP1 [get_ports {qsfp1RefClkP[1]}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks qsfp0RefClkP0] -group [get_clocks -include_generated_clocks qsfp0RefClkP1] -group [get_clocks -include_generated_clocks qsfp1RefClkP0] -group [get_clocks -include_generated_clocks qsfp1RefClkP1] -group [get_clocks -include_generated_clocks pciRefClkP] -group [get_clocks -include_generated_clocks pciExtRefClkP]

create_generated_clock -name phyRxClk10 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk10 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk10] -group [get_clocks phyTxClk10]

create_generated_clock -name phyRxClk11 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk11 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk11] -group [get_clocks phyTxClk11]

create_generated_clock -name phyRxClk12 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk12 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk12] -group [get_clocks phyTxClk12]

create_generated_clock -name phyRxClk13 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk13 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk13] -group [get_clocks phyTxClk13]

# set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}]
# set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP1}]



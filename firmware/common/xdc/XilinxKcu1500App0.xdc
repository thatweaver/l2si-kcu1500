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
# QSFP[0] #
###########

set_property PACKAGE_PIN AV39 [get_ports {qsfp0RefClkN[0]}]
set_property PACKAGE_PIN AV38 [get_ports {qsfp0RefClkP[0]}]
set_property PACKAGE_PIN AU36 [get_ports {qsfp0RefClkP[1]}]
set_property PACKAGE_PIN AU37 [get_ports {qsfp0RefClkN[1]}]
set_property PACKAGE_PIN AP44 [get_ports {qsfp0RxN[3]}]
set_property PACKAGE_PIN AP43 [get_ports {qsfp0RxP[3]}]
set_property PACKAGE_PIN AP39 [get_ports {qsfp0TxN[3]}]
set_property PACKAGE_PIN AP38 [get_ports {qsfp0TxP[3]}]
set_property PACKAGE_PIN AR46 [get_ports {qsfp0RxN[2]}]
set_property PACKAGE_PIN AR45 [get_ports {qsfp0RxP[2]}]
set_property PACKAGE_PIN AR41 [get_ports {qsfp0TxN[2]}]
set_property PACKAGE_PIN AR40 [get_ports {qsfp0TxP[2]}]
set_property PACKAGE_PIN AT44 [get_ports {qsfp0RxN[1]}]
set_property PACKAGE_PIN AT43 [get_ports {qsfp0RxP[1]}]
set_property PACKAGE_PIN AT39 [get_ports {qsfp0TxN[1]}]
set_property PACKAGE_PIN AT38 [get_ports {qsfp0TxP[1]}]
set_property PACKAGE_PIN AU46 [get_ports {qsfp0RxN[0]}]
set_property PACKAGE_PIN AU45 [get_ports {qsfp0RxP[0]}]
set_property PACKAGE_PIN AU41 [get_ports {qsfp0TxN[0]}]
set_property PACKAGE_PIN AU40 [get_ports {qsfp0TxP[0]}]

##########
# Clocks #
##########

create_clock -period 6.400 -name qsfp0RefClkP0 [get_ports {qsfp0RefClkP[0]}]
create_clock -period 6.400 -name qsfp0RefClkP1 [get_ports {qsfp0RefClkP[1]}]
# create_clock -period 8.000 -name qsfp0RefClkP1 [get_ports {qsfp0RefClkP[1]}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks qsfp0RefClkP0] -group [get_clocks -include_generated_clocks qsfp0RefClkP1] -group [get_clocks -include_generated_clocks pciRefClkP]

create_generated_clock -name phyRxClk00 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk00 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk00] -group [get_clocks phyTxClk00]

create_generated_clock -name phyRxClk01 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk01 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk01] -group [get_clocks phyTxClk01]

create_generated_clock -name phyRxClk02 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk02 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk02] -group [get_clocks phyTxClk02]

create_generated_clock -name phyRxClk03 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk03 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyRxClk03] -group [get_clocks phyTxClk03]

# set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}]
# set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP1}]



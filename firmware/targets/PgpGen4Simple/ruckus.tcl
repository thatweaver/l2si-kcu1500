# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
#loadRuckusTcl $::env(PROJ_DIR)/../../common
loadSource -dir "$::DIR_PATH/../../common/rtl"

loadSource -path "$::DIR_PATH/../../common/mig/Mig0.vhd"
loadSource -path "$::DIR_PATH/../../common/mig/Mig1.vhd"
loadIpCore -path "$::DIR_PATH/../../common/mig/XilinxKcu1500Mig0Core.xci"
loadIpCore -path "$::DIR_PATH/../../common/mig/XilinxKcu1500Mig1Core.xci"
loadConstraints -path "$::DIR_PATH/../../common/mig/XilinxKcu1500Mig0.xdc"
loadConstraints -path "$::DIR_PATH/../../common/mig/XilinxKcu1500Mig1.xdc"

loadRuckusTcl "$::DIR_PATH/../../common/coregen"

loadConstraints -path "$::DIR_PATH/../../common/xdc/XilinxKcu1500Core.xdc"
loadConstraints -path "$::DIR_PATH/../../common/xdc/XilinxKcu1500PciePhy.xdc"
loadConstraints -path "$::DIR_PATH/../../common/xdc/XilinxKcu1500App0.xdc"

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

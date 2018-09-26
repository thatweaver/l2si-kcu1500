# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
#loadRuckusTcl $::env(PROJ_DIR)/../../common
loadSource -dir "$::DIR_PATH/../../common/rtl"
#loadSource -path "$::DIR_PATH/../../common/mig/Mig0.vhd"

# Load local source Code and constraints
loadSource -dir "$::DIR_PATH/../../common/sim/"
loadSource -dir "$::DIR_PATH/hdl/"

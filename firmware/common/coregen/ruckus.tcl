# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load dcp files
loadSource -path "$::DIR_PATH/AppToMig.dcp"
loadIpCore -path "$::DIR_PATH/MigToPcie.xci"
loadIpCore -path "$::DIR_PATH/MonToPcie.xci"
loadIpCore -path "$::DIR_PATH/PcieXbar.xci"
loadIpCore -path "$::DIR_PATH/XilinxKcu1500PciePhy_DaqMaster.xci"
loadIpCore -path "$::DIR_PATH/MigXbar.xci"
loadIpCore -path "$::DIR_PATH/ila_0.xci"



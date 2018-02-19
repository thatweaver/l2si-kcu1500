export GIT_BYPASS = 1

# Define Firmware Version Number
export PRJ_VERSION = 0x00000000

# Define target part
export PRJ_PART = xcku115-flvb2104-2-e

export BOARD_PART = xilinx.com:kcu1500:part0:1.1

export REMOVE_UNUSED_CODE = 1

# Define target output
target: gui

# Using a non-standard target directory structure, 
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../..)

# Use top level makefile
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk

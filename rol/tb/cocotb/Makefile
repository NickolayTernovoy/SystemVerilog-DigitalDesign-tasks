ыыыTOPLEVEL_LANG ?= verilog
SIM ?= icarus

PWD = $(shell pwd)

# Specify the path to the RTL design
VERILOG_SOURCES = $(PWD)/../../hdl/bitmanip_rol_solution.sv

# Fix the seed to ensure deterministic tests
export RANDOM_SEED := 123456789
# Cocotb settings
TOPLEVEL := bitmanip_rol_solution
MODULE := cocotb_rol_tb

# Include the main Cocotb Makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

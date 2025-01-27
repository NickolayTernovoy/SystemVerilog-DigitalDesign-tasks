TOPLEVEL_LANG ?= verilog
SIM ?= icarus

PWD = $(shell pwd)

# Specify the path to the RTL design
VERILOG_SOURCES = $(PWD)/../../hdl/bitmanip_rol_solution.sv

# Include EXTRA_ARGS only if SIM is verilator
ifeq ($(SIM), verilator)
  EXTRA_ARGS += --trace --trace-fst --trace-structs
endif

# Fix the seed to ensure deterministic tests
export RANDOM_SEED := 123456789
# Cocotb settings
TOPLEVEL := bitmanip_rol_solution
MODULE := cocotb_rol_tb

# Include the main Cocotb Makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

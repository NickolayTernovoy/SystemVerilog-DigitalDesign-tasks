# Minimal Makefile for cocotb and Icarus Verilog

TOPLEVEL_LANG ?= verilog  # Language for the top-level module
SIM = icarus             # Default simulator

PWD = $(shell pwd)

# Verilog source file
VERILOG_SOURCES = $(PWD)/../../hdl/bitmanip_rol_solution.sv

# Name of the DUT module (from the Verilog file)
COCOTB_TOPLEVEL := bitmanip_rol_solution

# Name of the Python module containing tests (without .py)
COCOTB_TEST_MODULES := cocotb_rol_tb

# Include cocotb's Makefile for simulation
include $(shell cocotb-config --makefiles)/Makefile.sim

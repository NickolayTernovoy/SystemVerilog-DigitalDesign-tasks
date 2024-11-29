# Digital Design Tasks and Modules

This repository contains a collection of tasks and modules related to **computer arithmetic**, **digital design**, and implementations inspired by various **textbooks**, **courses**, and **scientific papers**.

---

## Features

- **Testing**:
  - Supports **SystemVerilog-based testbenches**.
  - Supports **Python-based cocotb testbenches** for flexible and reusable testing.
- **Simulators**:
  - Successfully tested with **Icarus Verilog**.
  - Work in progress to verify compatibility with **Verilator**.

---

## How to Use

To use this repository, navigate to the folder of the module you are interested in. In the root of the module folder, you will find two subfolders: `hdl` and `tb`.

- To run tests, navigate to the `tb` folder.
- The `hdl` folder contains:
  - A **solution file** with a completed implementation of the described task.
  - An **empty template file** with the I/O defined, where you can describe your custom logic.  
    If you want to test your custom implementation, replace the top module for the DUT in the testbench, and then run the tests from the `tb` folder.


### Cocotb Test (Icarus Verilog)

1. **Install Dependencies**:
   - Python 3.x
   - cocotb:
     ```bash
     pip install cocotb
     ```
   - Icarus Verilog:
     ```bash
     sudo apt install iverilog  # For Linux
     brew install icarus-verilog  # For macOS
     ```

2. **Run the Test**:
   ```bash
   make SIM=icarus

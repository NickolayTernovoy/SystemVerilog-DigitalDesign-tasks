import cocotb
import random
from cocotb.triggers import Timer
import math

# Parameters
SIZE = 16  # Data size (matches Verilog SIZE parameter)
SHAMT_SIZE = math.ceil(math.log2(SIZE))  # Calculate shift amount size using log2
N = 2 ** SIZE  # Total iterations, matches `N = 2**SIZE` in Verilog
DEBUG_INFO = True

# Helper function: Rotate left
def rotate_left(value, amount, size=SIZE):
    """Performs left rotation of a given value."""
    return ((value << amount) & ((1 << size) - 1)) | (value >> (size - amount))

@cocotb.test()
async def test_bitmanip_rol(dut):
    """Test the bitmanip_rol module."""
    # Reset the DUT inputs
    dut.data_i.value = 0
    dut.shamt_i.value = 0

    # Run test cases
    for i in range(N):  # Use N iterations
        # Generate random inputs
        data = random.randint(0, (1 << SIZE) - 1)  # Random data within SIZE range
        shamt = random.randint(0, (1 << SHAMT_SIZE) - 1)  # Random shift within SHAMT_SIZE range

        # Apply inputs to DUT
        dut.data_i.value = data
        dut.shamt_i.value = shamt

        # Wait for combinational logic to settle
        await Timer(1, units="ns")

        # Get the outputs
        result_by_borders = int(dut.result_by_borders_o.value)
        result_by_shift = int(dut.result_by_shift_o.value)

        # Compute the expected golden value
        golden_value = rotate_left(data, shamt)

        # Assertions
        assert result_by_borders == result_by_shift, (
            f"Mismatch between borders and shift logic at iteration {i}: "
            f"result_by_borders={result_by_borders}, result_by_shift={result_by_shift}"
        )
        assert result_by_borders == golden_value, (
            f"Golden value mismatch at iteration {i}: "
            f"golden_value={golden_value}, result_by_borders={result_by_borders}"
        )

        # Debug information
        if DEBUG_INFO:
            dut._log.info(
                f"Iteration {i}: data={data:#x}, shamt={shamt}, "
                f"golden_value={golden_value:#x}, result_by_borders={result_by_borders:#x}, "
                f"result_by_shift={result_by_shift:#x}"
            )

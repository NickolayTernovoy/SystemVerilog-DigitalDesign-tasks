`timescale 1ns / 1ps

module rol_tb;
// Clock generation
  reg clk;
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period clock
  end

  // Param declaration
  localparam SIZE = 16;
  localparam SHAMT_SIZE = $clog2(SIZE);
  localparam N = 2**SIZE;
  localparam DEBUG_INFO = 1;

  // DUT instantiation
  reg  [SIZE-1:0] data;
  reg  [SHAMT_SIZE-1:0] shamt;
  wire [SIZE-1:0] result_by_borders_o;
  wire [SIZE-1:0] result_by_shift_o;

  bitmanip_rol rol_dut (
    .data_i               (data               ),
    .shamt_i              (shamt              ),
    .result_by_borders_o  (result_by_borders_o),
    .result_by_shift_o    (result_by_shift_o  )
  );

  // Helper function for left rotate
  function automatic [SIZE-1:0] rotate_left;
    input [SIZE-1:0] value;
    input [SHAMT_SIZE-1:0] amount;
    rotate_left = (value << amount) | (value >> (SIZE - amount));
  endfunction

  // Test procedure
  initial begin
    // Initialize inputs
    data = 0;
    shamt = 0;

    // Wait for reset to finish if needed
    // #(reset_duration);

    for (int i = 0; i < N; i = i + 1) begin
      data = $urandom_range(0, 2**SIZE - 1);
      shamt = $urandom_range(0, SHAMT_SIZE-1);

      #10; // Wait for a clock cycle

      assert(result_by_borders_o == result_by_shift_o)
        else $fatal("Assertion failed at iteration %0d: result_by_borders_o=%h, result_by_shift_o=%h", i, result_by_borders_o, result_by_shift_o);
      assert(result_by_borders_o == rotate_left(data, shamt))
        else $fatal("Assertion failed at iteration %0d: golden_value=%h, result_by_borders_o=%h", i, rotate_left(data, shamt), result_by_borders_o);

      if (DEBUG_INFO) begin
        $display("Iter = %0d", i);
        $display("Golden value = %h", rotate_left(data, shamt));
        $display("result_by_borders_o = %h, result_by_shift_o = %h", result_by_borders_o, result_by_shift_o);
      end
    end

    $finish;
  end

endmodule

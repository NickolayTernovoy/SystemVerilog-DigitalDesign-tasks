`timescale 1ns / 1ps

module bitmanip_rol_solution #(
    parameter SIZE = 16, // Width of the data input and output
    parameter SHAMT_SIZE = $clog2(SIZE) // Width of the shift amount input
)(
    // Do not modify the input/output ports of this module
    input  [SIZE-1:0]       data_i                 , // Input data to be rotated
    input  [SHAMT_SIZE-1:0] shamt_i                , // Shift amount (number of positions to rotate)
    output [SIZE-1:0]       result_by_shift_o      , // Output result computed using the shift approach
    output [SIZE-1:0]       result_by_borders_o    , // Output result computed using the border extension approach
    // Ports for verification
    input  [SIZE-1:0]       golden_value_i         , // Expected (golden) value for verification
    output                  result_by_shift_err_o  , // Error flag: set if result_by_shift_o does not match golden_value_i
    output                  result_by_borders_err_o  // Error flag: set if result_by_borders_o does not match golden_value_i
);
// Local signal declaration
logic [2*SIZE-1:0] result_by_borders_o_comb;

// **************************
//       Rotation Logic
// **************************

// Approach 1: Using shift and OR
assign result_by_shift_o = (data_i << shamt_i) | (data_i >> (SIZE - shamt_i));

// Approach 2: Using border extension
assign result_by_borders_o_comb   = {data_i, data_i} << shamt_i;
assign result_by_borders_o        = result_by_borders_o_comb[2*SIZE-1:SIZE];

// **************************
//       Verification Logic
// **************************

// Logic for mismatch detection
assign result_by_shift_err_o    = (result_by_shift_o   != golden_value_i); // Error flag for approach 1
assign result_by_borders_err_o  = (result_by_borders_o != golden_value_i); // Error flag for approach 2

endmodule

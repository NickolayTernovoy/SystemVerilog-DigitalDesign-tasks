`timescale 1ns / 1ps
`define SVA_ENABLE 1
module float_to_fix #(
    parameter EXP_MSB_POS    = 14, // MSB in exponent filed
    parameter EXP_LSB_POS    = 10, // LSB in exponent field
    parameter FLOAT_OP_WIDTH = 16, // Width of the floating-point input
    parameter FIXED_OP_WIDTH = 80  // Width of the fixed-point output
)(
`ifdef SVA_ENABLE
    input  wire logic                      clk_i                , // Clock input
    input  wire logic                      rst_n_i              , // Active-low reset input
`endif
    input  wire logic [FLOAT_OP_WIDTH-1:0] float_point_operand_i, // Input floating-point operand
    output var  logic [FIXED_OP_WIDTH-1:0] fixed_point_value_o  , // Output fixed-point value
    output var  logic                      nan_flag_o           , // Output NaN flag
    output var  logic                      snan_flag_o          , // Output sNaN flag
    output var  logic                      inf_flag_o             // Output +/-inf flag
);
    // Declare local signals
    logic                                   sign                      ; // Sign bit of the floating-point number
    logic [EXP_MSB_POS - EXP_LSB_POS:0]     exp                       ; // Exponent of the floating-point number
    logic [EXP_LSB_POS - 1:0]               mantissa                  ; // Mantissa of the floating-point number
    logic                                   normal_bit                ; // Normalization bit (indicates non-zero exponent)
    logic [EXP_MSB_POS - EXP_LSB_POS:0]     norm_exp                  ; // Normalized exponent value
    logic [EXP_LSB_POS :0]                  norm_mantissa             ; // Normalized mantissa (includes hidden '1' for normalized numbers)
    logic [EXP_LSB_POS + 1:0]               sign_norm_mantissa        ; // Signed normalized mantissa
    logic [FIXED_OP_WIDTH - 1:0]            fixed_point_value_2s_cmpl ; // Sign handler
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Extract the sign, exponent, and mantissa from the input
    always_comb begin
        sign     = float_point_operand_i[EXP_MSB_POS + 1              ]; // Sign bit
        exp      = float_point_operand_i[EXP_MSB_POS     : EXP_LSB_POS]; // Exponent (5 bits)
        mantissa = float_point_operand_i[EXP_LSB_POS - 1 : 0          ]; // Mantissa (10 bits)
    end
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Special Cases detection
    // qNaN: Exponent is all 1's, MSB of mantissa is 1
    always_comb nan_flag_o = (&exp) & mantissa[EXP_LSB_POS-1];

    // sNaN: Exponent is all 1's, MSB of mantissa is 0, and at least one bit in mantissa is non-zero
    always_comb snan_flag_o = (&exp) & ~mantissa[EXP_LSB_POS-1] & (|mantissa[EXP_LSB_POS-2:0]);

    // Infinity: Exponent is all 1's, and all mantissa bits are 0
    always_comb inf_flag_o = (&exp) & ~(|mantissa);
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Check if the number is normalized (non-zero exponent)
    always_comb normal_bit = |exp;

    // Adjust exponent for normalized numbers by subtracting 1 to account for the hidden bit position,
    // or return 0 for denormalized numbers
    always_comb norm_exp = normal_bit ? exp - 1'b1 : '0;

    // Add the hidden '1' bit for normalized numbers or keep denormalized mantissa as-is
    always_comb norm_mantissa = {normal_bit, mantissa};

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Compute the fixed-point value by shifting the signed mantissa by the normalized exponent
    always_comb fixed_point_value_2s_cmpl = FIXED_OP_WIDTH'({norm_mantissa} << norm_exp);
    // 2's complement handler
    always_comb fixed_point_value_o = sign ? FIXED_OP_WIDTH'(~fixed_point_value_2s_cmpl + 1'b1) :
                                             FIXED_OP_WIDTH'( fixed_point_value_2s_cmpl)        ;
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // System Verilog Assertion
    ///////////////////////////////////////////////////////////////////////////////////////////////
`ifdef SVA_ENABLE

    SVA_SNAN_IMPLIES_NAN: assert property (
        @(negedge clk_i) disable iff (~rst_n_i)
        (snan_flag_o) |-> (nan_flag_o)
    ) else $error("Error: sNaN is a subset of NaN and must be asserted simultaneously with nan_flag_o!");

    SVA_NAN_AND_INF_EXCLUSIVE: assert property (
        @(negedge clk_i) disable iff (~rst_n_i)
        (nan_flag_o |-> ~inf_flag_o)
    ) else $error("Error: NaN and +/-Infinity cannot be asserted simultaneously!");

    SVA_INF_AND_NaN_EXCLUSIVE: assert property (
        @(negedge clk_i) disable iff (~rst_n_i)
        (inf_flag_o |-> ~nan_flag_o)
    ) else $error("Error: NaN and +/-Infinity cannot be asserted simultaneously!");

`endif

endmodule

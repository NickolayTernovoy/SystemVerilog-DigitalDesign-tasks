`timescale 1ns / 1ps

module float_to_fix #(
    parameter EXP_MSB_POS    = 14, // MSB in exponent filed
    parameter EXP_LSB_POS    = 10, // LSB in exponent field
    parameter FLOAT_OP_WIDTH = 16, // Width of the floating-point input
    parameter FIXED_OP_WIDTH = 40  // Width of the fixed-point output
)(
    input  wire logic [FLOAT_OP_WIDTH-1:0] float_point_operand_i, // Input floating-point operand
    output var  logic [FIXED_OP_WIDTH-1:0] fixed_point_value_o    // Output fixed-point value
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
        sign     = float_point_operand_i[15   ]; // Sign bit
        exp      = float_point_operand_i[14:10]; // Exponent (5 bits)
        mantissa = float_point_operand_i[9:0  ]; // Mantissa (10 bits)
    end
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Check if the number is normalized (non-zero exponent)
    always_comb normal_bit = |exp;

    // If the number is normalized, subtract 1 because the maximum exponent value 
    // is reserved for special cases (infinity and NaN)
    always_comb norm_exp = normal_bit ? exp - 1'b1 : '0;

    // Add the hidden '1' bit for normalized numbers or keep denormalized mantissa as-is
    always_comb norm_mantissa = {normal_bit, mantissa};

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Compute the fixed-point value by shifting the signed mantissa by the normalized exponent
    always_comb fixed_point_value_2s_cmpl = {norm_mantissa} << norm_exp;
    // 2's complement handler
    always_comb fixed_point_value_o = sign ? FIXED_OP_WIDTH'(~fixed_point_value_2s_cmpl + 1'b1) :
                                             FIXED_OP_WIDTH'( fixed_point_value_2s_cmpl)        ;

endmodule

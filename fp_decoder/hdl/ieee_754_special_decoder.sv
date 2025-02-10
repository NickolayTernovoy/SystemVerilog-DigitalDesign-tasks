`timescale 1ns / 1ps

module ieee_754_special_decoder #(
    // Parameter definitions:
    // EXP_MSB_POS: MSB position of the exponent field (Example for fp16: 14; for fp32: 30; for bf16: 7; for fp64: 62)
    // EXP_LSB_POS: LSB position of the exponent field (Example for fp16: 10; for fp32: 23; for bf16: 0; for fp64: 52)
    // FP_WIDTH: Total bit width of the floating-point representation (Example for fp16: 16; for fp32: 32; for bf16: 16; for fp64: 64)
    parameter EXP_MSB_POS = 14,
    parameter EXP_LSB_POS = 10,
    parameter FP_WIDTH    = 16
)(
    input  wire logic [FP_WIDTH-1:0] fp_operand_i,       // Input IEEE-754 bit string
    output logic                     qnan_flag_o,        // Quiet NaN flag
    output logic                     snan_flag_o,        // Signaling NaN flag
    output logic                     nan_flag_o,         // NaN flag
    output logic                     pos_inf_flag_o,     // Positive Infinity flag
    output logic                     neg_inf_flag_o,     // Negative Infinity flag
    output logic                     zero_flag_o,        // Zero flag
    output logic                     subnormal_flag_o    // Subnormal (denormalized) number flag (regardless of sign)
);

    // Calculate field widths:
    // EXP_WIDTH: Width of the exponent field (Example for fp16: 5 bits; for fp32: 8 bits; for bf16: 8 bits; for fp64: 11 bits)
    localparam EXP_WIDTH  = EXP_MSB_POS - EXP_LSB_POS + 1;
    // MANT_WIDTH: Width of the mantissa field (Example for fp16: 10 bits; for fp32: 23 bits; for bf16: 7 bits; for fp64: 52 bits)
    localparam MANT_WIDTH = EXP_LSB_POS;

    // Extract fields: sign, exponent, and mantissa from the input
    logic                   sign;      // Sign bit
    logic [EXP_WIDTH-1:0]   exp;       // Exponent field
    logic [MANT_WIDTH-1:0]  mantissa;  // Mantissa field
    // Local signals for bitwise comparisons
    logic exp_all_ones;
    logic exp_all_zeros;
    logic mant_zero;

    // IEEE-754 operand decomposition
    always_comb begin
        sign     = fp_operand_i[FP_WIDTH-1];               // Sign bit is the MSB
        exp      = fp_operand_i[EXP_MSB_POS:EXP_LSB_POS];  // Exponent bits
        mantissa = fp_operand_i[EXP_LSB_POS-1:0];          // Mantissa bits
    end

    always_comb exp_all_ones  = (exp      == {EXP_WIDTH{1'b1}} );
    always_comb exp_all_zeros = (exp      == {EXP_WIDTH{1'b0}} );
    always_comb mant_zero     = (mantissa == {MANT_WIDTH{1'b0}});

    // Detect Infinity:
    // Infinity is indicated when the exponent is all ones and the mantissa is zero.
    // The sign bit indicates positive (using ~sign) or negative (using sign) infinity.
    always_comb pos_inf_flag_o = (exp_all_ones & mant_zero & ~sign);
    always_comb neg_inf_flag_o = (exp_all_ones & mant_zero &  sign);

    // Detect NaN:
    // NaN is indicated when the exponent is all ones and the mantissa is non-zero.
    // For IEEE-754:
    //   - Quiet NaN (qNaN): The MSB of the mantissa is 1.
    //   - Signaling NaN (sNaN): The MSB of the mantissa is 0, but at least one of the lower bits is non-zero.
    always_comb qnan_flag_o = (exp_all_ones & ( mantissa[MANT_WIDTH-1  ]));
    always_comb snan_flag_o = (exp_all_ones & (~mantissa[MANT_WIDTH-1  ]) &
                                              (|mantissa[MANT_WIDTH-2:0]));

    always_comb nan_flag_o = qnan_flag_o | snan_flag_o;

    // Detect Zero:
    // Zero is indicated when both the exponent and mantissa are all zeros.
    always_comb zero_flag_o = (exp_all_zeros & mant_zero);

    // Detect Subnormal (Denormalized) numbers:
    // Subnormal numbers have an exponent of all zeros and a non-zero mantissa.
    always_comb subnormal_flag_o = (exp_all_zeros & ~mant_zero);

endmodule

module fp4_multiplier_e2m1 (
    input  logic       clk,
    input  logic [3:0] operand_a,
    input  logic [3:0] operand_b,
    input  logic       saturation_mode,
    input  logic       round_mode,      // Reserved for future use
    output logic [3:0] result,
    input  logic [3:0] golden_value,
    output logic       result_err
);
// --------------------------------------------------------------------------
// Local param Declarations
// --------------------------------------------------------------------------
localparam BIAS = 1;
localparam MAX_EXP = 3;

// --------------------------------------------------------------------------
// Signal Declarations
// --------------------------------------------------------------------------
typedef struct packed {
    logic sign;
    logic [1:0]  exponent;
    logic mantissa;
} fp4_e2m1_t;

fp4_e2m1_t a, b;

// Special cases detection
logic a_is_zero, b_is_zero;
logic special_case_zero;
logic a_is_normal;
logic b_is_normal;

// Sign calculation
logic result_sign;

// Exponent and mantissa processing
logic [3:0] exp_sum_raw;
logic [3:0] mantissa_product;
logic [4:0] mantissa_shifted;
logic       sticky_bit;
logic [1:0] a_mant, b_mant;
logic [5:0] final_exponent;

// Overflow/Underflow handling
logic overflow_occurred, underflow_occurred;
logic [1:0] rounded_mantissa;
logic       mantissa_overflow;
logic       round_up;

// --------------------------------------------------------------------------
// Combinational Logic
// --------------------------------------------------------------------------

// Format OCP e2m1 decomposition
always_comb begin
    a.sign     = operand_a[3  ];
    a.exponent = operand_a[2:1];
    a.mantissa = operand_a[0  ];
end

always_comb begin
    b.sign     = operand_b[3  ];
    b.exponent = operand_b[2:1];
    b.mantissa = operand_b[0  ];
end

// Special case detection
always_comb begin
    a_is_zero = (operand_a[2:0] == '0);
    b_is_zero = (operand_b[2:0] == '0);
end

// Normal bit handler
always_comb begin
    a_is_normal = |a.exponent;
    b_is_normal = |b.exponent;
end

// Mantissa preparation with subnormal handling
always_comb begin
    // For normal numbers: implied 1.mantissa
    // For subnormal numbers: 0.mantissa
    a_mant = {a_is_normal, a.mantissa};
    b_mant = {b_is_normal, b.mantissa};
end

// Exponent calculation with subnormal handling
always_comb begin
    exp_sum_raw = (a.exponent - BIAS)  + (b.exponent - BIAS)  +
    (1'b1 - a_is_normal) + (1'b1 - b_is_normal) ;
end

// Enhanced mantissa multiplier with subnormal support
always_comb begin
    case({a_mant, b_mant})
        4'b0101: mantissa_product = 4'b0001; // 0.5 * 0.5
        4'b0110: mantissa_product = 4'b0010; // 0.5 * 1.0
        4'b0111: mantissa_product = 4'b0011; // 0.5 * 1.5
        4'b1001: mantissa_product = 4'b0010; // 1.0 * 0.5
        4'b1010: mantissa_product = 4'b0100; // 1.0 * 1.0
        4'b1011: mantissa_product = 4'b0110; // 1.0 * 1.5
        4'b1101: mantissa_product = 4'b0011; // 1.5 * 0.5
        4'b1110: mantissa_product = 4'b0110; // 1.5 * 1.0
        4'b1111: mantissa_product = 4'b1001; // 1.5 * 1.5
        default: mantissa_product = 4'b0000; // Includes zero cases
    endcase
end

// Normalization and rounding
always_comb begin
    // Default assignments
    final_exponent = exp_sum_raw;
    mantissa_shifted = {mantissa_product, 1'b0};
    sticky_bit = 1'b0;
    // Normalize result
    if (mantissa_product[3]) begin
        final_exponent = final_exponent + 1'b1;
        mantissa_shifted = {1'b0, mantissa_product[3:1]};
        sticky_bit = mantissa_product[0];
    end
end

// Rounding logic
always_comb begin
    // Round-ties-to-even
    round_up = mantissa_shifted[1] &
    (mantissa_shifted[0] | sticky_bit | mantissa_shifted[2]);
    rounded_mantissa = mantissa_shifted[3:2] + round_up;
    // Handle rounding overflow
    if (rounded_mantissa == 2'b10) begin
        rounded_mantissa = 2'b01;
        final_exponent = final_exponent + 1'b1;
    end
    // Overflow/Underflow detection
    overflow_occurred = (final_exponent > MAX_EXP);
    underflow_occurred = (final_exponent < 0);
end

// Result sign
always_comb begin
    result_sign = a.sign ^ b.sign;
end

// Zero result
always_comb begin
    special_case_zero = a_is_zero | b_is_zero | underflow_occurred;
end

// Result assembly
always_comb begin
    result = '0;
    if (special_case_zero) begin
        result = {result_sign, 3'b000}; // ±0
    end else if (overflow_occurred & saturation_mode) begin
        result = {result_sign, 3'b111}; // ±MAX
    end else begin
        result = {result_sign, final_exponent[1:0], rounded_mantissa[0]};
    end
end

endmodule
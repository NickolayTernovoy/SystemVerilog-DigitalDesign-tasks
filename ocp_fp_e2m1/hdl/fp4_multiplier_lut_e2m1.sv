module fp4_multiplier_lut_e2m1 (
    input  logic [3:0] operand_a,
    input  logic [3:0] operand_b,
    output logic [3:0] result_o
);
    /////////////////////////////////////////////////////////////////////////////////
    // Local signals
    logic        result_sign;  // Result sign (XOR of the operand sign bits)
    logic [2:0]  magnitude;    // Result magnitude

    /////////////////////////////////////////////////////////////////////////////////
    // Sign handling: compute the result sign as the XOR of the operand sign bits
    always_comb result_sign = operand_a[3] ^ operand_b[3];
    /////////////////////////////////////////////////////////////////////////////////
    // Magnitude calculation using LUT (default value is zero)
    always_comb begin
        // Default value: zero
        magnitude = 3'b000;
        case ({operand_a[2:0], operand_b[2:0]})
            // Subnormal × Subnormal
            {3'b001, 3'b001}:
                magnitude = 3'b001; // 0.5 × 0.5 = 0.5

            // Subnormal × Normal
            {3'b001, 3'b010},
            {3'b010, 3'b001}:
                magnitude = 3'b001; // 0.5 × 1.0 = 0.5

            {3'b001, 3'b011},
            {3'b011, 3'b001}:
                magnitude = 3'b010; // 0.5 × 1.5 = 1.0

            {3'b001, 3'b110},
            {3'b110, 3'b001}:
                magnitude = 3'b011; // 0.5 × 3.0 = 1.5

            {3'b001, 3'b111},
            {3'b111, 3'b001}:
                magnitude = 3'b110; // 0.5 × 6.0 = 3.0

            // Normal × Normal
            {3'b010, 3'b010}:
                magnitude = 3'b010; // 1.0 × 1.0 = 1.0

            {3'b010, 3'b011},
            {3'b011, 3'b010}:
                magnitude = 3'b011; // 1.0 × 1.5 = 1.5

            {3'b010, 3'b110},
            {3'b110, 3'b010}:
                magnitude = 3'b110; // 1.0 × 3.0 = 3.0

            {3'b010, 3'b111},
            {3'b111, 3'b010}:
                magnitude = 3'b111; // 1.0 × 6.0 = 6.0

            {3'b011, 3'b011}:
                magnitude = 3'b110; // 1.5 × 1.5 = 3.0

            {3'b011, 3'b110},
            {3'b110, 3'b011}:
                magnitude = 3'b111; // 1.5 × 3.0 = 6.0

            {3'b011, 3'b111},
            {3'b111, 3'b011}:
                magnitude = 3'b111; // 1.5 × 6.0 = 6.0 (saturated)

            {3'b110, 3'b110}:
                magnitude = 3'b111; // 3.0 × 3.0 = 6.0 (saturated)

            {3'b110, 3'b111},
            {3'b111, 3'b110}:
                magnitude = 3'b111; // 3.0 × 6.0 = 6.0 (saturated)

            {3'b111, 3'b111}:
                magnitude = 3'b111; // 6.0 × 6.0 = 6.0 (saturated)

            // All other cases (including zeros) return 0
            default:
                magnitude = 3'b000;
        endcase
    end
    /////////////////////////////////////////////////////////////////////////////////
    // Final result assembly: combine sign and magnitude
    // TODO: 2's complement for CSA reduction tree for accumulation result
    always_comb result_o = {result_sign, magnitude};

endmodule

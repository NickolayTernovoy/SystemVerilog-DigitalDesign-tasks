// Zfa FP Constant Handler Module
// This module implements the logic for handling the Zfa extension, which is used
// to load floating-point constants into the datapath. It supports FP16, FP32, FP64,
// and BFloat16 formats by computing the appropriate exponent and mantissa fields
// based on a 5-bit immediate selection (imm_sel_i). Special cases such as NaN and
// Infinity are properly handled, with optional NaN boxing for format extension.

module zfa_imm_fli_handler #(
    parameter OUT_WIDTH = 64
)(
    input  wire logic                   clk_i       , // Clock input
    input  wire logic                   rst_n_i     , // Active-low reset input
    input  wire logic [4:0]             imm_sel_i   , // Select which of the 32 constants
    input  wire logic [1:0]             type_data_i , // 00=half, 01=single, 10=double, 11=bfloat
    input  wire logic                   nan_boxing_i, // Controls NaN boxing
    input wire  logic                   valid_en_i  , // Valid signal
    output      logic [OUT_WIDTH-1:0]   float_out_o   // Result
);
    // Internal signals
    logic                   sign;          // Sign bit for the floating-point constant.
    logic [10:0]            exp_dp;        // Double precision exponent field (11 bits).
    logic [7:0]             exp_sp;        // Single precision exponent field (8 bits).
    logic [4:0]             exp_hp;        // Half precision exponent field (5 bits).
    logic [2:0]             mantissa_3;    // Top 3 bits of mantissa (extracted from the immediate value).
    logic [15:0]            half_val;      // Assembled half-precision floating-point value (16 bits).
    logic [31:0]            single_val;    // Assembled single-precision floating-point value (32 bits).
    logic [63:0]            double_val;    // Assembled double-precision floating-point value (64 bits).
    logic [OUT_WIDTH-1:0]   float_out;     // Final floating-point output; width is parameterized by OUT_WIDTH.
    logic [OUT_WIDTH-1:0]   float_out_ff;  // Registered version of the final floating-point output.

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Control Logic
    // Sign bit generation
    always_comb sign = (imm_sel_i == '0);

    // Exponent selection for different formats (FP16, FP32, FP64).
    // Each case corresponds to an imm_sel_i entry and includes a comment
    // indicating the numerical value associated with that exponent setting.
    always_comb begin
        case (imm_sel_i)
            // 1.0
            5'd0: begin
                // Value: 1.0
                exp_hp = 5'b01111;         // bias 15  (unbiased 0)
                exp_sp = 8'b01111111;      // bias 127 (unbiased 0)
                exp_dp = 11'b01111111111;  // bias 1023 (unbiased 0)
            end
            // Minimum positive normal
            5'd1: begin
                // Value: smallest normal
                exp_hp = 5'b00001;         // smallest normal for FP16
                exp_sp = 8'b00000001;      // smallest normal for FP32
                exp_dp = 11'b00000000001;  // smallest normal for FP64
            end
            // 2**-15
            //Additionally, since 2**-16 and 2**-15 are subnormal in half-precision,
            //entry 1 is numerically greater than entries 2 and 3 for FLI.H.
            5'd2: begin
                // Value: c
                exp_hp = 5'b00000;         // subrnormal
                exp_sp = 8'b01101111;      // unbiased -16
                exp_dp = 11'b01101111111;  // unbiased -16
            end
            // 2**-14
            5'd3: begin
                // Value: 2**-14
                exp_hp = 5'b00000;         // subnormal
                exp_sp = 8'b01110000;      // unbiased -15
                exp_dp = 11'b01110000000;  // unbiased -15
            end
            // 2**-8
            5'd4: begin
                // Value: 2**-8
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01110111;      // unbiased -9
                exp_dp = 11'b01110111111;  // unbiased -9
            end
            // 2**-7
            5'd5: begin
                // Value: 2**-7
                exp_hp = 5'b01111;         // unbiased 0
                exp_sp = 8'b01111000;      // unbiased -8
                exp_dp = 11'b01111000000;  // unbiased -8
            end
            // 0.0625 (2**-4)
            5'd6: begin
                // Value: 2**-4 = 0.0
                exp_hp = 5'b01011;         // unbiased -5
                exp_sp = 8'b01111011;      // unbiased -5
                exp_dp = 11'b01111011111;  // unbiased -5
            end
            // 0.125 (2**-3)
            5'd7: begin
                // Value: 2**-3 = 0.125
                exp_hp = 5'b01101;         // unbiased -2
                exp_sp = 8'b01111100;      // unbiased -4
                exp_dp = 11'b01111100000;  // unbiased -4
            end
            // 0.25
            5'd8: begin
                // Value: 0.25
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111101;      // unbiased -3
                exp_dp = 11'b01111101111;  // unbiased -3
            end
            // 0.3125
            5'd9: begin
                // Value: 0.3125
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111101;      // unbiased -3
                exp_dp = 11'b01111101111;  // unbiased -3
            end
            // 0.375
            5'd10: begin
                // Value: 0.375
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111101;      // unbiased -3
                exp_dp = 11'b01111101111;  // unbiased -3
            end
            // 0.4375
            5'd11: begin
                // Value: 0.4375
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111101;      // unbiased -3
                exp_dp = 11'b01111101111;  // unbiased -3
            end
            // 0.5
            5'd12: begin
                // Value: 0.5
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111110;      // unbiased -2
                exp_dp = 11'b01111110000;  // unbiased -2
            end
            // 0.625
            5'd13: begin
                // Value: 0.625
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111110;      // unbiased -2
                exp_dp = 11'b01111110000;  // unbiased -2
            end
            // 0.75
            5'd14: begin
                // Value: 0.75
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111110;      // unbiased -2
                exp_dp = 11'b01111110000;  // unbiased -2
            end
            // 0.875
            5'd15: begin
                // Value: 0.875
                exp_hp = 5'b01110;         // unbiased -1
                exp_sp = 8'b01111110;      // unbiased -2
                exp_dp = 11'b01111110000;  // unbiased -2
            end
            // 1.0
            5'd16: begin
                // Value: 1.0
                exp_hp = 5'b01111;         // unbiased 0
                exp_sp = 8'b01111111;      // unbiased 0
                exp_dp = 11'b01111111111;  // unbiased 0
            end
            // 1.25
            5'd17: begin
                // Value: 1.25
                exp_hp = 5'b01111;         // unbiased 0
                exp_sp = 8'b01111111;      // unbiased 0
                exp_dp = 11'b01111111111;  // unbiased 0
            end
            // 1.5
            5'd18: begin
                // Value: 1.5
                exp_hp = 5'b01111;         // unbiased 0
                exp_sp = 8'b01111111;      // unbiased 0
                exp_dp = 11'b01111111111;  // unbiased 0
            end
            // 1.75
            5'd19: begin
                // Value: 1.75
                exp_hp = 5'b01111;         // unbiased 0
                exp_sp = 8'b01111111;      // unbiased 0
                exp_dp = 11'b01111111111;  // unbiased 0
            end
            // 2.0
            5'd20: begin
                // Value: 2.0
                exp_hp = 5'b10000;         // unbiased 1
                exp_sp = 8'b10000000;      // unbiased 1
                exp_dp = 11'b10000000000;  // unbiased 1
            end
            // 2.5
            5'd21: begin
                // Value: 2.5
                exp_hp = 5'b10000;         // unbiased 1
                exp_sp = 8'b10000000;      // unbiased 1
                exp_dp = 11'b10000000000;  // unbiased 1
            end
            // 3.0
            5'd22: begin
                // Value: 3.0
                exp_hp = 5'b10000;         // unbiased 1
                exp_sp = 8'b10000000;      // unbiased 1
                exp_dp = 11'b10000000000;  // unbiased 1
            end
            // 4.0
            5'd23: begin
                // Value: 4.0
                exp_hp = 5'b10001;         // unbiased 2
                exp_sp = 8'b10000001;      // unbiased 2
                exp_dp = 11'b10000000001;  // unbiased 2
            end
            // 8.0
            5'd24: begin
                // Value: 8.0
                exp_hp = 5'b10010;         // unbiased 3
                exp_sp = 8'b10000010;      // unbiased 3
                exp_dp = 11'b10000000010;  // unbiased 3
            end
            // 16.0
            5'd25: begin
                // Value: 16.0
                exp_hp = 5'b10011;         // unbiased 4
                exp_sp = 8'b10000011;      // unbiased 4
                exp_dp = 11'b10000000011;  // unbiased 4
            end
            // 128.0
            5'd26: begin
                // Value: 128.0
                exp_hp = 5'b10110;         // unbiased 7
                exp_sp = 8'b10000110;      // unbiased 7
                exp_dp = 11'b10000000110;  // unbiased 7
            end
            // 256.0
            5'd27: begin
                // Value: 256.0
                exp_hp = 5'b10111;         // unbiased 8
                exp_sp = 8'b10000111;      // unbiased 8
                exp_dp = 11'b10000000111;  // unbiased 8
            end
            // 2**15
            5'd28: begin
                // Value: 2**15
                exp_hp = 5'b11110;         // unbiased 15
                exp_sp = 8'b10001110;      // unbiased 15
                exp_dp = 11'b10000001110;  // unbiased 15
            end
            // 2**16
            5'd29: begin
                // Value: 2**16 (not representable in FP16 -> +Inf in half)
                exp_hp = 5'b11111;         // special case: +Inf for FP16
                exp_sp = 8'b10001111;      // unbiased 16
                exp_dp = 11'b10000001111;  // unbiased 16
            end
            // +Inf
            5'd30: begin
                // Value: +Infinity
                exp_hp = 5'b11111;         // +Inf
                exp_sp = 8'b11111111;      // +Inf
                exp_dp = 11'b11111111111;  // +Inf
            end
            // NaN
            5'd31: begin
                // Value: Canonical NaN
                exp_hp = 5'b11111;         // NaN
                exp_sp = 8'b11111111;      // NaN
                exp_dp = 11'b11111111111;  // NaN
            end
            // Default case
            default: begin
                exp_hp = '0;
                exp_sp = '0;
                exp_dp = '0;
            end
        endcase
    end

    // Mantissa top 3 bits selection.
    // Need only the top 3 bits of the mantissa, regardless of the floating-point
    // data type (FP16, FP32, FP64, or BF16), to represent all constants from the Zfa table.
    always_comb begin
        case (imm_sel_i)
            5'd9,  5'd13, 5'd17, 5'd21: mantissa_3 = 3'b010;
            5'd10, 5'd14, 5'd22, 5'd31: mantissa_3 = 3'b100;
            5'd11, 5'd15, 5'd19:        mantissa_3 = 3'b110;
            default:                    mantissa_3 = 3'b000;
        endcase
    end

    // Format-specific result assembly
    always_comb half_val   = {sign, exp_hp, mantissa_3, {7 {1'b0}} };
    always_comb single_val = {sign, exp_sp, mantissa_3, {20{1'b0}} };
    always_comb double_val = {sign, exp_dp, mantissa_3, {49{1'b0}} };

    // NaN boxing, bf16 handler
    always_comb begin
        float_out = '0;
        // Output selection with NaN boxing
        case (type_data_i)
            2'b00: begin // half
                float_out[15:0] = half_val;
                float_out[OUT_WIDTH-1:16] = nan_boxing_i ? '1 : '0;
            end
            2'b01: begin // single
                float_out[31:0] = single_val;
                float_out[OUT_WIDTH-1:32] = nan_boxing_i ? '1 : '0;
            end
            2'b10: begin // double
                float_out = double_val;
            end
            2'b11: begin // bfloat16
                // BFloat16 uses same exponent as FP32 but truncated mantissa
                float_out[15:0] = {sign, exp_sp, mantissa_3, {4{1'b0}}};
                float_out[OUT_WIDTH-1:16] = nan_boxing_i ? '1 : '0;
                end
            default: begin
                float_out = '0;
            end
        endcase
    end
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Flopping result and output propagation
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (~rst_n_i)
            float_out_ff <= '0;
        else if (valid_en_i)
            float_out_ff <= float_out;
    end

    assign float_out_o = float_out_ff;
    ///////////////////////////////////////////////////////////////////////////////////////////////
`ifdef SVA_ENABLE
    // SVA property to check that when FLI.H is executed for half precision,
    // entry 29 loads positive infinity (i.e., it is redundant with entry 30).
    // For FP16, positive infinity is represented by FP16_INF.
    localparam FP16_INF = 16'h7c00;
    SVA_FLIH_ENTRY29_INF: assert property (
        @(negedge clk_i) disable iff (!rst_n_i)
          ( (type_data_i == 2'b00 & ((imm_sel_i == 5'd29) | (imm_sel_i == 5'd30)) )
          |-> (half_val == FP16_INF)
    ) else $error("For FLI.H, entry 29 (like entry 30) must load FP16 positive infinity.");
`endif
///////////////////////////////////////////////////////////////////////////////////////////////
endmodule
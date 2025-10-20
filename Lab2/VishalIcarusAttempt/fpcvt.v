/**
 * @file FPCVT.v
 * @brief Converts a 12-bit two's complement integer to an 8-bit custom floating-point format.
 * @details The conversion follows the specification from CS M152A Lab 2.
 * The 8-bit floating-point format is composed of:
 * - 1-bit sign (s)
 * - 3-bit exponent (E)
 * - 4-bit significand (F)
 * The value is calculated as V = (-1)^s * F * 2^E.
 */
module FPCVT (
    input  wire [11:0] D, // Input data in 12-bit Two's Complement
    output wire        s, // Sign bit of the FP representation
    output reg  [2:0]  E, // 3-bit Exponent of the FP representation
    output reg  [3:0]  F  // 4-bit Significand of the FP representation
);

    //================================================================
    // Stage 1: Convert 2's Complement to Sign-Magnitude
    //================================================================
    // The sign bit 's' is the MSB of the input D.
    // The magnitude is the absolute value of D.
    // If D is negative, its magnitude is found by taking its two's complement (~D + 1).
    wire [11:0] magnitude;
    assign s = D[11];
    assign magnitude = s ? (~D + 1'b1) : D;

    //================================================================
    // Stage 2: Primary Conversion (Priority Encoder)
    //================================================================
    // This stage determines the preliminary exponent and a 5-bit value
    // containing the 4-bit significand and a 5th "round bit".
    // A priority-encoded case statement finds the most significant '1'
    // in the magnitude to determine the exponent and select the correct bits.
    reg [2:0] temp_E;
    reg [4:0] temp_F_and_round_bit; // {4'b significand, 1'b round_bit}

    always @(*) begin
        // The casex statement acts as a priority encoder, checking for the
        // position of the most significant '1' from MSB to LSB.
        casex (magnitude)
            12'b1xxx_xxxx_xxxx: begin // For D = -2048, magnitude is 2048 (1000...)
                temp_E = 3'd7;
                temp_F_and_round_bit = magnitude[11:7];
            end
            12'b01xx_xxxx_xxxx: begin // [1024-2047], 1 leading zero
                temp_E = 3'd7;
                temp_F_and_round_bit = magnitude[10:6];
            end
            12'b001x_xxxx_xxxx: begin // [512-1023], 2 leading zeros
                temp_E = 3'd6;
                temp_F_and_round_bit = magnitude[9:5];
            end
            12'b0001_xxxx_xxxx: begin // [256-511], 3 leading zeros
                temp_E = 3'd5;
                temp_F_and_round_bit = magnitude[8:4];
            end
            12'b0000_1xxx_xxxx: begin // [128-255], 4 leading zeros
                temp_E = 3'd4;
                temp_F_and_round_bit = magnitude[7:3];
            end
            12'b0000_01xx_xxxx: begin // [64-127], 5 leading zeros
                temp_E = 3'd3;
                temp_F_and_round_bit = magnitude[6:2];
            end
            12'b0000_001x_xxxx: begin // [32-63], 6 leading zeros
                temp_E = 3'd2;
                temp_F_and_round_bit = magnitude[5:1];
            end
            12'b0000_0001_xxxx: begin // [16-31], 7 leading zeros
                temp_E = 3'd1;
                temp_F_and_round_bit = magnitude[4:0];
            end
            default: begin // [0-15], >=8 leading zeros
                temp_E = 3'd0;
                // For E=0, significand is the 4 LSBs, not normalized.
                temp_F_and_round_bit = {magnitude[3:0], 1'b0};
            end
        endcase
    end


    //================================================================
    // Stage 3: Rounding and Overflow Handling
    //================================================================
    // This stage performs the rounding operation and handles all overflow cases.
    wire [3:0] pre_round_F;
    wire       round_bit;
    wire [4:0] rounded_F;           // 5 bits to hold potential carry-out
    wire       significand_overflow;

    // Split the 5-bit bundle into the pre-rounded significand and the round bit.
    assign pre_round_F = temp_F_and_round_bit[4:1];
    assign round_bit   = temp_F_and_round_bit[0];

    // Add the round bit. If it's 1, F is incremented. If 0, F is unchanged.
    assign rounded_F = {1'b0, pre_round_F} + round_bit;
    assign significand_overflow = rounded_F[4]; // Check for carry-out

    always @(*) begin
        if (significand_overflow) begin
            // This occurs when rounding 1111 up to 10000.
            if (temp_E == 3'b111) begin
                // Exponent is already maxed out. Saturate the output to the
                // largest possible FP value: E=7, F=15.
                E <= 3'b111;
                F <= 4'b1111;
            end else begin
                // Increment the exponent and set the new significand to 1000
                // as per the spec (e.g., 10000 is shifted right).
                E <= temp_E + 1'b1;
                F <= 4'b1000;
            end
        end else begin
            // No overflow. The exponent is unchanged and the significand
            // is the lower 4 bits of the rounding result.
            E <= temp_E;
            F <= rounded_F[3:0];
        end
    end

endmodule
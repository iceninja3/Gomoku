`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/03/2025 12:24:09 PM
// Design Name:
// Module Name: bcd_to_7seg
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module BCD_to_7Seg (
    input  [3:0] bcd_in,
    output reg [6:0] seg_out
);
    // Active-LOW (Common Anode) segment patterns for gfedcba order (0=ON, 1=OFF)
    always @(*) begin
        case (bcd_in)
            // gfedcba
            4'd0: seg_out = 7'b1000000; // 0 (abcdef ON, g OFF)
            4'd1: seg_out = 7'b1111001; // 1 (bc ON, adefg OFF)
            4'd2: seg_out = 7'b0100100; // 2 (abdeg ON, cf OFF)
            4'd3: seg_out = 7'b0110000; // 3 (abcdg ON, ef OFF)
            4'd4: seg_out = 7'b0011001; // 4 (bcfg ON, ade OFF)
            4'd5: seg_out = 7'b0010010; // 5 (acdfg ON, be OFF)
            4'd6: seg_out = 7'b0000010; // 6 (acdefg ON, b OFF)
            4'd7: seg_out = 7'b1111000; // 7 (abc ON, defg OFF)
            4'd8: seg_out = 7'b0000000; // 8 (abcdefg ON)
            4'd9: seg_out = 7'b0010000; // 9 (abcdfg ON, e OFF)
            default: seg_out = 7'b1111111; // Blank/Error (all segments OFF)
        endcase
    end
endmodule
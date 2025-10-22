`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2025 12:08:42 PM
// Design Name: 
// Module Name: fpcvt
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


module fpcvt(
    input wire[11:0] D,
    output wire S, output wire[2:0] E, output wire[3:0] F
    );

    reg [3:0] leadingNum;
    wire [10:0] mag;
    reg [2:0] eReg;
    reg fifthBit;
    reg [3:0] fReg;
    wire overflow;
    wire smallest;
    wire eOverflow;
    wire biggest;

    // sign bit
    assign S = D[11];
    // magnitude (absolute value of lower 11 bits)
    assign mag = S ? (~D[10:0] + 1) : D[10:0];

    // leading zero count on 11-bit mag (priority encoder)
    always @* begin
        casex (mag)
            11'b1??????????: leadingNum = 4'd0;
            11'b01?????????: leadingNum = 4'd1;
            11'b001????????: leadingNum = 4'd2;
            11'b0001???????: leadingNum = 4'd3;
            11'b00001??????: leadingNum = 4'd4;
            11'b000001?????: leadingNum = 4'd5;
            11'b0000001????: leadingNum = 4'd6;
            11'b00000001???: leadingNum = 4'd7;
            11'b000000001??: leadingNum = 4'd8;
            11'b0000000001?: leadingNum = 4'd9;
            11'b00000000001: leadingNum = 4'd10;
            default:         leadingNum = 4'd11;
        endcase
    end

    // map leadingNum
    always @* begin
        case (leadingNum)
            4'd0: eReg = 3'd7;
            4'd1: eReg = 3'd6;
            4'd2: eReg = 3'd5;
            4'd3: eReg = 3'd4;
            4'd4: eReg = 3'd3;
            4'd5: eReg = 3'd2;
            4'd6: eReg = 3'd1;
            default: eReg = 3'd0;
        endcase
    end

    // extract significand and fifth bit safely (no out-of-range indices)
    always @* begin
        if (eReg == 3'd0) begin
            // exponent 0: significand is least-significant 4 bits
            fReg = mag[3:0];
            fifthBit = 1'b0;
        end
        else if (leadingNum <= 7) begin
            // significand: bits [10-leadingNum -: 4]
            fReg = mag[10-leadingNum -: 4];
            // fifth bit is at index (10-leadingNum-4) == (6-leadingNum). Only valid when leadingNum <= 6.
            fifthBit = (leadingNum <= 6) ? mag[6-leadingNum] : 1'b0;
        end
        else begin
            fReg = 4'b0000;
            fifthBit = 1'b0;
        end
    end

    // overflow predicate: only possible when fReg == 1111 and fifthBit == 1
    assign overflow = (fReg == 4'b1111) && (fifthBit == 1'b1);
    assign smallest = (D == 12'b100000000000); // -2048 special case
    assign eOverflow = overflow && eReg != 3'd7;
    assign biggest = overflow && eReg == 3'd7;

    // final outputs: apply rounding; if overflow then set f to 1000 and increment exponent
    assign E = (smallest || biggest) ? 3'd7 : (eReg + ((eOverflow) ? 3'd1 : 3'd0));
    assign F = (smallest || biggest) ? 4'b1111 : (overflow ? 4'b1000 : (fReg + (fifthBit ? 4'd1 : 4'd0)));

endmodule
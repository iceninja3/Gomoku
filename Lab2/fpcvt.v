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
    input wire[11:0] d,
    output wire s, output wire[2:0] e, output wire[3:0] f
    );
    
    reg [3:0] leadingNum;
    wire [10:0] mag;
    reg [2:0] eReg;
    reg fifthBit;
    reg [3:0] fReg;
    wire overflow;

    // if d== -2048, automaticlaly write its value 
    
    // clearly, sign bit from 2's complement <=> sign bit in fp
    assign s = d[11];
   
    assign mag = s ? (~d[10:0] + 1) : d[10:0];
    
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
            11'b00000000000: leadingNum = 4'd11;
        endcase
    end
    
    always @* begin
        case (leadingNum)
            4'd1: eReg = 3'd7;
            4'd2: eReg = 3'd6;
            4'd3: eReg = 3'd5;
            4'd4: eReg = 3'd4;
            4'd5: eReg = 3'd3;
            4'd6: eReg = 3'd2;
            4'd7: eReg = 3'd1;
            default: eReg = 3'd0;
        endcase
    end
    
    always @* begin
        if (eReg == 3'd0) begin
            fReg = mag[3:0];
            fifthBit = 0;
        end
        else if (leadingNum <= 7) begin
            fReg = mag[10-leadingNum -: 4];
            fifthBit = leadingNum == 7 ? 0 : mag[10-leadingNum-4];
        end
        else begin
            fReg = 4'b0000;
            fifthBit = 0;
        end
    end
    
    assign overFlow = (fReg == 4'b1111 && fifthBit == 1'b1);
    assign e = eReg + overFlow;
    assign f = (fReg+fifthBit)>>overflow;
endmodule

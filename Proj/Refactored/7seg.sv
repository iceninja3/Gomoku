`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 12:37:59 PM
// Design Name: 
// Module Name: 7seg
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

module seg7_control(input clk, rst, input [7:0] num_p1, num_p2, output reg [6:0] seg, output reg [3:0] an, output wire dp);
    assign dp = 1;
    reg [19:0] refresh_counter;
    always @(posedge clk) begin
        if(rst) refresh_counter <= 0; else refresh_counter <= refresh_counter + 1;
    end
    wire [1:0] digit_select = refresh_counter[19:18];
    reg [3:0] hex_digit;
    always @* begin
        case(digit_select)
            // rightmost is P2
            2'b00: begin an = 4'b1110; hex_digit = num_p2[3:0]; end
            2'b01: begin an = 4'b1101; hex_digit = num_p2[7:4]; end
            // leftmost is P1
            2'b10: begin an = 4'b1011; hex_digit = num_p1[3:0]; end
            2'b11: begin an = 4'b0111; hex_digit = num_p1[7:4]; end
        endcase
    end
    always @* begin
        case(hex_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule

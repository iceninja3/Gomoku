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

module seg7_control(
    input clk, 
    input rst, 
    input [7:0] num_p1,
    input [7:0] num_p2, 
    output reg [6:0] seg, 
    output reg [3:0] an, 
    output wire dp
);
    assign dp = 1;

    // Refresh Counter for multiplexing
    reg [19:0] refresh_counter;
    always @(posedge clk) begin
        if(rst) 
            refresh_counter <= 0;
        else 
            refresh_counter <= refresh_counter + 1;
    end

    // Use top 2 bits to select which digit is active
    wire [1:0] digit_select = refresh_counter[19:18];
    
    reg [3:0] display_digit;

    // Hexadecimal to decimal    
    wire [3:0] p2_ones = num_p2 % 10;
    wire [3:0] p2_tens = (num_p2 / 10) % 10;
    
    wire [3:0] p1_ones = num_p1 % 10;
    wire [3:0] p1_tens = (num_p1 / 10) % 10;

    // Multiplexer to select which digit to show based on counter
    always @* begin
        case(digit_select)
            // Rightmost 2 digits (Player 2)
            2'b00: begin 
                an = 4'b1110; 
                display_digit = p2_ones; 
            end
            2'b01: begin 
                an = 4'b1101; 
                display_digit = p2_tens; 
            end
            
            // Leftmost 2 digits (Player 1)
            2'b10: begin 
                an = 4'b1011; 
                display_digit = p1_ones; 
            end
            2'b11: begin 
                an = 4'b0111; 
                display_digit = p1_tens; 
            end
        endcase
    end

    // 7-Segment Decoder
    always @* begin
        case(display_digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111; // Off
        endcase
    end

endmodule

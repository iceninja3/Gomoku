`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 01:22:18 PM
// Design Name: 
// Module Name: display
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


module display(
    input wire clk_100mhz,
    input wire rst,
    input wire clk_500hz,
    input wire clk_4hz,
    input wire [3:0] bcd_min_tens,
    input wire [3:0] bcd_min_ones,
    input wire [3:0] bcd_sec_tens,
    input wire [3:0] bcd_sec_ones,
    input wire is_adjust,
    input wire is_sel_sec,
    
    output reg [6:0] segment,
    output reg [3:0] anode
    );
    
    reg [1:0] mux_sel;
    always @(posedge clk_100mhz) begin
        if (rst) begin
            mux_sel <= 2'd0;
        end
        else if (clk_500hz) begin
            mux_sel <= mux_sel + 1;
        end
    end
    
    reg blink_on;
    always @(posedge clk_100mhz) begin
        if (rst) begin
            blink_on = 1'b1;
        end
        else if (clk_4hz) begin
            blink_on <= !blink_on;
        end
    end
    
    reg [3:0] bcd_mux_data;
    always @(*) begin
        case (mux_sel)
            2'b00: bcd_mux_data = bcd_min_tens;
            2'b01: bcd_mux_data = bcd_min_ones;
            2'b10: bcd_mux_data = bcd_sec_tens;
            2'b11: bcd_mux_data = bcd_sec_ones;
        endcase
    end
    
    wire [6:0] segment_pattern;
    BCD_to_7Seg i_decoder(
        .bcd_in(bcd_mux_data),
        .seg_out(segment_pattern)
    );
    
    reg blank_this_digit;
    always @(*) begin
        anode = 4'b0000;
        segment = 7'b1111111;
        
        if (is_adjust && !blink_on) begin
            if (!is_sel_sec && (mux_sel == 2'b00 || mux_sel == 2'b01)) begin
                blank_this_digit = 1'b1;
            end
            else if (is_sel_sec && (mux_sel == 2'b10 || mux_sel == 2'b11)) begin
                blank_this_digit = 1'b1;
            end
            else begin
                blank_this_digit = 1'b0;
            end
        end
        
        if (!blank_this_digit) begin
            segment = segment_pattern;
            case (mux_sel)
                2'b00: anode = 4'b0001;
                2'b01: anode = 4'b0010;
                2'b10: anode = 4'b0100;
                2'b11: anode = 4'b1000;
                default: anode = 4'b0000;
            endcase
        end
    end
endmodule

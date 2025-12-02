`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 12:37:59 PM
// Design Name: 
// Module Name: vga_sync
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

module vga_sync(input clk, rst, output hsync, vsync, video_on, output [9:0] x, y);
    localparam HD=640, HF=16, HB=48, HR=96, VD=480, VF=10, VB=33, VR=2;
    reg [9:0] h_count, v_count;
    always @(posedge clk) begin
        if (rst) begin h_count<=0; v_count<=0; end
        else if (h_count == 799) begin
            h_count<=0;
            if (v_count == 524) v_count<=0; else v_count<=v_count+1;
        end else h_count<=h_count+1;
    end
    assign hsync = ~(h_count >= (HD+HF) && h_count < (HD+HF+HR));
    assign vsync = ~(v_count >= (VD+VF) && v_count < (VD+VF+VR));
    assign video_on = (h_count < HD) && (v_count < VD);
    assign x = h_count; assign y = v_count;
endmodule

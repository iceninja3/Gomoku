`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 12:24:09 PM
// Design Name: 
// Module Name: clock
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


module clock(
    input wire clk_100mhz,
    output wire clk_1hz,
    output wire clk_2hz,
    output wire clk_500hz,
    output wire clk_4hz
    );
    localparam CLK_FREQ = 100_000_000;
    localparam CNT_1HZ_MAX = (CLK_FREQ / 1) - 1;
    localparam CNT_2HZ_MAX = (CLK_FREQ / 2) - 1;
    localparam CNT_500HZ_MAX = (CLK_FREQ / 500) - 1;
    localparam CNT_4HZ_MAX = (CLK_FREQ / 4) - 1;
    
    reg [31:0] cnt_1hz = 32'b0;
    reg [31:0] cnt_2hz = 32'b0;
    reg [31:0] cnt_500hz = 32'b0;
    reg [31:0] cnt_4hz = 32'b0;
    
    always @(posedge clk_100mhz) begin
        if (cnt_1hz == CNT_1HZ_MAX) begin
            cnt_1hz <= 0;
        end
        else begin
            cnt_1hz <= cnt_1hz + 1;
        end
        
        if (cnt_2hz == CNT_2HZ_MAX) begin
            cnt_2hz <= 0;
        end
        else begin
            cnt_2hz <= cnt_2hz + 1;
        end
        
        if (cnt_500hz == CNT_500HZ_MAX) begin
            cnt_500hz <= 0;
        end
        else begin
            cnt_500hz <= cnt_500hz + 1;
        end
        
        if (cnt_4hz == CNT_4HZ_MAX) begin
            cnt_4hz <= 0;
        end
        else begin
            cnt_4hz <= cnt_4hz + 1;
        end
    end
    
    assign clk_1hz = (cnt_1hz == CNT_1HZ_MAX);
    assign clk_2hz = (cnt_2hz == CNT_2HZ_MAX);
    assign clk_500hz = (cnt_500hz == CNT_500HZ_MAX);
    assign clk_4hz = (cnt_4hz == CNT_4HZ_MAX);
endmodule

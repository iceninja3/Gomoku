`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 12:37:59 PM
// Design Name: 
// Module Name: button_debouncer
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

module button_debouncer(input clk, in, output out_pulse);
    reg [21:0] count; reg stable, prev_stable;
    always @(posedge clk) begin
        if (in != stable) begin count <= count + 1; if (count == 250000) stable <= in; end
        else count <= 0;
        prev_stable <= stable;
    end
    assign out_pulse = stable & ~prev_stable;
endmodule

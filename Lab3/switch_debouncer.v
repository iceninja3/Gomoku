`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/03/2025 12:24:09 PM
// Design Name:
// Module Name: switch_debouncer
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

module switch_debouncer (
    input wire clk_100mhz,
    input wire rst,
    input wire sw_in,       // Raw switch signal
    output wire sw_out      // Synchronized switch level
    );

    reg [1:0] sw_shift_reg = 2'b00;

    always @(posedge clk_100mhz) begin
        if (rst) begin
            sw_shift_reg <= 2'b00;
        end
        else begin
            sw_shift_reg <= {sw_in, sw_shift_reg[1]};
        end
    end

    assign sw_out = sw_shift_reg[0];
endmodule

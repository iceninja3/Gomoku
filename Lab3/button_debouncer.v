`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/03/2025 12:24:09 PM
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

module button_debouncer (
    input wire clk_100mhz,
    input wire rst,
    input wire btn_in,      // Raw button signal
    output wire btn_out     // Clean, debounced button level
    );

    // 763Hz timing signal generation from basys3.v
    reg [16:0] clk_dv;
    reg        clk_en;

    always @ (posedge clk_100mhz) begin
        if (rst) begin
            clk_dv <= 0;
            clk_en <= 1'b0;
        end
        else begin
            // clk_dv rolls over at 2^17, setting clk_en high for one cycle
            clk_dv <= clk_dv + 1;
            clk_en <= (clk_dv == 17'd0);
        end
    end

    // Debounce Logic using step_d from basys3.v
    reg [1:0] sync;
    reg [2:0] step_d = 3'b000;
    reg       btn_debounced = 1'b0;

    always @(posedge clk_100mhz) begin
        if (rst) begin
            sync <= 2'b00;
            step_d <= 3'b000;
            btn_debounced <= 1'b0;
        end
        else begin
            // Synchronize asynchronous button input
            sync <= {sync[0], btn_in};

            // Only sample the synchronized input on the slow clock enable
            if (clk_en) begin
                step_d <= {sync[1], step_d[2:1]};
                if (step_d == 3'b110)
                    btn_debounced <= 1'b1;
                else if (step_d == 3'b001)
                    btn_debounced <= 1'b0;
            end
        end
    end

    assign btn_out = btn_debounced;
endmodule

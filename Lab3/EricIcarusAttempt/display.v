`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/03/2025 12:24:09 PM
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
    input wire clk_500hz, // Mux switching clock enable (faster)
    input wire clk_4hz,   // Blinking clock enable (>1Hz)
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
    reg       clk_500hz_d; // delayed sample for rising-edge detect
    always @(posedge clk_100mhz) begin
        if (rst) begin
            mux_sel <= 2'd0;
            clk_500hz_d <= 1'b0;
        end
        else begin
            // Rising-edge detect on the enable signal allows either pulse or level inputs
            clk_500hz_d <= clk_500hz;
            if (clk_500hz && !clk_500hz_d) begin
                mux_sel <= mux_sel + 1;
            end
        end
    end

    reg blink_on;
    reg clk_4hz_d; // delayed sample for rising-edge detect
    always @(posedge clk_100mhz) begin
        if (rst) begin
            blink_on <= 1'b1; // Start ON
            clk_4hz_d <= 1'b0;
        end
        else begin
            // Rising-edge detect on the enable signal allows either pulse or level inputs
            clk_4hz_d <= clk_4hz;
            if (clk_4hz && !clk_4hz_d) begin
                blink_on <= !blink_on;
            end
        end
    end

    wire [3:0] bcd_mux_data;
    assign bcd_mux_data = (mux_sel == 2'b00) ? bcd_min_tens :
                          (mux_sel == 2'b01) ? bcd_min_ones :
                          (mux_sel == 2'b10) ? bcd_sec_tens :
                          /* 2'b11 */          bcd_sec_ones;

    wire [6:0] segment_pattern;
    BCD_to_7Seg i_decoder(
        .bcd_in(bcd_mux_data),
        .seg_out(segment_pattern)
    );

    // Anode and Segment Output Logic
    always @(*) begin
        // Anode (Active-LOW: 0=ON, 1=OFF)
        case (mux_sel)
            2'b00: anode = 4'b0111; // Min Tens ON
            2'b01: anode = 4'b1011; // Min Ones ON
            2'b10: anode = 4'b1101; // Sec Tens ON
            2'b11: anode = 4'b1110; // Sec Ones ON
            default: anode = 4'b1111; // All OFF
        endcase

        // Default segment pattern is the decoded value
        segment = segment_pattern;

        // blinking logic
        if (is_adjust && !blink_on) begin
            if (!is_sel_sec && (mux_sel == 2'b00 || mux_sel == 2'b01)) begin
                segment = 7'b1111111;
            end
            else if (is_sel_sec && (mux_sel == 2'b10 || mux_sel == 2'b11)) begin
                segment = 7'b1111111;
            end
        end
    end
endmodule
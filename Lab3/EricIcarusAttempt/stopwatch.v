`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/03/2025 12:24:09 PM
// Design Name:
// Module Name: stopwatch
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Main stopwatch FSM, BCD counters, and control logic.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module stopwatch(
    input wire clk_100mhz,
    input wire rst,
    input wire clk_1hz,     // 1Hz tick for counting
    input wire clk_2hz,     // 2Hz tick for adjustment
    input wire button_pause,
    input wire switch_sel,  // 0=Minutes, 1=Seconds
    input wire switch_adj,

    output wire [3:0] bcd_min_tens,
    output wire [3:0] bcd_min_ones,
    output wire [3:0] bcd_sec_tens,
    output wire [3:0] bcd_sec_ones,

    output wire is_adj,
    output wire is_sel_sec,
    output wire [1:0] state_out
    );

    // States: S_PAUSED (00), S_COUNTING (01), S_ADJUST (10)
    localparam S_PAUSED   = 2'b00;
    localparam S_COUNTING = 2'b01;
    localparam S_ADJUST   = 2'b10; // Maps to the 2'b10 state seen in the testbench

    reg [1:0] state = S_PAUSED;

    // Time registers (initialized via reset)
    reg [3:0] sec_ones = 4'd0;
    reg [3:0] sec_tens = 4'd0;
    reg [3:0] min_ones = 4'd0;
    reg [3:0] min_tens = 4'd0;

    // Button Debouncer/Edge Detector logic for button_pause
    // We assume a debounced input, but implement a simple edge detector for state transition
    reg button_pause_d = 1'b0;
    wire button_pause_rise = button_pause && !button_pause_d;

    // FSM and BCD Counter Logic - All synchronous to clk_100mhz
    always @(posedge clk_100mhz) begin
        // Update delayed button_pause for edge detection
        button_pause_d <= button_pause;

        if (rst) begin
            // Reset state and BCD time to 00:00
            state <= S_PAUSED;
            sec_ones <= 4'd0;
            sec_tens <= 4'd0;
            min_ones <= 4'd0;
            min_tens <= 4'd0;
        end
        else begin
            // --- State Transition Logic (Next State Logic) ---
            case (state)
                S_PAUSED: begin
                    if (button_pause_rise) state <= S_COUNTING;
                    else if (switch_adj) state <= S_ADJUST;
                end
                S_COUNTING: begin
                    if (button_pause_rise) state <= S_PAUSED;
                    // No transition to ADJUST mode from COUNTING
                end
                S_ADJUST: begin
                    if (!switch_adj) state <= S_PAUSED; // Exit adjustment when switch is off
                end
                default: state <= S_PAUSED;
            endcase

            // --- Time Update Logic (Updates based on current state) ---
            case (state)
                S_COUNTING: begin
                    if (clk_1hz) begin
                        // 1Hz COUNTING (Sec 0-9, Sec Tens 0-5, Min Ones 0-9, Min Tens 0-5)
                        if (sec_ones == 4'd9) begin
                            sec_ones <= 4'd0;
                            if (sec_tens == 4'd5) begin
                                sec_tens <= 4'd0;
                                if (min_ones == 4'd9) begin
                                    min_ones <= 4'd0;
                                    if (min_tens == 4'd5) begin
                                        min_tens <= 4'd0; // Rolls over 59:59 to 00:00
                                    end
                                    else begin
                                        min_tens <= min_tens + 1;
                                    end
                                end
                                else begin
                                    min_ones <= min_ones + 1;
                                end
                            end
                            else begin
                                sec_tens <= sec_tens + 1;
                            end
                        end
                        else begin
                            sec_ones <= sec_ones + 1;
                        end
                    end
                end // end S_COUNTING

                S_ADJUST: begin
                    if (clk_2hz) begin
                        if (switch_sel) begin // switch_sel = 1 (Adjust Seconds)
                            if (sec_ones == 4'd9) begin
                                sec_ones <= 4'd0;
                                if (sec_tens == 4'd5) begin
                                    sec_tens <= 4'd0;
                                end
                                else begin
                                    sec_tens <= sec_tens + 1;
                                end
                            end
                            else begin
                                sec_ones <= sec_ones + 1;
                            end
                        end
                        else begin // switch_sel = 0 (Adjust Minutes)
                            if (min_ones == 4'd9) begin
                                min_ones <= 4'd0;
                                if (min_tens == 4'd5) begin
                                    min_tens <= 4'd0;
                                end
                                else begin
                                    min_tens <= min_tens + 1;
                                end
                            end
                            else begin
                                min_ones <= min_ones + 1;
                            end
                        end
                    end
                end // end S_ADJUST
            endcase
        end
    end

    // Output Assignments
    assign bcd_sec_ones = sec_ones;
    assign bcd_sec_tens = sec_tens;
    assign bcd_min_ones = min_ones;
    assign bcd_min_tens = min_tens;

    // Status/Control Outputs
    assign is_adj = (state == S_ADJUST);
    assign is_sel_sec = switch_sel;
    assign state_out = state;
endmodule

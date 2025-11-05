`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: stopwatch_top
// Description: Top-level module for the M152A Lab 3 Stopwatch.
//              Instantiates and connects all sub-modules:
//              - clock (clock divider)
//              - button_debouncer (for pause and reset)
//              - switch_debouncer (for adjust and select switches)
//              - stopwatch (main state machine and counters)
//              - display (7-segment display multiplexer and BCD driver)
//////////////////////////////////////////////////////////////////////////////////

module main(
    // --- Global Inputs ---
    input wire clk,         // 100MHz system clock
    input wire btnC,        // Center button (used for Reset)
    input wire btnU,        // Up button (used for Pause/Continue)
    input wire [1:0] sw,    // Switches (sw[0]=Adjust, sw[1]=Select)

    // --- Global Outputs ---
    output wire [6:0] segment, // 7-segment display segments (Active-LOW)
    output wire [3:0] anode,   // 7-segment display anodes (Active-LOW)
    output wire [0:0] led,     // LED[0] for debug (shows debounced pause)

    // --- Debug/Monitor Outputs for Testbench ---
    output wire [3:0] bcd_min_tens_out,
    output wire [3:0] bcd_min_ones_out,
    output wire [3:0] bcd_sec_tens_out,
    output wire [3:0] bcd_sec_ones_out,
    output wire [1:0] state_out,
    output wire       pause_btn_debounced_out
    );

    // --- Internal Wires ---

    // Reset signal (synchronously debounced)
    wire rst;

    // Clock enable pulses
    wire clk_1hz;
    wire clk_2hz;
    wire clk_4hz;
    wire clk_500hz;

    // Debounced button and switch signals (level)
    wire btn_pause_level;
    wire sw_adj_level;
    wire sw_sel_level;

    // BCD digits from stopwatch to display
    wire [3:0] bcd_min_tens;
    wire [3:0] bcd_min_ones;
    wire [3:0] bcd_sec_tens;
    wire [3:0] bcd_sec_ones;

    // Adjust/Select flags from stopwatch to display
    wire is_adj_wire;
    wire is_sel_sec_wire;
    wire [1:0] state_wire;

    // --- 1. Clock Divider ---
    // Generates all the clock enable pulses needed by other modules.
    clock i_clock (
        .clk_100mhz(clk),
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .clk_500hz(clk_500hz),
        .clk_4hz(clk_4hz)
    );

    // --- 2. Input Conditioning (Debouncers and Synchronizers) ---
`ifdef SIMULATION
    // In simulation, bypass slow debouncers to recognize short testbench pulses
    assign rst = btnC;
    assign btn_pause_level = btnU;
    assign sw_adj_level = sw[0];
    assign sw_sel_level = sw[1];
`else
    // Debounce the Reset button (btnC)
    button_debouncer i_rst_debouncer (
        .clk_100mhz(clk),
        .rst(1'b0), // Debouncer's own reset is tied low
        .btn_in(btnC),
        .btn_out(rst) // This is the clean, high-active synchronous reset
    );

    // Debounce the Pause button (btnU)
    button_debouncer i_pause_debouncer (
        .clk_100mhz(clk),
        .rst(rst),
        .btn_in(btnU),
        .btn_out(btn_pause_level)
    );

    // Synchronize the Adjust switch (sw[0])
    // (Using 'switch_debouncer' which is a 2-FF synchronizer)
    switch_debouncer i_adj_sync (
        .clk_100mhz(clk),
        .rst(rst),
        .sw_in(sw[0]),
        .sw_out(sw_adj_level)
    );

    // Synchronize the Select switch (sw[1])
    switch_debouncer i_sel_sync (
        .clk_100mhz(clk),
        .rst(rst),
        .sw_in(sw[1]),
        .sw_out(sw_sel_level)
    );
`endif

    // --- 3. Stopwatch Core Logic ---
    // Main state machine.
    stopwatch i_stopwatch (
        .clk_100mhz(clk),
        .rst(rst),
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .button_pause(btn_pause_level), // Input the debounced LEVEL
        .switch_sel(sw_sel_level),
        .switch_adj(sw_adj_level),

        .bcd_min_tens(bcd_min_tens),
        .bcd_min_ones(bcd_min_ones),
        .bcd_sec_tens(bcd_sec_tens),
        .bcd_sec_ones(bcd_sec_ones),
        .is_adj(is_adj_wire),
        .is_sel_sec(is_sel_sec_wire),
        .state_out(state_wire)
    );

    // --- 4. Display Driver ---
    // MUX and BCD-to-7-Seg (which is instantiated inside this module).
    display i_display (
        .clk_100mhz(clk),
        .rst(rst),
        .clk_500hz(clk_500hz),
        .clk_4hz(clk_4hz),
        .bcd_min_tens(bcd_min_tens),
        .bcd_min_ones(bcd_min_ones),
        .bcd_sec_tens(bcd_sec_tens),
        .bcd_sec_ones(bcd_sec_ones),
        .is_adjust(is_adj_wire),
        .is_sel_sec(is_sel_sec_wire),

        .segment(segment),
        .anode(anode)
    );

    // --- 5. Debug Output ---
    // Assign the debounced pause signal to LED[0]
    assign led[0] = btn_pause_level;

    // Drive testbench monitor outputs
    assign bcd_min_tens_out = bcd_min_tens;
    assign bcd_min_ones_out = bcd_min_ones;
    assign bcd_sec_tens_out = bcd_sec_tens;
    assign bcd_sec_ones_out = bcd_sec_ones;
    assign state_out = state_wire;
    assign pause_btn_debounced_out = btn_pause_level;

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2025 12:35:10 PM
// Design Name: 
// Module Name: Top
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


module Top(
    input wire clk,         // 100MHz system clock, V11
    input wire btnL,        // RESET, BTNL (W19)
    input wire btnR,        // PAUSE, BTNR (T17)
    input wire [1:0] sw,    // Switches (sw[0]=Adjust, sw[1]=Select)

    output wire [6:0] seg, // 7-segment display segments
    output wire [3:0] an   // 7-segment display anodes
    );
    
    // Reset signal (synchronously debounced)
    wire rst;

    // Clock enable pulses
    wire clk_1hz;
    wire clk_2hz;
    wire clk_blink;
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

    // Clock module
    clock i_clock (
        .clk_100mhz(clk),
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .clk_500hz(clk_500hz),
        .clk_blink(clk_blink)
    );
    
    // Reset debouncer
    button_debouncer i_rst_debouncer (
        .clk_100mhz(clk),
        .rst(1'b0),
        .btn_in(btnL),
        .btn_out(rst)
    );
    
    // Pause debouncer
    button_debouncer i_pause_debouncer (
        .clk_100mhz(clk),
        .rst(1'b0),
        .btn_in(btnR),
        .btn_out(btn_pause_level)
    );
    
    // Adjust switch debouncer
    switch_debouncer i_adj_sync (
        .clk_100mhz(clk),
        .rst(rst),
        .sw_in(sw[0]),
        .sw_out(sw_adj_level)
    );
    
    // Select switch debouncer
    switch_debouncer i_sel_sync (
        .clk_100mhz(clk),
        .rst(rst),
        .sw_in(sw[1]),
        .sw_out(sw_sel_level)
    );
    
    // Stopwatch FSM
    stopwatch i_stopwatch (
        .clk_100mhz(clk),
        .rst(rst),
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .button_pause(btn_pause_level),
        .switch_sel(sw_sel_level),
        .switch_adj(sw_adj_level),

        .bcd_min_tens(bcd_min_tens),
        .bcd_min_ones(bcd_min_ones),
        .bcd_sec_tens(bcd_sec_tens),
        .bcd_sec_ones(bcd_sec_ones),
        .is_adj(is_adj_wire),
        .is_sel_sec(is_sel_sec_wire)
    );
    
    display i_display (
        .clk_100mhz(clk),
        .rst(rst),
        .clk_500hz(clk_500hz),
        .clk_blink(clk_blink),
        .bcd_min_tens(bcd_min_tens),
        .bcd_min_ones(bcd_min_ones),
        .bcd_sec_tens(bcd_sec_tens),
        .bcd_sec_ones(bcd_sec_ones),
        .is_adjust(is_adj_wire),
        .is_sel_sec(is_sel_sec_wire),

        .segment(seg),
        .anode(an)
    );
endmodule

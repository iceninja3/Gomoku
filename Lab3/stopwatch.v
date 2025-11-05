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
// Description: 
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
    input wire clk_1hz,
    input wire clk_2hz,
    input wire button_pause,
    input wire switch_sel,
    input wire switch_adj,
    
    output wire [3:0] bcd_min_tens,
    output wire [3:0] bcd_min_ones,
    output wire [3:0] bcd_sec_tens,
    output wire [3:0] bcd_sec_ones,
    
    output wire is_adj,
    output wire is_sel_sec
    );
    localparam S_PAUSED = 2'b00;
    localparam S_COUNTING = 2'b01;
    localparam S_ADJUST_PAUSED = 2'b10;
    localparam S_ADJUST_COUNTING = 2'b11;
    
    reg [1:0] state;
    reg pause_d;
    reg [3:0] sec_ones;
    reg [3:0] sec_tens;
    reg [3:0] min_ones;
    reg [3:0] min_tens;
    
    wire pause_pressed = button_pause & ~pause_d;
    
    always @(posedge clk_100mhz) begin
        pause_d <= button_pause;
        if (rst) begin
            state <= S_COUNTING;
            sec_ones <= 4'd0;
            sec_tens <= 4'd0;
            min_ones <= 4'd0;
            min_tens <= 4'd0;
        end
        else begin
            case (state)
                S_PAUSED: begin
                    if (pause_pressed) begin
                        state <= S_COUNTING;
                    end
                    else if (switch_adj) begin
                        state <= S_ADJUST_PAUSED;
                    end
                end
                
                S_COUNTING: begin
                    if (pause_pressed) begin
                        state <= S_PAUSED;
                    end
                    else if (switch_adj) begin
                        state <= S_ADJUST_COUNTING;
                    end
                    else if (clk_1hz) begin
                        if (sec_ones == 4'd9) begin
                            sec_ones <= 4'd0;
                            if (sec_tens == 4'd5) begin
                                sec_tens <= 4'd0;
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
                            else begin
                                sec_tens <= sec_tens + 1;
                            end
                        end
                        else begin
                            sec_ones <= sec_ones + 1;
                        end
                    end
                end
                
                S_ADJUST_PAUSED, S_ADJUST_COUNTING: begin
                    if (!switch_adj) begin
                        state <= (state == S_ADJUST_PAUSED) ? S_PAUSED : S_COUNTING;
                    end
                    else if (clk_2hz) begin
                        if (switch_sel) begin
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
                        else begin
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
                end
            endcase
        end
    end
    
    assign bcd_sec_ones = sec_ones;
    assign bcd_sec_tens = sec_tens;
    assign bcd_min_ones = min_ones;
    assign bcd_min_tens = min_tens;
    
    assign is_adj = (state == S_ADJUST_PAUSED || state == S_ADJUST_COUNTING);
    assign is_sel_sec = switch_sel;
endmodule

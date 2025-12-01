`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 12:37:59 PM
// Design Name: 
// Module Name: game_logic
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

import states::*;

module game_logic(
    input wire clk, rst,
    input wire pulse_u, pulse_d, pulse_l, pulse_r, pulse_s,
    output reg [1:0] grid [14:0][14:0],
    output reg [3:0] cursor_x, cursor_y,
    output reg player_turn,
    output reg [1:0] winner,
    output reg [7:0] score_p1, score_p2,
    output state_t state,
    output reg [1:0] p1_shape, p2_shape,
    output wire [1:0] temp_shape_out 
    );

    localparam GRID_SIZE = 15;
    integer r, c;
    reg [1:0] check_val;

    reg [1:0] temp_shape; 
    assign temp_shape_out = temp_shape;

    always @(posedge clk) begin
        if (rst) begin
            // Full Reset
            for(r=0; r<GRID_SIZE; r++) for(c=0; c<GRID_SIZE; c++) grid[r][c] <= 0;
            cursor_x <= 7; cursor_y <= 7;
            player_turn <= 0; winner <= 0;
            score_p1 <= 0; score_p2 <= 0;
            
            state <= S_SELECT_P1;
            temp_shape <= 0; 
            p1_shape <= 0; p2_shape <= 0;
        end else begin
            
            case (state)
                // --- STATE: P1 AVATAR ---
                S_SELECT_P1: begin
                    if (pulse_l) temp_shape <= temp_shape - 1;
                    if (pulse_r) temp_shape <= temp_shape + 1;
                    if (pulse_s) begin
                        p1_shape <= temp_shape;
                        temp_shape <= 0; 
                        state <= S_SELECT_P2;
                    end
                end

                // --- STATE: P2 AVATAR ---
                S_SELECT_P2: begin
                    if (pulse_l) temp_shape <= temp_shape - 1;
                    if (pulse_r) temp_shape <= temp_shape + 1;
                    if (pulse_s) begin
                        p2_shape <= temp_shape;
                        state <= S_PLAY; 
                    end
                end

                // --- STATE: MAIN GAME ---
                S_PLAY: begin
                    // Movement
                    if (pulse_l) cursor_x <= (cursor_x == 0) ? GRID_SIZE-1 : cursor_x - 1;
                    if (pulse_r) cursor_x <= (cursor_x == GRID_SIZE-1) ? 0 : cursor_x + 1;
                    if (pulse_u) cursor_y <= (cursor_y == 0) ? GRID_SIZE-1 : cursor_y - 1;
                    if (pulse_d) cursor_y <= (cursor_y == GRID_SIZE-1) ? 0 : cursor_y + 1;

                    // Place Piece
                    if (pulse_s) begin
                        if (grid[cursor_y][cursor_x] == 0) begin
                            grid[cursor_y][cursor_x] <= (player_turn == 0) ? 2'b01 : 2'b10;
                            player_turn <= ~player_turn;
                        end
                    end
                    
                    // Win Check
                    // Horizontal
                    for (r=0; r<GRID_SIZE; r++) begin
                        for (c=0; c<=GRID_SIZE-5; c++) begin
                            check_val = grid[r][c];
                            if (check_val != 0 &&
                                grid[r][c+1] == check_val && grid[r][c+2] == check_val &&
                                grid[r][c+3] == check_val && grid[r][c+4] == check_val) begin
                                    winner <= check_val;
                                    state <= S_WIN;
                                    if (check_val == 1) score_p1 <= score_p1 + 1;
                                    else score_p2 <= score_p2 + 1;
                            end
                        end
                    end
                    // Vertical
                    for (c=0; c<GRID_SIZE; c++) begin
                        for (r=0; r<=GRID_SIZE-5; r++) begin
                            check_val = grid[r][c];
                            if (check_val != 0 &&
                                grid[r+1][c] == check_val && grid[r+2][c] == check_val &&
                                grid[r+3][c] == check_val && grid[r+4][c] == check_val) begin
                                    winner <= check_val;
                                    state <= S_WIN;
                                    if (check_val == 1) score_p1 <= score_p1 + 1;
                                    else score_p2 <= score_p2 + 1;
                            end
                        end
                    end
                    // Diag 1
                    for (r=0; r<=GRID_SIZE-5; r++) begin
                        for (c=0; c<=GRID_SIZE-5; c++) begin
                            check_val = grid[r][c];
                            if (check_val != 0 &&
                                grid[r+1][c+1] == check_val && grid[r+2][c+2] == check_val &&
                                grid[r+3][c+3] == check_val && grid[r+4][c+4] == check_val) begin
                                    winner <= check_val;
                                    state <= S_WIN;
                                    if (check_val == 1) score_p1 <= score_p1 + 1;
                                    else score_p2 <= score_p2 + 1;
                            end
                        end
                    end
                    // Diag 2
                    for (r=4; r<GRID_SIZE; r++) begin
                        for (c=0; c<=GRID_SIZE-5; c++) begin
                            check_val = grid[r][c];
                            if (check_val != 0 &&
                                grid[r-1][c+1] == check_val && grid[r-2][c+2] == check_val &&
                                grid[r-3][c+3] == check_val && grid[r-4][c+4] == check_val) begin
                                    winner <= check_val;
                                    state <= S_WIN;
                                    if (check_val == 1) score_p1 <= score_p1 + 1;
                                    else score_p2 <= score_p2 + 1;
                            end
                        end
                    end
                end

                // --- STATE: WIN SCREEN ---
                S_WIN: begin
                    if (pulse_s) begin
                        // Rematch
                        // Clear board
                        for(r=0; r<GRID_SIZE; r++) for(c=0; c<GRID_SIZE; c++) grid[r][c] <= 0;
                        winner <= 0;
                        player_turn <= 0;
                        
                        // Reset cursor to center
                        cursor_x <= 7;
                        cursor_y <= 7;
                        
                        state <= S_PLAY;
                    end
                end
            endcase
        end
    end
endmodule

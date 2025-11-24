`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Shared Types
// -----------------------------------------------------------------------------
package gomoku_types;
    typedef logic [1:0] grid_t [14:0][14:0];
    
    typedef enum logic [1:0] {
        S_SELECT_P1 = 0, // Player 1 choosing avatar
        S_SELECT_P2 = 1, // Player 2 choosing avatar
        S_PLAY      = 2, // Main Game
        S_WIN       = 3  // Game Over
    } state_t;
endpackage

import gomoku_types::*;

// -----------------------------------------------------------------------------
// Top Level
// -----------------------------------------------------------------------------
module gomoku_top(
    input wire clk,
    input wire [15:0] sw, // sw[0] = RESET
    input wire btnU, btnD, btnL, btnR, btnS,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue,
    output wire Hsync, Vsync,
    output wire [6:0] seg, 
    output wire [3:0] an, 
    output wire dp
    );

    wire rst = sw[0];

    // 1. Clock (25MHz)
    reg [1:0] clk_div;
    always @(posedge clk) clk_div <= clk_div + 1;
    wire clk_25MHz = clk_div[1];

    // 2. Inputs
    wire pulse_u, pulse_d, pulse_l, pulse_r, pulse_s;
    debounce db_u (.clk(clk_25MHz), .in(btnU), .out_pulse(pulse_u));
    debounce db_d (.clk(clk_25MHz), .in(btnD), .out_pulse(pulse_d));
    debounce db_l (.clk(clk_25MHz), .in(btnL), .out_pulse(pulse_l));
    debounce db_r (.clk(clk_25MHz), .in(btnR), .out_pulse(pulse_r));
    debounce db_s (.clk(clk_25MHz), .in(btnS), .out_pulse(pulse_s));

    // 3. Game Signals
    grid_t grid;
    wire [3:0] cursor_x, cursor_y;
    wire player_turn;
    wire [1:0] winner;
    wire [7:0] score_p1, score_p2;
    state_t state;
    wire [1:0] p1_shape, p2_shape;
    wire [1:0] active_selection; 

    // 4. Logic Module
    gomoku_logic engine (
        .clk(clk_25MHz), .rst(rst),
        .pulse_u(pulse_u), .pulse_d(pulse_d), 
        .pulse_l(pulse_l), .pulse_r(pulse_r), .pulse_s(pulse_s),
        .grid(grid),
        .cursor_x(cursor_x), .cursor_y(cursor_y),
        .player_turn(player_turn),
        .winner(winner),
        .score_p1(score_p1), .score_p2(score_p2),
        .state(state),
        .p1_shape(p1_shape), .p2_shape(p2_shape),
        .temp_shape_out(active_selection)
    );

    // 5. Graphics Module
    wire [9:0] pixel_x, pixel_y;
    wire video_on;
    vga_sync vga_driver (
        .clk(clk_25MHz), .rst(rst),
        .hsync(Hsync), .vsync(Vsync),
        .video_on(video_on),
        .x(pixel_x), .y(pixel_y)
    );

    gomoku_graphics renderer (
        .pixel_x(pixel_x), .pixel_y(pixel_y),
        .video_on(video_on),
        .grid(grid),
        .cursor_x(cursor_x), .cursor_y(cursor_y),
        .player_turn(player_turn),
        .state(state),
        .p1_shape(p1_shape), .p2_shape(p2_shape),
        .preview_shape(active_selection), 
        .red_out(vgaRed), .green_out(vgaGreen), .blue_out(vgaBlue)
    );

    // 6. Score Display
    seg7_control scoreboard (
        .clk(clk), .rst(rst),
        .num_p1(score_p1), .num_p2(score_p2),
        .seg(seg), .an(an), .dp(dp)
    );

endmodule


// -----------------------------------------------------------------------------
// Game Logic Module
// -----------------------------------------------------------------------------
module gomoku_logic(
    input wire clk, rst,
    input wire pulse_u, pulse_d, pulse_l, pulse_r, pulse_s,
    output grid_t grid,
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
                        // Rematch: Clear Board, Keep Scores, Keep Avatars, Go to Play
                        for(r=0; r<GRID_SIZE; r++) for(c=0; c<GRID_SIZE; c++) grid[r][c] <= 0;
                        winner <= 0;
                        player_turn <= 0;
                        
                        // *** FIX: RESET CURSOR TO CENTER ***
                        cursor_x <= 7;
                        cursor_y <= 7;
                        
                        state <= S_PLAY;
                    end
                end
            endcase
        end
    end
endmodule


// -----------------------------------------------------------------------------
// Graphics Module
// -----------------------------------------------------------------------------
module gomoku_graphics(
    input wire [9:0] pixel_x, pixel_y,
    input wire video_on,
    input grid_t grid,
    input wire [3:0] cursor_x, cursor_y,
    input wire player_turn,
    input state_t state,
    input wire [1:0] p1_shape, p2_shape,
    input wire [1:0] preview_shape, 
    output wire [3:0] red_out, green_out, blue_out
    );

    localparam CELL_SIZE = 30;
    localparam BOARD_OFF_X = 95; 
    localparam BOARD_OFF_Y = 30; 
    localparam BOARD_W = 15 * CELL_SIZE;
    localparam BOARD_H = 15 * CELL_SIZE;

    wire [9:0] rel_x = pixel_x - BOARD_OFF_X;
    wire [9:0] rel_y = pixel_y - BOARD_OFF_Y;
    wire [3:0] cell_x = rel_x / CELL_SIZE; 
    wire [3:0] cell_y = rel_y / CELL_SIZE;
    wire [9:0] ix = rel_x % CELL_SIZE; 
    wire [9:0] iy = rel_y % CELL_SIZE; 
    
    wire on_board = (pixel_x >= BOARD_OFF_X) && (pixel_x < BOARD_OFF_X + BOARD_W) &&
                    (pixel_y >= BOARD_OFF_Y) && (pixel_y < BOARD_OFF_Y + BOARD_H);

    // Center Screen Math
    wire [9:0] cx = 320;
    wire [9:0] cy = 240;
    wire [9:0] menu_dx = (pixel_x > cx) ? pixel_x - cx : cx - pixel_x;
    wire [9:0] menu_dy = (pixel_y > cy) ? pixel_y - cy : cy - pixel_y;

    // INTEGER MATH FUNCTION (Prevents overflow/ripples)
    function logic is_pixel_in_shape(input [1:0] shape, input [9:0] dx, input [9:0] dy, input [9:0] radius);
        integer d2, r2; 
        begin
            d2 = dx*dx + dy*dy; 
            r2 = radius*radius; 
            
            case (shape)
                0: is_pixel_in_shape = (d2 < r2); // Circle
                1: is_pixel_in_shape = (dx < radius && dy < radius);    // Square
                2: is_pixel_in_shape = (dx + dy < radius);              // Diamond
                3: is_pixel_in_shape = ((dx < radius/3 && dy < radius) || (dx < radius && dy < radius/3)); // Plus
                default: is_pixel_in_shape = 0;
            endcase
        end
    endfunction

    wire [9:0] cell_dx = (ix > 15) ? ix - 15 : 15 - ix;
    wire [9:0] cell_dy = (iy > 15) ? iy - 15 : 15 - iy;
    
    wire [1:0] menu_current_shape = preview_shape; 

    reg [3:0] r, g, b;
    always @* begin
        r=0; g=0; b=0;
        if (video_on) begin
            
            // --- MENU SCREENS ---
            if (state == S_SELECT_P1 || state == S_SELECT_P2) begin
                if (state == S_SELECT_P1) r = 2; 
                else b = 2;                      

                if (is_pixel_in_shape(menu_current_shape, menu_dx, menu_dy, 60)) begin
                    if (state == S_SELECT_P1) r=15; else b=15;
                end
            end

            // --- GAMEPLAY SCREEN ---
            else begin
                if (pixel_y < BOARD_OFF_Y) begin
                    if (state == S_WIN) begin r=8; b=8; end 
                    else if (player_turn == 0) r=15;        
                    else b=15;                              
                end
                else if (on_board) begin
                    if (ix == 0 || ix == 29 || iy == 0 || iy == 29) begin
                        r=8; g=8; b=8; 
                    end 
                    else if (state == S_PLAY && cell_x == cursor_x && cell_y == cursor_y) begin
                        g = 4; 
                        if (ix < 3 || ix > 26 || iy < 3 || iy > 26) g=15;
                    end
                    
                    if (grid[cell_y][cell_x] == 1) begin
                        if (is_pixel_in_shape(p1_shape, cell_dx, cell_dy, 10)) r=15;
                    end 
                    else if (grid[cell_y][cell_x] == 2) begin
                        if (is_pixel_in_shape(p2_shape, cell_dx, cell_dy, 10)) b=15;
                    end
                end
            end
        end
    end
    
    assign red_out = r;
    assign green_out = g;
    assign blue_out = b;

endmodule

// -----------------------------------------------------------------------------
// Scoreboard & Helpers
// -----------------------------------------------------------------------------
module seg7_control(input clk, rst, input [7:0] num_p1, num_p2, output reg [6:0] seg, output reg [3:0] an, output wire dp);
    assign dp = 1; 
    reg [19:0] refresh_counter;
    always @(posedge clk) begin
        if(rst) refresh_counter <= 0; else refresh_counter <= refresh_counter + 1;
    end
    wire [1:0] digit_select = refresh_counter[19:18];
    reg [3:0] hex_digit;
    always @* begin
        case(digit_select)
            2'b00: begin an = 4'b1110; hex_digit = num_p2[3:0]; end
            2'b01: begin an = 4'b1101; hex_digit = num_p2[7:4]; end
            2'b10: begin an = 4'b1011; hex_digit = num_p1[3:0]; end
            2'b11: begin an = 4'b0111; hex_digit = num_p1[7:4]; end
        endcase
    end
    always @* begin
        case(hex_digit)
            4'h0: seg = 7'b1000000; 4'h1: seg = 7'b1111001; 4'h2: seg = 7'b0100100; 4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001; 4'h5: seg = 7'b0010010; 4'h6: seg = 7'b0000010; 4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000; 4'h9: seg = 7'b0010000; 4'hA: seg = 7'b0001000; 4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110; 4'hD: seg = 7'b0100001; 4'hE: seg = 7'b0000110; 4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule

module vga_sync(input clk, rst, output hsync, vsync, video_on, output [9:0] x, y);
    // Timing Fix Applied: HF=16, HB=48 to shift image right (center it)
    localparam HD=640, HF=16, HB=48, HR=96, VD=480, VF=10, VB=33, VR=2;
    reg [9:0] h_count, v_count;
    always @(posedge clk) begin
        if (rst) begin h_count<=0; v_count<=0; end
        else if (h_count == 799) begin
            h_count<=0;
            if (v_count == 524) v_count<=0; else v_count<=v_count+1;
        end else h_count<=h_count+1;
    end
    assign hsync = ~(h_count >= (HD+HF) && h_count < (HD+HF+HR));
    assign vsync = ~(v_count >= (VD+VF) && v_count < (VD+VF+VR));
    assign video_on = (h_count < HD) && (v_count < VD);
    assign x = h_count; assign y = v_count;
endmodule

module debounce(input clk, in, output out_pulse);
    reg [21:0] count; reg stable, prev_stable;
    always @(posedge clk) begin
        if (in != stable) begin count <= count + 1; if (count == 250000) stable <= in; end
        else count <= 0;
        prev_stable <= stable;
    end
    assign out_pulse = stable & ~prev_stable;
endmodule
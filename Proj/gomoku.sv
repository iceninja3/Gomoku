`timescale 1ns / 1ps

module gomoku_top(
    input wire clk,             // 100MHz Clock
    input wire [15:0] sw,       // sw[0] is Reset
    input wire btnU, btnD, btnL, btnR, btnS,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue,
    output wire Hsync, Vsync
    );

    wire rst = sw[0];

    // -------------------------------------------------------------------------
    // 1. Clock Generation (25MHz)
    // -------------------------------------------------------------------------
    reg [1:0] clk_div;
    wire clk_25MHz;
    always @(posedge clk) clk_div <= clk_div + 1;
    assign clk_25MHz = clk_div[1];

    // -------------------------------------------------------------------------
    // 2. Inputs
    // -------------------------------------------------------------------------
    wire pulse_u, pulse_d, pulse_l, pulse_r, pulse_s;
    debounce db_u (.clk(clk_25MHz), .in(btnU), .out_pulse(pulse_u));
    debounce db_d (.clk(clk_25MHz), .in(btnD), .out_pulse(pulse_d));
    debounce db_l (.clk(clk_25MHz), .in(btnL), .out_pulse(pulse_l));
    debounce db_r (.clk(clk_25MHz), .in(btnR), .out_pulse(pulse_r));
    debounce db_s (.clk(clk_25MHz), .in(btnS), .out_pulse(pulse_s));

    // -------------------------------------------------------------------------
    // 3. Game Logic
    // -------------------------------------------------------------------------
    localparam GRID_SIZE = 15;
    
    reg [1:0] grid [GRID_SIZE-1:0][GRID_SIZE-1:0]; // 15x15 Grid
    reg [3:0] cursor_x; // 0 to 14 (Needs 4 bits)
    reg [3:0] cursor_y; // 0 to 14
    reg player_turn;    // 0=P1, 1=P2
    reg [1:0] winner;   
    reg game_over;

    // Variables for Win Check Loop
    integer r, c, k;
    reg [1:0] check_val;
    reg match;

    always @(posedge clk_25MHz) begin
        if (rst) begin
            for(r=0; r<GRID_SIZE; r=r+1) 
                for(c=0; c<GRID_SIZE; c=c+1) 
                    grid[r][c] <= 0;
            cursor_x <= 7; // Start in center
            cursor_y <= 7;
            player_turn <= 0;
            winner <= 0;
            game_over <= 0;
        end else begin
            
            // --- Movement ---
            if (!game_over) begin
                if (pulse_l) cursor_x <= (cursor_x == 0) ? GRID_SIZE-1 : cursor_x - 1;
                if (pulse_r) cursor_x <= (cursor_x == GRID_SIZE-1) ? 0 : cursor_x + 1;
                if (pulse_u) cursor_y <= (cursor_y == 0) ? GRID_SIZE-1 : cursor_y - 1;
                if (pulse_d) cursor_y <= (cursor_y == GRID_SIZE-1) ? 0 : cursor_y + 1;

                // --- Selection ---
                if (pulse_s) begin
                    if (grid[cursor_y][cursor_x] == 0) begin
                        grid[cursor_y][cursor_x] <= (player_turn == 0) ? 2'b01 : 2'b10;
                        player_turn <= ~player_turn;
                    end
                end
            end else begin
                // Restart
                if (pulse_s) begin
                    for(r=0; r<GRID_SIZE; r=r+1) for(c=0; c<GRID_SIZE; c=c+1) grid[r][c] <= 0;
                    game_over <= 0; winner <= 0; player_turn <= 0;
                end
            end

            // --- Massive 5-in-a-row Check ---
            // We run this every clock cycle. 
            if (!game_over) begin
                // Default: No winner found yet this cycle
                
                // Note: We only check for the CURRENT player's previous move usually,
                // but here we brute force scan everything.
                
                // Horizontal Check
                for (r=0; r<GRID_SIZE; r=r+1) begin
                    for (c=0; c<=GRID_SIZE-5; c=c+1) begin
                        check_val = grid[r][c];
                        if (check_val != 0 &&
                            grid[r][c+1] == check_val &&
                            grid[r][c+2] == check_val &&
                            grid[r][c+3] == check_val &&
                            grid[r][c+4] == check_val) begin
                                winner <= check_val;
                                game_over <= 1;
                        end
                    end
                end

                // Vertical Check
                for (c=0; c<GRID_SIZE; c=c+1) begin
                    for (r=0; r<=GRID_SIZE-5; r=r+1) begin
                        check_val = grid[r][c];
                        if (check_val != 0 &&
                            grid[r+1][c] == check_val &&
                            grid[r+2][c] == check_val &&
                            grid[r+3][c] == check_val &&
                            grid[r+4][c] == check_val) begin
                                winner <= check_val;
                                game_over <= 1;
                        end
                    end
                end

                // Diagonal (Top-Left to Bottom-Right)
                for (r=0; r<=GRID_SIZE-5; r=r+1) begin
                    for (c=0; c<=GRID_SIZE-5; c=c+1) begin
                        check_val = grid[r][c];
                        if (check_val != 0 &&
                            grid[r+1][c+1] == check_val &&
                            grid[r+2][c+2] == check_val &&
                            grid[r+3][c+3] == check_val &&
                            grid[r+4][c+4] == check_val) begin
                                winner <= check_val;
                                game_over <= 1;
                        end
                    end
                end

                // Diagonal (Bottom-Left to Top-Right)
                for (r=4; r<GRID_SIZE; r=r+1) begin
                    for (c=0; c<=GRID_SIZE-5; c=c+1) begin
                        check_val = grid[r][c];
                        if (check_val != 0 &&
                            grid[r-1][c+1] == check_val &&
                            grid[r-2][c+2] == check_val &&
                            grid[r-3][c+3] == check_val &&
                            grid[r-4][c+4] == check_val) begin
                                winner <= check_val;
                                game_over <= 1;
                        end
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // 4. Graphics
    // -------------------------------------------------------------------------
    wire [9:0] x, y;
    wire video_on;
    vga_sync vga (.clk(clk_25MHz), .rst(rst), .hsync(Hsync), .vsync(Vsync), 
                  .video_on(video_on), .x(x), .y(y));

    // Screen Constants
    localparam CELL_SIZE = 30;
    localparam BOARD_OFFSET_X = 95; // Center horizontally: (640 - 15*30)/2
    localparam BOARD_OFFSET_Y = 30; // Space for top bar
    localparam BOARD_W = GRID_SIZE * CELL_SIZE;
    localparam BOARD_H = GRID_SIZE * CELL_SIZE;

    // Calculate Grid Coordinate from Pixel Coordinate
    // Note: Division is expensive, but at 25MHz it usually passes timing.
    wire [9:0] rel_x = x - BOARD_OFFSET_X;
    wire [9:0] rel_y = y - BOARD_OFFSET_Y;
    
    // Which cell are we in?
    wire [3:0] cell_x = rel_x / CELL_SIZE; 
    wire [3:0] cell_y = rel_y / CELL_SIZE;
    
    // Where are we inside that cell?
    wire [9:0] in_cell_x = rel_x % CELL_SIZE;
    wire [9:0] in_cell_y = rel_y % CELL_SIZE;

    // Are we effectively inside the board area?
    wire on_board = (x >= BOARD_OFFSET_X) && (x < BOARD_OFFSET_X + BOARD_W) &&
                    (y >= BOARD_OFFSET_Y) && (y < BOARD_OFFSET_Y + BOARD_H);

    reg [3:0] red, green, blue;
    always @* begin
        red=0; green=0; blue=0;
        if (video_on) begin
            
            // 1. Status Bar (Top 30 pixels)
            if (y < BOARD_OFFSET_Y) begin
                if (game_over) begin red=8; blue=8; green=0; end // Purple
                else if (player_turn == 0) red=15;        // Red Turn
                else blue=15;                              // Blue Turn
            end
            
            else if (on_board) begin
                // 2. Grid Lines (Dark Gray background, White lines)
                // Draw lines at edges of cells
                if (in_cell_x == 0 || in_cell_x == CELL_SIZE-1 || 
                    in_cell_y == 0 || in_cell_y == CELL_SIZE-1) begin
                    red=8; green=8; blue=8; // Gray Grid Lines
                end 
                
                // 3. Cursor Highlight (Green Box)
                else if (!game_over && cell_x == cursor_x && cell_y == cursor_y) begin
                    green = 4; // Dim green background for cursor
                    // Bright green border for cursor
                    if (in_cell_x < 3 || in_cell_x > CELL_SIZE-3 || 
                        in_cell_y < 3 || in_cell_y > CELL_SIZE-3) green=15;
                end

                // 4. Pieces
                if (grid[cell_y][cell_x] == 1) begin
                    // Player 1: Red Circle (approximate)
                    // Distance squared calculation for circle: (x-c)^2 + (y-c)^2 < r^2
                    // Center is 15,15. Radius is approx 10.
                    // (in_cell_x - 15)^2 + (in_cell_y - 15)^2 < 100
                    if ( (in_cell_x - 15)*(in_cell_x - 15) + 
                         (in_cell_y - 15)*(in_cell_y - 15) < 100 ) red=15;
                end 
                else if (grid[cell_y][cell_x] == 2) begin
                    // Player 2: Blue Circle
                    if ( (in_cell_x - 15)*(in_cell_x - 15) + 
                         (in_cell_y - 15)*(in_cell_y - 15) < 100 ) blue=15;
                end
            end
        end
    end
    
    assign vgaRed=red; assign vgaGreen=green; assign vgaBlue=blue;
endmodule

// --- Standard Helper Modules (Unchanged) ---

module vga_sync(input clk, rst, output hsync, vsync, video_on, output [9:0] x, y);
    localparam HD=640, HF=48, HB=16, HR=96, VD=480, VF=10, VB=33, VR=2;
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
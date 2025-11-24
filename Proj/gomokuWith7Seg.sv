`timescale 1ns / 1ps

module gomoku_top(
    input wire clk,             // 100MHz Clock
    input wire [15:0] sw,       // sw[0] is Reset
    input wire btnU, btnD, btnL, btnR, btnS,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue,
    output wire Hsync, Vsync,
    // New 7-Segment Outputs
    output wire [6:0] seg,      // Segments A-G
    output wire [3:0] an,       // Anodes
    output wire dp              // Decimal Point
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
    // 3. Game Logic & Score Keeping
    // -------------------------------------------------------------------------
    localparam GRID_SIZE = 15;
    
    reg [1:0] grid [GRID_SIZE-1:0][GRID_SIZE-1:0]; 
    reg [3:0] cursor_x; 
    reg [3:0] cursor_y; 
    reg player_turn;    
    reg [1:0] winner;   
    reg game_over;

    // --- SCORE REGISTERS ---
    reg [7:0] score_p1; // Max score 255
    reg [7:0] score_p2;

    // Variables for Win Check Loop
    integer r, c;
    reg [1:0] check_val;

    always @(posedge clk_25MHz) begin
        if (rst) begin
            for(r=0; r<GRID_SIZE; r=r+1) 
                for(c=0; c<GRID_SIZE; c=c+1) 
                    grid[r][c] <= 0;
            cursor_x <= 7; 
            cursor_y <= 7;
            player_turn <= 0;
            winner <= 0;
            game_over <= 0;
            // Reset scores on hard reset (Switch 0)
            score_p1 <= 0;
            score_p2 <= 0;
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
                // Restart (Center Button) - Clears board but KEEPS score
                if (pulse_s) begin
                    for(r=0; r<GRID_SIZE; r=r+1) for(c=0; c<GRID_SIZE; c=c+1) grid[r][c] <= 0;
                    game_over <= 0; winner <= 0; player_turn <= 0;
                end
            end

            // --- Massive 5-in-a-row Check ---
            // NOTE: We must duplicate the score increment logic in all 4 loops
            // to ensure we catch the win regardless of direction.
            if (!game_over) begin
                
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
                                // Increment Score
                                if (check_val == 1) score_p1 <= score_p1 + 1;
                                else score_p2 <= score_p2 + 1;
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
                                // Increment Score
                                if (check_val == 1) score_p1 <= score_p1 + 1;
                                else score_p2 <= score_p2 + 1;
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
                                // Increment Score
                                if (check_val == 1) score_p1 <= score_p1 + 1;
                                else score_p2 <= score_p2 + 1;
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
                                // Increment Score
                                if (check_val == 1) score_p1 <= score_p1 + 1;
                                else score_p2 <= score_p2 + 1;
                        end
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // 4. Graphics (VGA)
    // -------------------------------------------------------------------------
    wire [9:0] x, y;
    wire video_on;
    vga_sync vga (.clk(clk_25MHz), .rst(rst), .hsync(Hsync), .vsync(Vsync), 
                  .video_on(video_on), .x(x), .y(y));

    localparam CELL_SIZE = 30;
    localparam BOARD_OFFSET_X = 95; 
    localparam BOARD_OFFSET_Y = 30; 
    localparam BOARD_W = GRID_SIZE * CELL_SIZE;
    localparam BOARD_H = GRID_SIZE * CELL_SIZE;

    wire [9:0] rel_x = x - BOARD_OFFSET_X;
    wire [9:0] rel_y = y - BOARD_OFFSET_Y;
    wire [3:0] cell_x = rel_x / CELL_SIZE; 
    wire [3:0] cell_y = rel_y / CELL_SIZE;
    wire [9:0] in_cell_x = rel_x % CELL_SIZE;
    wire [9:0] in_cell_y = rel_y % CELL_SIZE;

    wire on_board = (x >= BOARD_OFFSET_X) && (x < BOARD_OFFSET_X + BOARD_W) &&
                    (y >= BOARD_OFFSET_Y) && (y < BOARD_OFFSET_Y + BOARD_H);

    reg [3:0] red, green, blue;
    always @* begin
        red=0; green=0; blue=0;
        if (video_on) begin
            if (y < BOARD_OFFSET_Y) begin
                if (game_over) begin red=8; blue=8; green=0; end 
                else if (player_turn == 0) red=15;        
                else blue=15;                              
            end
            else if (on_board) begin
                if (in_cell_x == 0 || in_cell_x == CELL_SIZE-1 || 
                    in_cell_y == 0 || in_cell_y == CELL_SIZE-1) begin
                    red=8; green=8; blue=8; 
                end 
                else if (!game_over && cell_x == cursor_x && cell_y == cursor_y) begin
                    green = 4; 
                    if (in_cell_x < 3 || in_cell_x > CELL_SIZE-3 || 
                        in_cell_y < 3 || in_cell_y > CELL_SIZE-3) green=15;
                end
                if (grid[cell_y][cell_x] == 1) begin
                    if ( (in_cell_x - 15)*(in_cell_x - 15) + 
                         (in_cell_y - 15)*(in_cell_y - 15) < 100 ) red=15;
                end 
                else if (grid[cell_y][cell_x] == 2) begin
                    if ( (in_cell_x - 15)*(in_cell_x - 15) + 
                         (in_cell_y - 15)*(in_cell_y - 15) < 100 ) blue=15;
                end
            end
        end
    end
    
    assign vgaRed=red; assign vgaGreen=green; assign vgaBlue=blue;

    // -------------------------------------------------------------------------
    // 5. 7-Segment Display Controller (Score)
    // -------------------------------------------------------------------------
    seg7_control seg_inst (
        .clk(clk), 
        .rst(rst), 
        .num_p1(score_p1), // Left 2 digits
        .num_p2(score_p2), // Right 2 digits
        .seg(seg), 
        .an(an),
        .dp(dp)
    );

endmodule


// --- Helper Modules ---

module seg7_control(
    input clk, rst,
    input [7:0] num_p1,
    input [7:0] num_p2,
    output reg [6:0] seg,
    output reg [3:0] an,
    output wire dp
    );

    assign dp = 1; // Turn decimal point off (Active Low)

    // Refresh Counter (to strobe through the 4 digits)
    // 100MHz / 2^18 approx 381Hz refresh rate
    reg [19:0] refresh_counter;
    always @(posedge clk) begin
        if(rst) refresh_counter <= 0;
        else refresh_counter <= refresh_counter + 1;
    end
    
    wire [1:0] digit_select = refresh_counter[19:18];

    // Mux to choose which number to display
    reg [3:0] hex_digit;
    always @* begin
        case(digit_select)
            2'b00: begin // Digit 0 (Far Right) - P2 Ones
                an = 4'b1110;
                hex_digit = num_p2[3:0];
            end
            2'b01: begin // Digit 1 - P2 Tens (Hex)
                an = 4'b1101;
                hex_digit = num_p2[7:4];
            end
            2'b10: begin // Digit 2 - P1 Ones
                an = 4'b1011;
                hex_digit = num_p1[3:0];
            end
            2'b11: begin // Digit 3 (Far Left) - P1 Tens (Hex)
                an = 4'b0111;
                hex_digit = num_p1[7:4];
            end
        endcase
    end

    // 7-Segment Decoder (Common Anode: 0=On)
    always @* begin
        case(hex_digit)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // Off
        endcase
    end
endmodule

// Standard VGA Sync and Debounce modules remain...
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
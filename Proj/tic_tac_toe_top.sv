`timescale 1ns / 1ps

module tic_tac_toe_top(
    input wire clk,             // 100MHz Clock
    input wire [15:0] sw,       // Switches (We use sw[0] for Reset)
    input wire btnU,            // Button Up
    input wire btnD,            // Button Down
    input wire btnL,            // Button Left
    input wire btnR,            // Button Right
    input wire btnS,            // Button Select (Center)
    output wire [3:0] vgaRed,   // VGA Red
    output wire [3:0] vgaGreen, // VGA Green
    output wire [3:0] vgaBlue,  // VGA Blue
    output wire Hsync,          // Horizontal Sync
    output wire Vsync           // Vertical Sync
    );

    wire rst = sw[0]; // Reset is Switch 0

    // -------------------------------------------------------------------------
    // 1. Clock Generation (100MHz -> 25MHz)
    // -------------------------------------------------------------------------
    reg [1:0] clk_div;
    wire clk_25MHz;

    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end
    assign clk_25MHz = clk_div[1];

    // -------------------------------------------------------------------------
    // 2. Input Debouncing
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
    reg [1:0] grid [2:0][2:0]; // 00=Empty, 01=P1, 10=P2
    reg [1:0] cursor_x; // 0..2
    reg [1:0] cursor_y; // 0..2
    reg player_turn;    // 0=P1, 1=P2
    reg [1:0] winner;   // 0=None, 1=P1, 2=P2
    reg game_over;

    always @(posedge clk_25MHz) begin
        if (rst) begin
            integer i, j;
            for(i=0; i<3; i=i+1) for(j=0; j<3; j=j+1) grid[i][j] <= 0;
            cursor_x <= 0; cursor_y <= 0;
            player_turn <= 0; winner <= 0; game_over <= 0;
        end else begin
            
            if (!game_over) begin
                // Movement (Wrap Around)
                if (pulse_l) cursor_x <= (cursor_x == 0) ? 2 : cursor_x - 1;
                if (pulse_r) cursor_x <= (cursor_x == 2) ? 0 : cursor_x + 1;
                if (pulse_u) cursor_y <= (cursor_y == 0) ? 2 : cursor_y - 1;
                if (pulse_d) cursor_y <= (cursor_y == 2) ? 0 : cursor_y + 1;

                // Selection
                if (pulse_s) begin
                    if (grid[cursor_y][cursor_x] == 0) begin
                        grid[cursor_y][cursor_x] <= (player_turn == 0) ? 2'b01 : 2'b10;
                        player_turn <= ~player_turn;
                    end
                end
            end else begin
                // Restart on Select if game over
                if (pulse_s) begin
                    integer r, c;
                    for(r=0; r<3; r=r+1) for(c=0; c<3; c=c+1) grid[r][c] <= 0;
                    game_over <= 0; winner <= 0; player_turn <= 0;
                end
            end
            
            // Win Checking (Brute Force)
            // Player 1
            if ((grid[0][0]==1 && grid[0][1]==1 && grid[0][2]==1) ||
                (grid[1][0]==1 && grid[1][1]==1 && grid[1][2]==1) ||
                (grid[2][0]==1 && grid[2][1]==1 && grid[2][2]==1) ||
                (grid[0][0]==1 && grid[1][0]==1 && grid[2][0]==1) ||
                (grid[0][1]==1 && grid[1][1]==1 && grid[2][1]==1) ||
                (grid[0][2]==1 && grid[1][2]==1 && grid[2][2]==1) ||
                (grid[0][0]==1 && grid[1][1]==1 && grid[2][2]==1) ||
                (grid[0][2]==1 && grid[1][1]==1 && grid[2][0]==1)) begin
                winner <= 1; game_over <= 1;
            end
            // Player 2
            else if ((grid[0][0]==2 && grid[0][1]==2 && grid[0][2]==2) ||
                     (grid[1][0]==2 && grid[1][1]==2 && grid[1][2]==2) ||
                     (grid[2][0]==2 && grid[2][1]==2 && grid[2][2]==2) ||
                     (grid[0][0]==2 && grid[1][0]==2 && grid[2][0]==2) ||
                     (grid[0][1]==2 && grid[1][1]==2 && grid[2][1]==2) ||
                     (grid[0][2]==2 && grid[1][2]==2 && grid[2][2]==2) ||
                     (grid[0][0]==2 && grid[1][1]==2 && grid[2][2]==2) ||
                     (grid[0][2]==2 && grid[1][1]==2 && grid[2][0]==2)) begin
                winner <= 2; game_over <= 1;
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

    localparam BAR_H = 40;
    localparam CELL_W = 640/3;
    localparam CELL_H = (480-BAR_H)/3;
    
    wire [1:0] cx = (x < CELL_W) ? 0 : (x < 2*CELL_W) ? 1 : 2;
    wire [1:0] cy = (y < BAR_H + CELL_H) ? 0 : (y < BAR_H + 2*CELL_H) ? 1 : 2;
    wire [9:0] rx = x - (cx * CELL_W);
    wire [9:0] ry = y - BAR_H - (cy * CELL_H);

    reg [3:0] r, g, b;
    always @* begin
        r=0; g=0; b=0;
        if (video_on) begin
            if (y < BAR_H) begin // Status Bar
                if (game_over) begin r=15; b=15; end // Purple = Game Over
                else if (player_turn==0) r=15;       // Red = P1
                else b=15;                           // Blue = P2
            end else if ((x>=CELL_W-2 && x<=CELL_W+2) || (x>=2*CELL_W-2 && x<=2*CELL_W+2) ||
                         (y>=BAR_H+CELL_H-2 && y<=BAR_H+CELL_H+2) || 
                         (y>=BAR_H+2*CELL_H-2 && y<=BAR_H+2*CELL_H+2)) begin
                r=15; g=15; b=15; // Grid Lines
            end else if (!game_over && cx==cursor_x && cy==cursor_y) begin
                if (rx<5 || rx>CELL_W-5 || ry<5 || ry>CELL_H-5) g=15; // Green cursor box
            end 
            
            // Symbols
            if (grid[cy][cx] == 1 && y >= BAR_H) begin // P1 Box
                if (rx>50 && rx<CELL_W-50 && ry>40 && ry<CELL_H-40) r=15;
            end else if (grid[cy][cx] == 2 && y >= BAR_H) begin // P2 Plus
                if ((rx>CELL_W/2-10 && rx<CELL_W/2+10 && ry>20 && ry<CELL_H-20) ||
                    (ry>CELL_H/2-10 && ry>CELL_H/2+10 && rx>20 && rx<CELL_W-20)) b=15;
            end
        end
    end
    
    assign vgaRed=r; assign vgaGreen=g; assign vgaBlue=b;
endmodule

// --- Helpers ---
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
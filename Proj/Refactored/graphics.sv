`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 12:37:59 PM
// Design Name: 
// Module Name: graphics
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

module graphics(
    input wire [9:0] pixel_x, pixel_y,
    input wire video_on,
    input wire [1:0] grid [14:0][14:0],
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

    // Center screen math
    wire [9:0] cx = 320;
    wire [9:0] cy = 240;
    wire [9:0] menu_dx = (pixel_x > cx) ? pixel_x - cx : cx - pixel_x;
    wire [9:0] menu_dy = (pixel_y > cy) ? pixel_y - cy : cy - pixel_y;

    // helper
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
            
            // menu screen (big avatar in center)
            if (state == S_SELECT_P1 || state == S_SELECT_P2) begin
                if (state == S_SELECT_P1) r = 2; 
                else b = 2;                      

                if (is_pixel_in_shape(menu_current_shape, menu_dx, menu_dy, 60)) begin
                    if (state == S_SELECT_P1) r=15; else b=15;
                end
            end

            // gameplay (with grid)
            else begin
                if (pixel_y < BOARD_OFF_Y) begin
                    // top bar
                    if (state == S_WIN) begin r=8; b=8; end // purple (game over)
                    else if (player_turn == 0) r=15;        // red
                    else b=15;                              // blue
                end
                else if (on_board) begin
                    if (ix == 0 || ix == 29 || iy == 0 || iy == 29) begin
                        r=8; g=8; b=8; // empty
                    end 
                    else if (state == S_PLAY && cell_x == cursor_x && cell_y == cursor_y) begin
                        g = 4; // faint cursor fill
                        if (ix < 3 || ix > 26 || iy < 3 || iy > 26) g=15; // strong cursor highlight around border
                    end
                    
                    if (grid[cell_y][cell_x] == 1) begin
                        if (is_pixel_in_shape(p1_shape, cell_dx, cell_dy, 10)) r=15; // P1: red
                    end 
                    else if (grid[cell_y][cell_x] == 2) begin
                        if (is_pixel_in_shape(p2_shape, cell_dx, cell_dy, 10)) b=15; // P2: blue
                    end
                end
            end
        end
    end
    
    assign red_out = r;
    assign green_out = g;
    assign blue_out = b;

endmodule

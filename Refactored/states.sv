`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 12:37:59 PM
// Design Name: 
// Module Name: states
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


// -----------------------------------------------------------------------------
// Shared Types
// -----------------------------------------------------------------------------
package states;
    typedef enum logic [1:0] {
        S_SELECT_P1 = 0, // Player 1 choosing avatar
        S_SELECT_P2 = 1, // Player 2 choosing avatar
        S_PLAY      = 2, // Main Game
        S_WIN       = 3  // Game Over
    } state_t;
endpackage

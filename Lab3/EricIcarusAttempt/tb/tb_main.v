`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_main
// Description: Testbench for the top-level stopwatch module (main.v)
//////////////////////////////////////////////////////////////////////////////////

module tb_main;

    // --- Inputs ---
    reg clk;
    reg btnC; // Reset Button
    reg btnU; // Pause/Resume Button
    reg [1:0] sw; // sw[1]=SEL, sw[0]=ADJ

    // --- Outputs ---
    wire [6:0] segment;
    wire [3:0] anode;

    // --- DEBUG Wires (Must match output ports added to main.v for testing) ---
    wire [3:0] min_tens_out;
    wire [3:0] min_ones_out;
    wire [3:0] sec_tens_out;
    wire [3:0] sec_ones_out;
    wire [1:0] state_out; // FSM State
    wire pause_btn_debounced_out; // Debounced Pause Button State


    // --- Instantiate the DUT (Device Under Test) ---
    main dut (
        .clk(clk),
        .btnC(btnC),
        .btnU(btnU),
        .sw(sw),
        .segment(segment),
        .anode(anode),
        // --- Testbench Monitor Outputs from main.v ---
        .bcd_min_tens_out(min_tens_out),
        .bcd_min_ones_out(min_ones_out),
        .bcd_sec_tens_out(sec_tens_out),
        .bcd_sec_ones_out(sec_ones_out),
        .state_out(state_out),
        .pause_btn_debounced_out(pause_btn_debounced_out)
    );

    // --- Clock Generation (100MHz) ---
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period

    // --- Helper Task for Button Presses (Edge Triggered) ---
    // Drastically reducing button press time for instantaneous simulation.
    task press_button;
        inout reg btn;
        begin
            btn = 1'b1;
            #1000; // Hold long enough to guarantee rising edge detection
            btn = 1'b0;
            #1000; // Wait for release to settle
        end
    endtask

    // --- FSM State Mapping for readability (Must match stopwatch.v) ---
    localparam S_PAUSED = 2'b00;
    localparam S_COUNTING = 2'b01;
    localparam S_ADJUST_PAUSED = 2'b10;
    localparam S_ADJUST_COUNTING = 2'b11;

    // Accelerated Sim Timing Constants (1Hz = 10,000ns based on clock.v)
    localparam ONE_SEC_ACCEL = 10_000;

    // --- FIXED DELAY CONSTANTS ---
    localparam DELAY_3_SEC = 3 * ONE_SEC_ACCEL;
    localparam DELAY_2_SEC = 2 * ONE_SEC_ACCEL;


    // --- Test Stimulus ---
    initial begin
        $display("=============================================");
        $display("   Testbench for main.v (Stopwatch)");
        $display("   *** Running in ACCELERATED SIMULATION mode ***");
        $display("   (1 second of stopwatch time = 10,000ns simulation time)");
        $display("=============================================");
        $display("Time (ns) | Event");
        $display("---------------------------------------------");

        // 1. Initialize all inputs
        btnC = 0; // Reset button
        btnU = 0; // Pause/Resume button
        sw = 2'b00; // sw[1]=SEL, sw[0]=ADJ
        #1000;

        // 2. Initial Reset
        $display("%10t | Applying Reset (btnC)...", $time);
        press_button(btnC); // Resets to 00:00, S_PAUSED (00)
        #ONE_SEC_ACCEL;

        // 3. Start Counting
        $display("%10t | Pressing Resume (btnU) to start counting...", $time);
        press_button(btnU); // S_PAUSED -> S_COUNTING (01)

        // 4. Count for 3.0 seconds (3 x 1Hz ticks)
        $display("%10t | --- Counting for 3.0s (Target: 00:03) ---", $time);
        #DELAY_3_SEC;

        // Check 3.0s count
        $display("---------------------------------------------");
        $display("CHECK: Time=%10t | Time= %d%d:%d%d | state=%h | sw=%b (Expected 00:03, State: %h)",
                 $time,
                 min_tens_out,
                 min_ones_out,
                 sec_tens_out,
                 sec_ones_out,
                 state_out,
                 sw, S_COUNTING);
        $display("---------------------------------------------");


        // 5. Pause the stopwatch
        $display("%10t | Pressing Pause (btnU)...", $time);
        press_button(btnU); // S_COUNTING -> S_PAUSED (00)

        // 6. Wait for 2.0 seconds (count should not change)
        $display("%10t | --- Paused for 2s ---", $time);
        #DELAY_2_SEC;

        // Check paused value
        $display("---------------------------------------------");
        $display("CHECK: Time=%10t | Time= %d%d:%d%d | state=%h | sw=%b (Expected 00:03, State: %h)",
                 $time,
                 min_tens_out,
                 min_ones_out,
                 sec_tens_out,
                 sec_ones_out,
                 state_out,
                 sw, S_PAUSED);
        $display("---------------------------------------------");

        // 7. Enter Adjust Mode (Minutes: sw=01). ADJ=1, SEL=0.
        $display("%10t | Enter Adjust Mode (Minutes: sw=01). Should start auto-adjust at 2Hz.", $time);
        sw = 2'b01; // S_PAUSED -> S_ADJUST_PAUSED (10)

        // 8. Adjust Minutes for 3.0 seconds (3s * 2Hz = 6 increments)
        $display("%10t | --- Adjusting Minutes for 3s (Target: 06:03) ---", $time);
        #DELAY_3_SEC;

        // Check adjust minutes (00:03 + 6 min = 06:03)
        $display("---------------------------------------------");
        $display("CHECK: Time=%10t | Time= %d%d:%d%d | state=%h | sw=%b (Expected 06:03, State: %h)",
                 $time,
                 min_tens_out,
                 min_ones_out,
                 sec_tens_out,
                 sec_ones_out,
                 state_out,
                 sw, S_ADJUST_PAUSED);
        $display("---------------------------------------------");

        // 9. Switch to Adjust Mode (Seconds: sw=11). ADJ=1, SEL=1.
        $display("%10t | Switch to Adjust Mode (Seconds: sw=11). Continues auto-adjust at 2Hz.", $time);
        sw = 2'b11; // Stays in S_ADJUST_PAUSED (10)

        // 10. Adjust Seconds for 3.0 seconds (3s * 2Hz = 6 increments)
        $display("%10t | --- Adjusting Seconds for 3s (Target: 06:09) ---", $time);
        #DELAY_3_SEC;

        // Check adjust seconds (06:03 + 6 sec = 06:09)
        $display("---------------------------------------------");
        $display("CHECK: Time=%10t | Time= %d%d:%d%d | state=%h | sw=%b (Expected 06:09, State: %h)",
                 $time,
                 min_tens_out,
                 min_ones_out,
                 sec_tens_out,
                 sec_ones_out,
                 state_out,
                 sw, S_ADJUST_PAUSED);
        $display("---------------------------------------------");

        // 11. Exit Adjust Mode
        $display("%10t | Exit Adjust Mode (sw=00). Should return to Paused state.", $time);
        sw = 2'b00; // S_ADJUST_PAUSED -> S_PAUSED (00)

        // 12. Wait 2.0 seconds (Should be paused)
        $display("%10t | --- Paused for 2s ---", $time);
        #DELAY_2_SEC;

        // Check if paused
        $display("---------------------------------------------");
        $display("CHECK: Time=%10t | Time= %d%d:%d%d | state=%h | sw=%b (Expected 06:09, State: %h)",
                 $time,
                 min_tens_out,
                 min_ones_out,
                 sec_tens_out,
                 sec_ones_out,
                 state_out,
                 sw, S_PAUSED);
        $display("---------------------------------------------");

        // 13. Resume Counting
        $display("%10t | Pressing Resume (btnU) to continue counting...", $time);
        press_button(btnU); // S_PAUSED -> S_COUNTING (01)

        // 14. Count for 2.0 seconds (2 x 1Hz ticks)
        $display("%10t | --- Counting for 2.0s (Target: 06:11) ---", $time);
        #DELAY_2_SEC;

        // Check final count
        $display("---------------------------------------------");
        $display("CHECK: Time=%10t | Time= %d%d:%d%d | state=%h | sw=%b (Expected 06:11, State: %h)",
                 $time,
                 min_tens_out,
                 min_ones_out,
                 sec_tens_out,
                 sec_ones_out,
                 state_out,
                 sw, S_COUNTING);
        $display("---------------------------------------------");

        // 15. Final Reset
        $display("%10t | Applying Final Reset (btnC)...", $time);
        press_button(btnC);
        #ONE_SEC_ACCEL;

        $display("%10t | Simulation complete.", $time);
        $display("=============================================");
        $finish;
    end

    // --- Monitoring ---
    initial begin
        $monitor("Time=%t | MIN_T=%d MIN_O=%d | SEC_T=%d SEC_O=%d | state=%h | pause_btn=%b | sw=%b",
                 $time,
                 min_tens_out,
                 min_ones_out,
                 sec_tens_out,
                 sec_ones_out,
                 state_out,
                 pause_btn_debounced_out,
                 sw);
    end

endmodule
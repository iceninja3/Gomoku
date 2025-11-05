`timescale 1ns / 1ps

module tb_stopwatch;

    // --- DUT Signals ---
    reg clk_100mhz;
    reg rst;
    reg button_pause;
    reg switch_sel;
    reg switch_adj;

    // Clock Pulse Wires (Generated below)
    wire clk_1hz;
    wire clk_2hz;

    // BCD Outputs
    wire [3:0] bcd_min_tens;
    wire [3:0] bcd_min_ones;
    wire [3:0] bcd_sec_tens;
    wire [3:0] bcd_sec_ones;

    // State/Status Outputs
    wire is_adj;
    wire is_sel_sec;
    wire [1:0] state_out;

    // --- Instantiate DUT (stopwatch.v) ---
    stopwatch i_dut (
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .button_pause(button_pause),
        .switch_sel(switch_sel),
        .switch_adj(switch_adj),

        .bcd_min_tens(bcd_min_tens),
        .bcd_min_ones(bcd_min_ones),
        .bcd_sec_tens(bcd_sec_tens),
        .bcd_sec_ones(bcd_sec_ones),

        .is_adj(is_adj),
        .is_sel_sec(is_sel_sec),
        .state_out(state_out)
    );

    // --- Clock Generation ---
    initial clk_100mhz = 0;
    always #5 clk_100mhz = ~clk_100mhz; // 10ns period (100MHz)

    // Scaling Factor: 1s actual = 100us simulation (100,000ns)
    localparam CLK_1HZ_PERIOD_NS = 100_000; // 1Hz pulse every 100us (1s actual)
    localparam CLK_2HZ_PERIOD_NS = 50_000;  // 2Hz pulse every 50us

    reg [31:0] clk_1hz_count = 0;
    reg [31:0] clk_2hz_count = 0;
    reg clk_1hz_pulse = 0;
    reg clk_2hz_pulse = 0;

    // 1Hz Pulse Generator
    always @(posedge clk_100mhz) begin
        if (rst) begin
            clk_1hz_count <= 0;
            clk_1hz_pulse <= 0;
        end else begin
            if (clk_1hz_count == (CLK_1HZ_PERIOD_NS / 10) - 1) begin
                clk_1hz_count <= 0;
                clk_1hz_pulse <= 1; // Pulse for one clock cycle
            end else begin
                clk_1hz_count <= clk_1hz_count + 1;
                clk_1hz_pulse <= 0;
            end
        end
    end
    assign clk_1hz = clk_1hz_pulse;


    // 2Hz Pulse Generator
    always @(posedge clk_100mhz) begin
        if (rst) begin
            clk_2hz_count <= 0;
            clk_2hz_pulse <= 0;
        end else begin
            if (clk_2hz_count == (CLK_2HZ_PERIOD_NS / 10) - 1) begin
                clk_2hz_count <= 0;
                clk_2hz_pulse <= 1; // Pulse for one clock cycle
            end else begin
                clk_2hz_count <= clk_2hz_count + 1;
                clk_2hz_pulse <= 0;
            end
        end
    end
    assign clk_2hz = clk_2hz_pulse;

    // --- Helper Task for Logging ---
    task print_stopwatch_state;
        input [100:0] action_msg;
        $display("Time: %10.1f ns | State: %02b | is_adj: %1b | is_sel_sec: %1b | Action: %s. Time: %0d%0d:%0d%0d (MM:SS)",
                 $realtime, state_out, is_adj, is_sel_sec, action_msg,
                 bcd_min_tens, bcd_min_ones, bcd_sec_tens, bcd_sec_ones);
    endtask

    // --- Test Scenarios ---
    initial begin
        $display("------------------------------------------------------------------");
        $display("Start Test: Scaled Stopwatch Module Timing (1s now = 100us)");
        $display("------------------------------------------------------------------");

        // Initialize inputs
        rst = 1;
        button_pause = 0;
        switch_adj = 0;
        switch_sel = 1; // Default to seconds selected

        // --- SCENARIO 1: Reset ---
        #6;
        print_stopwatch_state("Asserting Reset (rst=1)");

        #10;
        rst = 0;
        print_stopwatch_state("Deasserting Reset");

        // --- SCENARIO 2: START COUNTING (00 -> 01) ---
        #20;
        button_pause = 1; // Start press
        #6;
        print_stopwatch_state("Start Counting (Press down)");

        #10;
        button_pause = 0; // Release press
        #20;
        print_stopwatch_state("Start Counting (Released)");


        // Count for 5s (500,000ns total time, 5 pulses of 1hz)
        // Current time: ~46ns. Need to wait until 500,000ns
        # (500000 - $realtime);
        print_stopwatch_state("Counted for 5s (Should be 00:05)");

        // --- SCENARIO 3: PAUSE (01 -> 00) ---
        #16;
        button_pause = 1; // Pause press
        #6;
        print_stopwatch_state("Paused (Press down)");

        #10;
        button_pause = 0; // Pause release
        #20;
        print_stopwatch_state("Paused (Released). Time should be 00:05");

        // Paused for 2s (200,000ns)
        #200000;
        print_stopwatch_state("Paused for 2s. Time should be unchanged at 00:05");

        // --- SCENARIO 4: ADJUST SECONDS (00 -> 10) ---
        #10;
        switch_adj = 1; // Enter ADJ mode
        switch_sel = 1; // Select Seconds (Default)
        print_stopwatch_state("Enter ADJ mode (Secs selected)");

        // Adjusted Seconds by 6 ticks (6 * 50,000ns = 300,000ns)
        // We wait for 6 ticks of clk_2hz, which takes ~300,000ns.
        #300000;
        print_stopwatch_state("Adjusted Seconds by 6 ticks. Should be 00:11 (5 + 6)");

        // --- SCENARIO 5: ADJUST MINUTES ---
        #7;
        switch_sel = 0; // Select Minutes
        print_stopwatch_state("Select Minutes (Still in ADJ mode)");

        // Adjusted Minutes by 4 ticks (4 * 50,000ns = 200,000ns)
        #200000;
        print_stopwatch_state("Adjusted Minutes by 4 ticks. Should be 04:11 (0 + 4)");

        // --- SCENARIO 6: EXIT ADJUST (10 -> 00) ---
        #7;
        switch_adj = 0; // Exit ADJ mode
        print_stopwatch_state("Exit ADJ mode. Should be 04:11");

        // --- SCENARIO 7: Testing Min/Sec Roll-Over ---
        #20;
        button_pause = 1; // Resume counting (00 -> 01)
        #6;
        print_stopwatch_state("Resume counting from 04:11 (Press down)");

        #10;
        button_pause = 0; // Release press
        #20;
        print_stopwatch_state("Resume counting from 04:11 (Released)");

        // Count 50 more seconds. (50 * 100,000ns = 5,000,000ns)
        // Time = 04:11. Expected final time: 05:01
        #5000000;
        print_stopwatch_state("Counted 50 more seconds. Should be 05:01 (04:11 + 50s)");

        $display("===========================================");
        $display("Simulation finished successfully.");
        $finish;
    end
endmodule

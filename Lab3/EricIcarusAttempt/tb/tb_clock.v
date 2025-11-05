`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for the clock module (clock.v)
// Verifies accelerated clock frequencies using the CLK_FREQ = 1000 setting.
// Expected periods: 500Hz=20ns, 4Hz=2500ns, 2Hz=5000ns, 1Hz=10000ns.
// Includes robust pulse detection and a monitor for debugging stalls.
//////////////////////////////////////////////////////////////////////////////////

module tb_clock;
    // --- Testbench Signals ---
    reg clk_100mhz; // 10ns period (5ns high, 5ns low)

    // Wires for DUT outputs (Clock Enable Pulses)
    wire clk_1hz;
    wire clk_2hz;
    wire clk_500hz;
    wire clk_4hz;

    // --- 1. DUT Instantiation ---
    clock dut (
        .clk_100mhz(clk_100mhz),
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .clk_500hz(clk_500hz),
        .clk_4hz(clk_4hz)
    );

    // --- 2. 100MHz Clock Generation (10 ns period) ---
    initial clk_100mhz = 0;
    always #5 clk_100mhz = ~clk_100mhz; // Toggle every 5ns

    // --- 3. Verification Task (Robust Pulse Period Measurement) ---
    task check_tick;
        input string clk_name;
        input clk_signal;
        input [63:0] expected_period;

        begin
            reg [63:0] start_time;

            // Wait for the FIRST pulse (posedge)
            @(posedge clk_signal);
            start_time = $time;
            $display("@%0t: %s Ticked (Start time for period measurement)", $time, clk_name);

            // Wait for the pulse to go LOW (negedge)
            @(negedge clk_signal);

            // Wait for the SECOND pulse (posedge)
            @(posedge clk_signal);

            if (($time - start_time) == expected_period) begin
                $display("@%0t: %s VERIFIED. Measured Period: %0dns.", $time, clk_name, expected_period);
            end else begin
                $display("@%0t: %s ERROR! Expected Period: %0dns, Actual Period: %0dns. (Stuck at %0tns)",
                         $time, clk_name, expected_period, ($time - start_time), $time);
                // NOTE: We don't $finish here so we can see the $monitor output longer
                // $finish;
            end
        end
    endtask


    // --- 4. Simulation Stimulus ---
    initial begin
        $display("-------------------------------------------------");
        $display("Clock Module Simulation Started (CLK_FREQ = 1000)");
        $display("-------------------------------------------------");

        // Settle time: Give the counters time to run the first pulse
        #50;

        // Sequential Check 1: 500Hz (20 ns period)
        check_tick("clk_500hz", clk_500hz, 20);

        // Sequential Check 2: 4Hz (2,500 ns period)
        check_tick("clk_4hz", clk_4hz, 2500);

        // Sequential Check 3: 2Hz (5,000 ns period)
        check_tick("clk_2hz", clk_2hz, 5000);

        // Sequential Check 4: 1Hz (10,000 ns period)
        check_tick("clk_1hz", clk_1hz, 10000);

        // Wait a short time to finish simulation
        #100;

        $display("-------------------------------------------------");
        $display("All Clocks Verified. Simulation Complete.");
        $finish;
    end

    // --- 5. Debug Monitor ---
    // Prints signal state whenever ANY signal changes. This will show where the stall is.
    initial begin
        $monitor("@%0t: clk_100mhz=%b, 500hz=%b, 4hz=%b, 2hz=%b, 1hz=%b",
                 $time, clk_100mhz, clk_500hz, clk_4hz, clk_2hz, clk_1hz);
    end

endmodule

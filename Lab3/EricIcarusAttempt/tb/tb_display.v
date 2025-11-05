`timescale 1ns / 1ps

module tb_display;

    // Clock and reset
    reg clk_100mhz;
    reg rst;
    reg clk_500hz;
    reg clk_4hz;

    // BCD inputs
    reg [3:0] bcd_min_tens;
    reg [3:0] bcd_min_ones;
    reg [3:0] bcd_sec_tens;
    reg [3:0] bcd_sec_ones;

    // Adjust/selection signals
    reg is_adjust;
    reg is_sel_sec;

    // Outputs
    wire [6:0] segment;
    wire [3:0] anode;

    display dut (
        .clk_100mhz(clk_100mhz),
        .rst(rst),
        .clk_500hz(clk_500hz),
        .clk_4hz(clk_4hz),
        .bcd_min_tens(bcd_min_tens),
        .bcd_min_ones(bcd_min_ones),
        .bcd_sec_tens(bcd_sec_tens),
        .bcd_sec_ones(bcd_sec_ones),
        .is_adjust(is_adjust),
        .is_sel_sec(is_sel_sec),
        .segment(segment),
        .anode(anode)
    );

    initial clk_100mhz = 0;
    always #5 clk_100mhz = ~clk_100mhz;

    initial clk_500hz = 0;
    always #1000 clk_500hz = ~clk_500hz; // 1 kHz period for simulation

    initial clk_4hz = 0;
    always #125000 clk_4hz = ~clk_4hz; // 250 us period for simulation

    // Test stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        is_adjust = 0;
        is_sel_sec = 0;
        bcd_min_tens = 0;
        bcd_min_ones = 0;
        bcd_sec_tens = 0;
        bcd_sec_ones = 0;

        #20;
        rst = 0;

        // Simulate a few seconds count
        repeat (5) begin
            {bcd_min_tens, bcd_min_ones, bcd_sec_tens, bcd_sec_ones} = 16'd0;
            #2000;
            bcd_sec_ones = 4'd1;
            #2000;
            bcd_sec_ones = 4'd2;
            #2000;
            bcd_sec_tens = 4'd1;
            bcd_sec_ones = 4'd3;
            #2000;
        end

        // Simulate adjust mode for minutes
        is_adjust = 1;
        is_sel_sec = 0;
        bcd_min_tens = 4'd1;
        bcd_min_ones = 4'd2;
        bcd_sec_tens = 4'd3;
        bcd_sec_ones = 4'd4;
        #10000;

        // Simulate adjust mode for seconds
        is_sel_sec = 1;
        #10000;

        $display("Simulation complete");
        $finish;
    end


    // Declare an intermediate signal for monitoring
    reg [15:0] bcd_mux_flat;

    always @(*) begin
        bcd_mux_flat = (bcd_min_tens << 12) |
                    (bcd_min_ones << 8) |
                    (bcd_sec_tens << 4) |
                    bcd_sec_ones;
    end

    initial begin
        $monitor("Time: %t | anode: %b | segment: %b | bcd_mux_flat: %b | blink_on: %b",
                $time, anode, segment, bcd_mux_flat, dut.blink_on);
    end
endmodule

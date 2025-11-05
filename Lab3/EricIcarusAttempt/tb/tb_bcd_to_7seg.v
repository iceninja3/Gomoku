`timescale 1ns / 1ps

module tb_bcd_to_7seg;
    reg  [3:0] bcd_in;
    wire [6:0] seg_out;

    BCD_to_7Seg dut (
        .bcd_in(bcd_in),
        .seg_out(seg_out)
    );

    integer i;

    initial begin
        $display("=============================================");
        $display("   Testbench for BCD_to_7Seg");
        $display("=============================================");
        $display("Time (ns) | BCD_in | seg_out");
        $display("---------------------------------------------");

        // Test all BCD values 0–9
        for (i = 0; i <= 9; i = i + 1) begin
            bcd_in = i[3:0];
            #5;
            $display("%8t |   %1d    | %07b", $time, bcd_in, seg_out);
        end

        // Test an invalid (default) case
        bcd_in = 4'd15;
        #5;
        $display("%8t |   %1d    | %07b (default case)", $time, bcd_in, seg_out);

        $display("=============================================");
        $display("Simulation complete.");
        $finish;
    end
endmodule

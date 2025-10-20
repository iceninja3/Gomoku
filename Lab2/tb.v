`timescale 1ns/1ps

module tb_fpcvt;

    // DUT inputs and outputs
    reg  [11:0] d;
    wire        s;
    wire [2:0]  e;
    wire [3:0]  f;

    // Instantiate the DUT
    fpcvt uut (
        .d(d),
        .s(s),
        .e(e),
        .f(f)
    );

    // Task to display formatted result
    task show_result;
        input [11:0] val;
        begin
            #1; // small delay for combinational settle
            $display("Input %6d (bin=%b) -> S=%b  E=%0d  F=%b", 
                     $signed(val), val, s, e, f);
        end
    endtask

    initial begin
        $display("========================================");
        $display("   Floating-Point Conversion Testbench  ");
        $display("========================================");

        // Zero and small positives
        d = 12'd0;          show_result(d);
        d = 12'd1;          show_result(d);
        d = 12'd3;          show_result(d);
        d = 12'd7;          show_result(d);
        d = 12'd15;         show_result(d);

        // Mid-range positives
        d = 12'd32;         show_result(d);
        d = 12'd63;         show_result(d);
        d = 12'd128;        show_result(d);
        d = 12'd255;        show_result(d);
        d = 12'd422;        show_result(d);
        d = 12'd1023;       show_result(d);

        // Maximum positive
        d = 12'd2047;       show_result(d);

        // Negatives
        d = -12'd1;         show_result(d);
        d = -12'd15;        show_result(d);
        d = -12'd32;        show_result(d);
        d = -12'd63;        show_result(d);
        d = -12'd422;       show_result(d);
        d = -12'd1023;      show_result(d);
        d = -12'd2047;      show_result(d);
        d = -12'd2048;      show_result(d);  // edge case (most negative)

        $display("========================================");
        $finish;
    end

endmodule

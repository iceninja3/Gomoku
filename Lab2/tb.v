module tb;

    // DUT inputs and outputs
    reg  [11:0] d;
    wire        s;
    wire [2:0]  e;
    wire [3:0]  f;

    // Instantiate the DUT
    fpcvt uut (
        .D(d),
        .S(s),
        .E(e),
        .F(f)
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

        d = 12'd0;          show_result(d);
        d = 12'd1;          show_result(d);
        d = 12'd15;         show_result(d);
        d = 12'd63;         show_result(d);
        d = 12'd422;        show_result(d);
        d = 12'd1023;       show_result(d);
        d = 12'd1500;       show_result(d);
        d = 12'd2000;       show_result(d);
        d = 12'd2047;       show_result(d);
        
        d = -12'd1;         show_result(d);
        d = -12'd15;        show_result(d);
        d = -12'd63;        show_result(d);
        d = -12'd422;       show_result(d);
        d = -12'd1023;      show_result(d);
        d = -12'd1500;      show_result(d);
        d = -12'd2000;      show_result(d);
        d = -12'd2048;      show_result(d);

        $display("========================================");
        $finish;
    end

endmodule

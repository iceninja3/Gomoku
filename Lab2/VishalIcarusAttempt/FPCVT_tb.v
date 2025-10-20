/**
 * @file FPCVT_tb.v
 * @brief Testbench for the FPCVT floating-point converter module.
 * @details This testbench verifies the FPCVT module by applying a series
 * of test vectors that cover various cases, including positive/negative
 * numbers, zero, rounding, and overflow conditions.
 */
`timescale 1ns / 1ps

module FPCVT_tb;

    //================================================================
    // Testbench Signals
    //================================================================
    reg  [11:0] D_tb;   // Input to the DUT
    wire        s_tb;   // Sign output from DUT
    wire [2:0]  E_tb;   // Exponent output from DUT
    wire [3:0]  F_tb;   // Significand output from DUT

    integer     fail_count; // Counter for failed tests

    //================================================================
    // Instantiate the Device Under Test (DUT)
    //================================================================
    FPCVT dut (
        .D(D_tb),
        .s(s_tb),
        .E(E_tb),
        .F(F_tb)
    );

    //================================================================
    // Test Task
    //================================================================
    // This task simplifies running a single test case.
    // It applies inputs, waits, and checks outputs against expected values.
    task run_test(
        input [11:0] D_in,      // 12-bit input vector
        input        s_exp,     // Expected sign
        input [2:0]  E_exp,     // Expected exponent
        input [3:0]  F_exp      // Expected significand
    );
    begin
        D_tb = D_in;
        #10; // Wait for combinational logic to settle

        if (s_tb === s_exp && E_tb === E_exp && F_tb === F_exp) begin
            $display("✅ PASS: (D=%d)", D_in);
        end else begin
            $display("❌ FAIL: (D=%d)", D_in);
            $display("      Expected s=%b, E=%d, F=%d (%b)", s_exp, E_exp, F_exp, F_exp);
            $display("      Got      s=%b, E=%d, F=%d (%b)", s_tb, E_tb, F_tb, F_tb);
            fail_count = fail_count + 1;
        end
    end
    endtask

    //================================================================
    // Main Test Sequence
    //================================================================
    initial begin
        $display("--- Starting FPCVT Testbench ---");
        fail_count = 0;

        //                 D_in,      s_exp, E_exp, F_exp
        run_test(           12'd0,    1'b0,  3'd0,  4'd0);    // Zero
        run_test(           12'd15,   1'b0,  3'd0,  4'd15);   // Max value for E=0
        run_test(           12'd16,   1'b0,  3'd1,  4'd8);    // Min value for E=1
        run_test(           12'd422,  1'b0,  3'd5,  4'd13);   // Positive number (422)
        run_test(          -12'd422,  1'b1,  3'd5,  4'd13);   // Negative number (-422)
        run_test(           12'd43,   1'b0,  3'd2,  4'd11);   // Rounding down (0...101011)
        run_test(           12'd46,   1'b0,  3'd2,  4'd12);   // Rounding up (0...101110)
        run_test(           12'd125,  1'b0,  3'd4,  4'd8);    // Significand overflow
        run_test(           12'd2047, 1'b0,  3'd7,  4'd15);   // Exponent overflow (saturation)
        run_test(          -12'd1,    1'b1,  3'd0,  4'd1);    // Negative one
        run_test(          -12'd2048, 1'b1,  3'd7,  4'd8);    // Most negative number (-2048)
        
        // Final summary
        #20;
        if (fail_count == 0) begin
            $display("\n🎉 All tests passed!");
        end else begin
            $display("\n🚨 %d test(s) failed.", fail_count);
        end

        $finish;
    end

endmodule
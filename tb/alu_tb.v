// alu_tb.v
// Test bench for the alu module.
// This TB verifies various arithmetic, logical, and shift operations,
// and flag generation.

`timescale 1ns / 1ps

module alu_tb;

    // Inputs to the DUT
    reg [31:0] operand1_in;
    reg [31:0] operand2_in;
    reg [3:0] alu_op_in;
    reg [1:0] shift_type_in;
    reg [4:0] shift_amt_in;
    reg alu_invert_operand2_in;

    // Outputs from the DUT
    wire [31:0] alu_result_out;
    wire zero_flag_out;
    wire negative_flag_out;
    wire carry_flag_out;
    wire overflow_flag_out;

    // Instantiate the DUT
    alu dut (
        .operand1(operand1_in),
        .operand2(operand2_in),
        .alu_op(alu_op_in),
        .shift_type(shift_type_in),
        .shift_amt(shift_amt_in),
        .alu_invert_operand2(alu_invert_operand2_in),
        .alu_result(alu_result_out),
        .zero_flag(zero_flag_out),
        .negative_flag(negative_flag_out),
        .carry_flag(carry_flag_out),
        .overflow_flag(overflow_flag_out)
    );

    initial begin
        // Dump waves for GTKWave
        $dumpfile("alu_waves.vcd");
        $dumpvars(0, alu_tb);

        $display("-----------------------------------------------------------------------------------------------------------------");
        $display("Time | Op1 (Hex) | Op2 (Hex) | ALU_Op | ShiftType | ShiftAmt | InvertOp2 | Result (Hex) | Z | N | C | V");
        $display("-----------------------------------------------------------------------------------------------------------------");

        // Helper macro for displaying results
        `define DISPLAY_ALU_RESULT $display("%0t | %h      | %h      | %b     | %b        | %0d        | %b         | %h         | %b| %b| %b| %b", \
                                            $time, operand1_in, operand2_in, alu_op_in, shift_type_in, shift_amt_in, alu_invert_operand2_in, \
                                            alu_result_out, zero_flag_out, negative_flag_out, carry_flag_out, overflow_flag_out);

        // Initialize inputs
        operand1_in = 32'b0;
        operand2_in = 32'b0;
        alu_op_in = 4'b0000; // ADD
        shift_type_in = 2'b00; // LSL
        shift_amt_in = 5'b0;
        alu_invert_operand2_in = 1'b0;
        #10;

        // Test 1: ADD (10 + 20 = 30)
        operand1_in = 32'd10;
        operand2_in = 32'd20;
        alu_op_in = 4'b0000; // ADD
        alu_invert_operand2_in = 1'b0;
        #10; `DISPLAY_ALU_RESULT

        // Test 2: SUB (30 - 10 = 20)
        operand1_in = 32'd30;
        operand2_in = 32'd10;
        alu_op_in = 4'b0001; // SUB
        alu_invert_operand2_in = 1'b0;
        #10; `DISPLAY_ALU_RESULT

        // Test 3: SUB (10 - 30 = -20) - Negative Result
        operand1_in = 32'd10;
        operand2_in = 32'd30;
        alu_op_in = 4'b0001; // SUB
        alu_invert_operand2_in = 1'b0;
        #10; `DISPLAY_ALU_RESULT

        // Test 4: AND (0xF0F0F0F0 & 0x0F0F0F0F = 0)
        operand1_in = 32'hF0F0F0F0;
        operand2_in = 32'h0F0F0F0F;
        alu_op_in = 4'b0101; // AND
        #10; `DISPLAY_ALU_RESULT

        // Test 5: ORR (0x12345678 | 0x87654321)
        operand1_in = 32'h12345678;
        operand2_in = 32'h87654321;
        alu_op_in = 4'b0110; // ORR
        #10; `DISPLAY_ALU_RESULT

        // Test 6: XOR (0x12345678 ^ 0x12345678 = 0)
        operand1_in = 32'h12345678;
        operand2_in = 32'h12345678;
        alu_op_in = 4'b0111; // XOR
        #10; `DISPLAY_ALU_RESULT

        // Test 7: BIC (0xF0F0F0F0 BIC 0x0F0F0F0F) = 0xF0F0F0F0 & (~0x0F0F0F0F) = 0xF0F0F0F0 & 0xF0F0F0F0 = 0xF0F0F0F0
        operand1_in = 32'hF0F0F0F0;
        operand2_in = 32'h0F0F0F0F;
        alu_op_in = 4'b1000; // BIC
        alu_invert_operand2_in = 1'b1; // Enable inversion for BIC
        #10; `DISPLAY_ALU_RESULT
        alu_invert_operand2_in = 1'b0; // Reset for next tests

        // Test 8: MVN (MVN 0x12345678) = ~0x12345678
        operand1_in = 32'b0; // Rn ignored for MVN
        operand2_in = 32'h12345678;
        alu_op_in = 4'b1001; // MVN
        alu_invert_operand2_in = 1'b1; // Enable inversion for MVN
        #10; `DISPLAY_ALU_RESULT
        alu_invert_operand2_in = 1'b0; // Reset for next tests

        // Test 9: CMP (10 - 10 = 0) - Check Zero Flag
        operand1_in = 32'd10;
        operand2_in = 32'd10;
        alu_op_in = 4'b1010; // CMP
        #10; `DISPLAY_ALU_RESULT

        // Test 10: TST (0x0F0F0F0F & 0xF0F0F0F0 = 0) - Check Zero Flag
        operand1_in = 32'h0F0F0F0F;
        operand2_in = 32'hF0F0F0F0;
        alu_op_in = 4'b1011; // TST
        #10; `DISPLAY_ALU_RESULT

        // Test 11: MVI (MVI #123)
        operand1_in = 32'b0; // Rn ignored
        operand2_in = 32'd123; // Immediate value
        alu_op_in = 4'b1100; // MVI
        #10; `DISPLAY_ALU_RESULT

        // Test 12: LSL (0x1 << 4 = 0x10)
        operand1_in = 32'b0; // Not used for shift test directly
        operand2_in = 32'd1;
        alu_op_in = 4'b0101; // AND (or any op that uses shifted operand2)
        shift_type_in = 2'b00; // LSL
        shift_amt_in = 5'd4;
        #10; `DISPLAY_ALU_RESULT

        // Test 13: LSR (0x80 >> 4 = 0x8)
        operand2_in = 32'h80;
        shift_type_in = 2'b01; // LSR
        shift_amt_in = 5'd4;
        #10; `DISPLAY_ALU_RESULT

        // Test 14: ASR (signed -0x80000000 >>> 1 = -0x40000000)
        operand2_in = 32'h80000000; // MSB is 1, so negative
        shift_type_in = 2'b10; // ASR
        shift_amt_in = 5'd1;
        #10; `DISPLAY_ALU_RESULT

        // Test 15: ROR (0x12345678 ROR 4)
        operand2_in = 32'h12345678;
        shift_type_in = 2'b11; // ROR
        shift_amt_in = 5'd4;
        #10; `DISPLAY_ALU_RESULT

        // Test 16: ADD with Signed Overflow (Positive + Positive = Negative)
        operand1_in = 32'h7FFFFFFF; // Max positive signed int
        operand2_in = 32'd1;
        alu_op_in = 4'b0000; // ADD
        shift_type_in = 2'b00;
        shift_amt_in = 5'd0;
        alu_invert_operand2_in = 1'b0;
        #10; `DISPLAY_ALU_RESULT

        // Test 17: SUB with Signed Overflow (Negative - Positive = Positive)
        operand1_in = 32'h80000000; // Min negative signed int
        operand2_in = 32'd1;
        alu_op_in = 4'b0001; // SUB
        #10; `DISPLAY_ALU_RESULT


        $display("-----------------------------------------------------------------------------------------------------------------");
        $finish;
    end

endmodule

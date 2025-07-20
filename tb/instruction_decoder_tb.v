// instruction_decoder_tb.v
// Test bench for the instruction_decoder module.
// This TB verifies if the 32-bit instruction is correctly parsed into its fields.

`timescale 1ns / 1ps

module instruction_decoder_tb;

    // Inputs to the DUT (Device Under Test)
    reg [31:0] instruction_in;

    // Outputs from the DUT
    wire [3:0] cond_out;
    wire [4:0] opcode_out;
    wire [3:0] Rn_out;
    wire [3:0] Rm_out;
    wire [3:0] Rd_out;
    wire [10:0] imm_out;
    wire [1:0] shift_type_out;
    wire [4:0] shift_amt_out;

    // Instantiate the Device Under Test (DUT)
    instruction_decoder dut (
        .instruction(instruction_in),
        .cond(cond_out),
        .opcode(opcode_out),
        .Rn(Rn_out),
        .Rm(Rm_out),
        .Rd(Rd_out),
        .imm(imm_out),
        .shift_type(shift_type_out),
        .shift_amt(shift_amt_out)
    );

    initial begin
        // Dump waves for GTKWave
        $dumpfile("instruction_decoder_waves.vcd");
        $dumpvars(0, instruction_decoder_tb);

        $display("----------------------------------------------------------------------------------------------------");
        $display("Time | Instruction (Hex) | Cond | Opcode | Rn | Rm | Rd | Imm (Dec) | Shift Type | Shift Amt");
        $display("----------------------------------------------------------------------------------------------------");

        // Test Case 1: ADDI R1, R0, #10 (E680100A)
        // cond=1110 (AL), opcode=01101 (ADDI), Rn=0000 (R0), Rm=0000 (ignored), Rd=0001 (R1), imm=00000001010 (10)
        instruction_in = 32'hE680100A;
        #10;
        $display("%0t | %h            | %b   | %b     | %b | %b | %b | %0d       | %b        | %0d",
                 $time, instruction_in, cond_out, opcode_out, Rn_out, Rm_out, Rd_out, imm_out, shift_type_out, shift_amt_out);

        // Test Case 2: ADD R3, R1, R2 (E0213000) - Data Processing, no shift
        // cond=1110 (AL), opcode=00000 (ADD), Rn=0001 (R1), Rm=0010 (R2), Rd=0011 (R3), imm=0 (no shift)
        instruction_in = 32'hE0213000;
        #10;
        $display("%0t | %h            | %b   | %b     | %b | %b | %b | %0d       | %b        | %0d",
                 $time, instruction_in, cond_out, opcode_out, Rn_out, Rm_out, Rd_out, imm_out, shift_type_out, shift_amt_out);

        // Test Case 3: SUB R6, R3, R1, LSL #2 (E0636020) - Data Processing with Shift
        // cond=1110 (AL), opcode=00001 (SUB), Rn=0011 (R3), Rm=0001 (R1), Rd=0110 (R6)
        // imm[10:0] = 00000100000 (32) -> shift_type=00 (LSL), shift_amt=00010 (2)
        instruction_in = 32'hE0636020;
        #10;
        $display("%0t | %h            | %b   | %b     | %b | %b | %b | %0d       | %b        | %0d",
                 $time, instruction_in, cond_out, opcode_out, Rn_out, Rm_out, Rd_out, imm_out, shift_type_out, shift_amt_out);

        // Test Case 4: LDR R4, [R3, #4] (E9234004) - Load/Store
        // cond=1110 (AL), opcode=10010 (LDR), Rn=0011 (R3), Rm=0000 (ignored), Rd=0100 (R4), imm=00000000100 (4)
        instruction_in = 32'hE9234004;
        #10;
        $display("%0t | %h            | %b   | %b     | %b | %b | %b | %0d       | %b        | %0d",
                 $time, instruction_in, cond_out, opcode_out, Rn_out, Rm_out, Rd_out, imm_out, shift_type_out, shift_amt_out);

        // Test Case 5: B 0x00 (EA0007F7) - Branch
        // cond=1110 (AL), opcode=10100 (B), Rn/Rm/Rd ignored, imm=11111110111 (-9 signed)
        instruction_in = 32'hEA0007F7;
        #10;
        $display("%0t | %h            | %b   | %b     | %b | %b | %b | %0d       | %b        | %0d",
                 $time, instruction_in, cond_out, opcode_out, Rn_out, Rm_out, Rd_out, imm_out, shift_type_out, shift_amt_out);


        $display("----------------------------------------------------------------------------------------------------");
        $finish;
    end

endmodule

// instruction_decoder_tb.v
// Test bench for the instruction_decoder module.
// Verifies that the 32-bit instruction is correctly parsed into its fields.

`timescale 1ns / 1ps

module instruction_decoder_tb;

    // Inputs to the DUT (Device Under Test)
    reg [31:0] instruction;

    // Outputs from the DUT
    wire [3:0] cond;
    wire [4:0] opcode;
    wire [3:0] Rn;
    wire [3:0] Rm;
    wire [3:0] Rd;
    wire [10:0] imm;
    wire [1:0] shift_type;
    wire [4:0] shift_amt;

    // Instantiate the instruction_decoder module
    instruction_decoder dut (
        .instruction(instruction),
        .cond(cond),
        .opcode(opcode),
        .Rn(Rn),
        .Rm(Rm),
        .Rd(Rd),
        .imm(imm),
        .shift_type(shift_type),
        .shift_amt(shift_amt)
    );

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting instruction_decoder Test ---");
        $display("Time | Instruction | Cond | Opcode | Rn | Rm | Rd | Imm | Shift_Type | Shift_Amt");
        $display("----------------------------------------------------------------------------------");

        // Test Case 1: ADDI R1, R0, #10 (Example from instruction_memory)
        // Instruction: 1110_01101_0000_0000_0001_00000001010 = E680100A
        // Expected: Cond=1110 (E), Opcode=01101 (D), Rn=0000 (0), Rm=0000 (0), Rd=0001 (1), Imm=00000001010 (A)
        // Shift fields are part of Imm, but for ADDI, they are typically ignored (or 0)
        instruction = 32'hE680100A;
        #10;
        $display("%0t | %h | %h | %h | %h | %h | %h | %h | %h | %h",
                 $time, instruction, cond, opcode, Rn, Rm, Rd, imm, shift_type, shift_amt);

        // Test Case 2: ADD R3, R1, R2 (Data Processing, no shift)
        // Instruction: 1110_00000_0001_0010_0011_00000000000 = E0213000
        // Expected: Cond=1110 (E), Opcode=00000 (0), Rn=0001 (1), Rm=0010 (2), Rd=0011 (3), Imm=0 (0)
        instruction = 32'hE0213000;
        #10;
        $display("%0t | %h | %h | %h | %h | %h | %h | %h | %h | %h",
                 $time, instruction, cond, opcode, Rn, Rm, Rd, imm, shift_type, shift_amt);

        // Test Case 3: SUB R6, R3, R1, LSL #2 (Data Processing, with shift)
        // Instruction: 1110_00001_0011_0001_0110_00000100000 = E0636020
        // Expected: Cond=1110 (E), Opcode=00001 (1), Rn=0011 (3), Rm=0001 (1), Rd=0110 (6)
        // Imm=00000100000 (32), Shift_Type=00 (LSL), Shift_Amt=00010 (2)
        instruction = 32'hE0636020;
        #10;
        $display("%0t | %h | %h | %h | %h | %h | %h | %h | %h | %h",
                 $time, instruction, cond, opcode, Rn, Rm, Rd, imm, shift_type, shift_amt);

        // Test Case 4: LDR R4, [R3, #4] (Load/Store)
        // Instruction: 1110_10010_0011_0000_0100_00000000100 = E9234004
        // Expected: Cond=1110 (E), Opcode=10010 (12), Rn=0011 (3), Rm=0000 (0), Rd=0100 (4), Imm=00000000100 (4)
        instruction = 32'hE9234004;
        #10;
        $display("%0t | %h | %h | %h | %h | %h | %h | %h | %h | %h",
                 $time, instruction, cond, opcode, Rn, Rm, Rd, imm, shift_type, shift_amt);

        // Test Case 5: B 0x00 (Branch)
        // Instruction: 1110_10100_0000_0000_0000_11111110111 = EA0007F7
        // Expected: Cond=1110 (E), Opcode=10100 (14), Rn=0, Rm=0, Rd=0, Imm=11111110111 (-9)
        instruction = 32'hEA0007F7;
        #10;
        $display("%0t | %h | %h | %h | %h | %h | %h | %h | %h | %h",
                 $time, instruction, cond, opcode, Rn, Rm, Rd, imm, shift_type, shift_amt);

        $display("--- instruction_decoder Test Finished ---");
        $finish; // End simulation
    end

endmodule

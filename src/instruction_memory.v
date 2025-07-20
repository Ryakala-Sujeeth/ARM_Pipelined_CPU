// instruction_memory.v
// Simple instruction memory module for simulation purposes.
// In a real system, this would interface with an external memory.
// REVISED: Ensuring all 'reg' declarations are at the module level.

module instruction_memory (
    input wire [31:0] addr,     // 32-bit address from PC
    output reg [31:0] instr     // 32-bit instruction output
);

    // Memory array: 256 words of 32 bits each (declared at module level)
    reg [31:0] mem [0:255];

    initial begin
        integer i; // 'integer' is fine inside initial/always blocks
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'hE6000000; // NOP (MVI R0, 0)
        end

        // --- Test Program ---
        // All instructions are assumed to have condition code 'AL' (Always) = 4'b1110
        // Instruction Format: cond[31:28] | opcode[27:23] | Rn[22:19] | Rm[18:15] | Rd[14:11] | imm[10:0]

        // Address 0x00: ADDI R1, R0, #10  (R1 = 0 + 10 = 10)
        // Instruction: 1110_01101_0000_0000_0001_00000001010 = E680100A
        mem[0] = 32'hE680100A;

        // Address 0x04: ADDI R2, R0, #20  (R2 = 0 + 20 = 20)
        // Instruction: 1110_01101_0000_0000_0010_00000010100 = E6802014
        mem[4] = 32'hE6802014;

        // Address 0x08: ADD R3, R1, R2     (R3 = R1 + R2 = 10 + 20 = 30)
        // Instruction: 1110_00000_0001_0010_0011_00000000000 = E0213000
        mem[8] = 32'hE0213000;

        // Address 0x0C: LDR R4, [R3, #4]   (R4 = Mem[R3 + 4] = Mem[30 + 4] = Mem[34])
        // Instruction: 1110_10010_0011_0000_0100_00000000100 = E9234004
        // Assume mem[34] contains 32'hC0FFEE
        mem[34] = 32'hC0FFEE; // Set data memory at this address

        // Address 0x10: ADDI R5, R4, #1    (R5 = R4 + 1 = C0FFEE + 1 = C0FFEF) - Load-use hazard with LDR R4
        // Instruction: 1110_01101_0100_0000_0101_00000000001 = E6845001
        mem[16] = 32'hE6845001;

        // Address 0x14: STR R5, [R0, #8]   (Mem[8] = R5 = C0FFEF)
        // Instruction: 1110_10011_0000_0101_0000_00000001000 = E9600008
        mem[20] = 32'hE9600008;

        // Address 0x18: SUB R6, R3, R1, LSL #2 (R6 = R3 - (R1 << 2) = 30 - (10 << 2) = 30 - 40 = -10)
        // Instruction: 1110_00001_0011_0001_0110_00000100000 = E0636020
        mem[24] = 32'hE0636020;

        // Address 0x1C: B 0x00 (Branch back to start - infinite loop for observation)
        // Instruction: 1110_10100_0000_0000_0000_11111110111 = EA0007F7
        mem[28] = 32'hEA0007F7; // Branch to address 0x00
    end

    always @(addr) begin
        // Read instruction from memory at the given byte address.
        // Assuming word-aligned access, so divide address by 4 for word index.
        instr = mem[addr[31:2]]; // instr = mem[addr / 4]
    end

endmodule

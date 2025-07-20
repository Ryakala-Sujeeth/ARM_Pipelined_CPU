// instruction_decoder.v
// This module decodes a 32-bit instruction into its various fields
// based on the Unified Instruction Format provided in the ISA document.

module instruction_decoder (
    input wire [31:0] instruction, // The 32-bit input instruction

    // Output fields
    output wire [3:0] cond,        // Condition code [31:28]
    output wire [4:0] opcode,      // Opcode [27:23]
    output wire [3:0] Rn,          // Source register 1 [22:19]
    output wire [3:0] Rm,          // Source register 2 / Base register [18:15]
    output wire [3:0] Rd,          // Destination register [14:11]
    output wire [10:0] imm,        // 11-bit immediate / shift / offset field [10:0]

    // Shift-related fields (extracted from 'imm' when applicable)
    output wire [1:0] shift_type,  // Shift type (from imm[10:9])
    output wire [4:0] shift_amt    // Shift amount (from imm[8:4])
);

    // Assign the instruction fields directly based on the specified bit ranges.
    // This is a combinational logic, meaning outputs change immediately with inputs.

    assign cond = instruction[31:28];     // Condition code
    assign opcode = instruction[27:23];   // 5-bit opcode
    assign Rn = instruction[22:19];       // Source register 1
    assign Rm = instruction[18:15];       // Source register 2 or Base register
    assign Rd = instruction[14:11];       // Destination register
    assign imm = instruction[10:0];       // 11-bit immediate/shift/offset field

    // Extract shift-related fields from the 'imm' field.
    // These are only relevant for Data Processing (Register-to-Register) instructions.
    assign shift_type = imm[10:9];        // 2 bits for shift type (LSL, LSR, ASR, ROR)
    assign shift_amt = imm[8:4];         // 5 bits for shift amount

endmodule

// forwarding_unit.v
// This module detects data hazards and generates forwarding signals
// to bypass data from later pipeline stages (EX, MEM) to earlier ones (ID/EX).

module forwarding_unit (
    // Inputs from ID/EX register (current instruction's read registers)
    input wire [3:0] Rs1_idex,      // Read register 1 from ID/EX (Rn)
    input wire [3:0] Rs2_idex,      // Read register 2 from ID/EX (Rm)

    // Inputs from EX/MEM register (instruction currently in EX stage)
    input wire reg_write_en_exmem,  // RegWrite enable for EX/MEM instruction
    input wire [3:0] Rd_exmem,      // Destination register for EX/MEM instruction

    // Inputs from MEM/WB register (instruction currently in MEM stage)
    input wire reg_write_en_memwb,  // RegWrite enable for MEM/WB instruction
    input wire [3:0] Rd_memwb,      // Destination register for MEM/WB instruction

    // Outputs: Forwarding control signals
    // 00: No forwarding (read from register file)
    // 01: Forward from EX/MEM.ALU_Result
    // 10: Forward from MEM/WB.ALU_Result or MEM/WB.MemReadData
    output reg [1:0] forward_A,     // Forwarding for Rs1 (operand1)
    output reg [1:0] forward_B      // Forwarding for Rs2 (operand2)
);

    always @(*) begin
        // Default: No forwarding
        forward_A = 2'b00;
        forward_B = 2'b00;

        // Rule 1: EX/MEM hazard for Rs1 (Operand1)
        // If the instruction in EX/MEM writes to a register and that register
        // is the same as Rs1 (and not R0, which is typically hardwired to 0)
        // then forward from EX/MEM.
        if (reg_write_en_exmem && (Rd_exmem != 4'b0) && (Rd_exmem == Rs1_idex)) begin
            forward_A = 2'b01;
        end

        // Rule 2: EX/MEM hazard for Rs2 (Operand2)
        // Similar to Rule 1, but for Rs2.
        if (reg_write_en_exmem && (Rd_exmem != 4'b0) && (Rd_exmem == Rs2_idex)) begin
            forward_B = 2'b01;
        end

        // Rule 3: MEM/WB hazard for Rs1 (Operand1)
        // If the instruction in MEM/WB writes to a register and that register
        // is the same as Rs1 (and not R0), AND it's NOT already handled by EX/MEM,
        // then forward from MEM/WB.
        // Priority: EX/MEM has higher priority as its data is newer.
        if (reg_write_en_memwb && (Rd_memwb != 4'b0) && (Rd_memwb == Rs1_idex)) begin
            if (~(reg_write_en_exmem && (Rd_exmem != 4'b0) && (Rd_exmem == Rs1_idex))) begin
                forward_A = 2'b10;
            end
        end

        // Rule 4: MEM/WB hazard for Rs2 (Operand2)
        // Similar to Rule 3, but for Rs2.
        if (reg_write_en_memwb && (Rd_memwb != 4'b0) && (Rd_memwb == Rs2_idex)) begin
            if (~(reg_write_en_exmem && (Rd_exmem != 4'b0) && (Rd_exmem == Rs2_idex))) begin
                forward_B = 2'b10;
            end
        end
    end

endmodule

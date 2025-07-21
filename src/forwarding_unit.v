// forwarding_unit.v
// Detects data hazards and generates forwarding signals.
// REVISED: Simplified and corrected forwarding priority logic.

module forwarding_unit (
    // Inputs from ID/EX register (operands for current EX instruction)
    input wire [3:0] rn_idex, // Source register 1 from ID/EX
    input wire [3:0] rm_idex, // Source register 2 from ID/EX

    // Inputs from EX/MEM register
    input wire [3:0] rd_exmem,         // Destination register for EX/MEM instr
    input wire       reg_write_en_exmem, // RegWrite enable for EX/MEM instr

    // Inputs from MEM/WB register
    input wire [3:0] rd_memwb,         // Destination register for MEM/WB instr
    input wire       reg_write_en_memwb, // RegWrite enable for MEM/WB instr

    // Outputs: Forwarding control signals
    // 00: No forward
    // 01: Forward from EX/MEM result
    // 10: Forward from MEM/WB result
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

    always @(*) begin
        // --- Default: No forwarding ---
        forward_a = 2'b00;
        forward_b = 2'b00;

        // --- MEM/WB Stage Hazards ---
        // Check this stage first, as it's the oldest data.
        if (reg_write_en_memwb && (rd_memwb != 4'b0)) begin
            if (rd_memwb == rn_idex) begin
                forward_a = 2'b10; // Forward from MEM/WB to operand A
            end
            if (rd_memwb == rm_idex) begin
                forward_b = 2'b10; // Forward from MEM/WB to operand B
            end
        end

        // --- EX/MEM Stage Hazards ---
        // This has higher priority, so it can override the MEM/WB setting.
        if (reg_write_en_exmem && (rd_exmem != 4'b0)) begin
            if (rd_exmem == rn_idex) begin
                forward_a = 2'b01; // Forward from EX/MEM to operand A
            end
            if (rd_exmem == rm_idex) begin
                forward_b = 2'b01; // Forward from EX/MEM to operand B
            end
        end
    end

endmodule

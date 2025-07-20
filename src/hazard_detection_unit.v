// hazard_detection_unit.v
// This module detects load-use hazards and branch hazards,
// generating stall and flush signals for the pipeline.

module hazard_detection_unit (
    // Inputs from IF/ID (current instruction)
    input wire [4:0] opcode_ifid,   // Opcode of instruction in IF/ID stage
    input wire [3:0] Rn_ifid,       // Rn of instruction in IF/ID stage
    input wire [3:0] Rm_ifid,       // Rm of instruction in IF/ID stage

    // Inputs from ID/EX (previous instruction)
    input wire [4:0] opcode_idex,   // Opcode of instruction in ID/EX stage
    input wire [3:0] Rd_idex,       // Rd of instruction in ID/EX stage
    input wire mem_read_en_idex,    // MemRead enable for instruction in ID/EX stage

    // Inputs from EX/MEM (for branch hazard detection)
    input wire branch_taken_exmem,  // Final branch taken decision from EX/MEM

    // Outputs
    output reg pc_write_en,         // PC write enable for IF stage
    output reg if_id_write_en,      // IF/ID pipeline register write enable (stall)
    output reg id_ex_flush,         // ID/EX pipeline register flush (for branches)
    output reg ex_mem_flush         // EX/MEM pipeline register flush (for branches)
);

    // Internal flags for hazard detection
    reg load_use_hazard;
    reg branch_hazard;

    always @(*) begin
        // Default: no stall, no flush, PC writes normally
        pc_write_en = 1'b1;
        if_id_write_en = 1'b1;
        id_ex_flush = 1'b0;
        ex_mem_flush = 1'b0;

        // 1. Load-Use Hazard Detection
        // A load-use hazard occurs if:
        // - The instruction in ID/EX is a LOAD instruction (mem_read_en_idex is high)
        // - AND the destination register of that load (Rd_idex) is used as
        //   a source register (Rn or Rm) by the instruction in IF/ID.
        load_use_hazard = 1'b0;
        if (mem_read_en_idex) begin
            if ((Rd_idex != 4'b0) && ((Rd_idex == Rn_ifid) || (Rd_idex == Rm_ifid))) begin
                load_use_hazard = 1'b1;
            end
        end

        // If a load-use hazard is detected, stall the pipeline
        if (load_use_hazard) begin
            pc_write_en = 1'b0;     // Stop PC from incrementing
            if_id_write_en = 1'b0;  // Prevent IF/ID register from updating (stall IF stage)
            id_ex_flush = 1'b1;     // Flush the ID/EX register (insert bubble/NOP)
            // No need to flush EX/MEM or MEM/WB for load-use, as they are already past the hazard.
        end

        // 2. Branch Hazard Detection
        // A branch hazard occurs if the branch is taken in the EX/MEM stage.
        // This means the instructions already in IF and ID stages are incorrect.
        branch_hazard = branch_taken_exmem;

        if (branch_hazard) begin
            // When a branch is taken, we need to flush IF/ID and ID/EX.
            // The PC will be updated by the branch target from EX stage.
            pc_write_en = 1'b1;     // Allow PC to update to branch target
            if_id_write_en = 1'b0;  // Stall IF/ID to prevent new instruction from entering
            id_ex_flush = 1'b1;     // Flush ID/EX (insert NOP)
            // We also need to flush the EX/MEM stage if it contains an instruction
            // that should not have been executed due to the branch.
            ex_mem_flush = 1'b1;    // Flush EX/MEM (insert NOP)
        end
    end

endmodule

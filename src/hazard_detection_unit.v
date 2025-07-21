// hazard_detection_unit.v
// Detects load-use hazards and handles branch flushes.
// REVISED: Corrected stall logic for load-use and simplified branch handling.

module hazard_detection_unit (
    // Inputs for Load-Use Hazard
    input wire [3:0] rn_ifid,           // Rn from IF/ID (decoded in ID)
    input wire [3:0] rm_ifid,           // Rm from IF/ID (decoded in ID)
    input wire [3:0] rd_idex,           // Rd from ID/EX
    input wire       mem_read_en_idex,  // MemRead enable from ID/EX

    // Input for Branch Hazard
    input wire pc_src_ex, // Final branch-taken decision from EX stage

    // Outputs
    output reg pc_write_en,    // PC write enable
    output reg if_id_write_en, // IF/ID register write enable (stall)
    output reg id_ex_nop       // Control to insert a NOP in ID stage
);

    always @(*) begin
        // --- Default control signals ---
        pc_write_en    = 1'b1;
        if_id_write_en = 1'b1;
        id_ex_nop      = 1'b0;

        // --- 1. Load-Use Hazard Detection ---
        // Occurs if the instruction in ID/EX is a LOAD and its destination
        // is used by the instruction currently in the ID stage.
        if (mem_read_en_idex && (rd_idex != 4'b0) &&
           ((rd_idex == rn_ifid) || (rd_idex == rm_ifid)))
        begin
            // Stall the pipeline for one cycle
            pc_write_en    = 1'b0; // Freeze the PC
            if_id_write_en = 1'b0; // Freeze the IF/ID register
            id_ex_nop      = 1'b1; // Insert a bubble into ID/EX
        end

        // --- 2. Branch Hazard Detection ---
        // If a branch is taken (pc_src_ex == 1), the instruction in the
        // ID stage is incorrect and must be flushed (replaced with a NOP).
        if (pc_src_ex) begin
            id_ex_nop = 1'b1; // Flush the instruction in ID stage by turning it into a NOP
        end
    end

endmodule

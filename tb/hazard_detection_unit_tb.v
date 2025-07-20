// hazard_detection_unit_tb.v
// Test bench for the hazard_detection_unit module.
// Verifies if stall and flush signals are correctly generated.

`timescale 1ns / 1ps

module hazard_detection_unit_tb;

    // Inputs to the DUT
    reg [4:0] opcode_ifid_in;
    reg [3:0] Rn_ifid_in;
    reg [3:0] Rm_ifid_in;

    reg [4:0] opcode_idex_in;
    reg [3:0] Rd_idex_in;
    reg mem_read_en_idex_in;

    reg branch_taken_exmem_in;

    // Outputs from the DUT
    wire pc_write_en_out;
    wire if_id_write_en_out;
    wire id_ex_flush_out;
    wire ex_mem_flush_out;

    // Instantiate the DUT
    hazard_detection_unit dut (
        .opcode_ifid(opcode_ifid_in),
        .Rn_ifid(Rn_ifid_in),
        .Rm_ifid(Rm_ifid_in),
        .opcode_idex(opcode_idex_in),
        .Rd_idex(Rd_idex_in),
        .mem_read_en_idex(mem_read_en_idex_in),
        .branch_taken_exmem(branch_taken_exmem_in),
        .pc_write_en(pc_write_en_out),
        .if_id_write_en(if_id_write_en_out),
        .id_ex_flush(id_ex_flush_out),
        .ex_mem_flush(ex_mem_flush_out)
    );

    initial begin
        // Dump waves
        $dumpfile("hazard_detection_unit.vcd"); // Changed to .vcd for consistency
        $dumpvars(0, hazard_detection_unit_tb);

        $display("--------------------------------------------------------------------------------------------------------------------");
        $display("Time | Opcode_IFID | Rn_IFID | Rm_IFID | Opcode_IDEX | Rd_IDEX | MemRead_IDEX | BranchTaken_EXMEM | PC_WrEn | IFID_WrEn | IDEX_Flush | EXMEM_Flush");
        $display("--------------------------------------------------------------------------------------------------------------------");

        // Helper macro for displaying results
        `define DISPLAY_HAZARD_RESULT $display("%0t | %b          | %b      | %b      | %b          | %b      | %b           | %b                | %b       | %b         | %b         | %b", \
                                                $time, opcode_ifid_in, Rn_ifid_in, Rm_ifid_in, opcode_idex_in, Rd_idex_in, \
                                                mem_read_en_idex_in, branch_taken_exmem_in, pc_write_en_out, if_id_write_en_out, \
                                                id_ex_flush_out, ex_mem_flush_out);

        // Initialize all inputs to 0 (No Hazard)
        opcode_ifid_in = 5'b0;
        Rn_ifid_in = 4'b0;
        Rm_ifid_in = 4'b0;
        opcode_idex_in = 5'b0;
        Rd_idex_in = 4'b0;
        mem_read_en_idex_in = 1'b0;
        branch_taken_exmem_in = 1'b0;
        #10; `DISPLAY_HAZARD_RESULT

        // Test 1: No Hazard (Normal operation)
        opcode_ifid_in = 5'b00000; // ADD
        Rn_ifid_in = 4'd1;
        Rm_ifid_in = 4'd2;
        opcode_idex_in = 5'b01101; // ADDI
        Rd_idex_in = 4'd3;
        mem_read_en_idex_in = 1'b0;
        branch_taken_exmem_in = 1'b0;
        #10; `DISPLAY_HAZARD_RESULT

        // Test 2: Load-Use Hazard (LDR R1, [R0, #0]; ADD R2, R1, R3)
        // ID/EX: LDR R1 (Rd_IDEX = R1, mem_read_en_IDEX = 1)
        // IF/ID: ADD R2, R1, R3 (Rn_IFID = R1)
        opcode_ifid_in = 5'b00000; // ADD
        Rn_ifid_in = 4'd1;         // Uses R1
        Rm_ifid_in = 4'd3;
        opcode_idex_in = 5'b10010; // LDR
        Rd_idex_in = 4'd1;         // Writes to R1
        mem_read_en_idex_in = 1'b1; // Is a load
        branch_taken_exmem_in = 1'b0;
        #10; `DISPLAY_HAZARD_RESULT // Expect stall (PC_WrEn=0, IFID_WrEn=0, IDEX_Flush=1)

        // Test 3: Load-Use Hazard (LDR R1, [R0, #0]; ADD R2, R3, R1) - Rm hazard
        // ID/EX: LDR R1 (Rd_IDEX = R1, mem_read_en_IDEX = 1)
        // IF/ID: ADD R2, R3, R1 (Rm_IFID = R1)
        opcode_ifid_in = 5'b00000; // ADD
        Rn_ifid_in = 4'd3;
        Rm_ifid_in = 4'd1;         // Uses R1
        opcode_idex_in = 5'b10010; // LDR
        Rd_idex_in = 4'd1;         // Writes to R1
        mem_read_en_idex_in = 1'b1; // Is a load
        branch_taken_exmem_in = 1'b0;
        #10; `DISPLAY_HAZARD_RESULT // Expect stall

        // Test 4: Branch Taken Hazard (Branch taken in EX/MEM)
        // Assume a branch instruction was in EX/MEM and it was taken
        opcode_ifid_in = 5'b00000; // Some instruction already fetched
        Rn_ifid_in = 4'd1;
        Rm_ifid_in = 4'd2;
        opcode_idex_in = 5'b00000; // Some instruction in ID/EX
        Rd_idex_in = 4'd3;
        mem_read_en_idex_in = 1'b0;
        branch_taken_exmem_in = 1'b1; // Branch taken!
        #10; `DISPLAY_HAZARD_RESULT // Expect flush (IFID_WrEn=0, IDEX_Flush=1, EXMEM_Flush=1)

        // Test 5: No Hazard (Rd_IDEX is R0)
        opcode_ifid_in = 5'b00000; // ADD
        Rn_ifid_in = 4'd1;
        Rm_ifid_in = 4'd2;
        opcode_idex_in = 5'b10010; // LDR
        Rd_idex_in = 4'd0;         // Writes to R0 (no hazard)
        mem_read_en_idex_in = 1'b1;
        branch_taken_exmem_in = 1'b0;
        #10; `DISPLAY_HAZARD_RESULT // Expect no stall

        $display("--------------------------------------------------------------------------------------------------------------------");
        $finish;
    end

endmodule

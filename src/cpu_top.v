// cpu_top.v
// This module integrates all pipeline stages, registers, and hazard units
// to form a complete 5-stage pipelined CPU.
// REVISED: Corrected forwarding paths, hazard unit connections, and branch logic.

module cpu_top (
    input wire clk,   // Global clock signal
    input wire reset  // Global asynchronous reset
);

    // ---------------------------------------------------------------------
    // Internal Wires for Pipeline Stage Connections
    // ---------------------------------------------------------------------

    // IF Stage Outputs / IF/ID Register Inputs
    wire [31:0] pc_plus_4_if;
    wire [31:0] instr_if;

    // IF/ID Register Outputs / ID Stage Inputs
    wire [31:0] pc_plus_4_ifid;
    wire [31:0] instr_ifid;

    // Decoded register fields from ID stage (for hazard and forwarding units)
    wire [3:0] rn_ifid;
    wire [3:0] rm_ifid;
    wire [3:0] rd_idex;
    wire [3:0] rn_idex;
    wire [3:0] rm_idex;

    // ID Stage Outputs / ID/EX Register Inputs
    wire [31:0] pc_plus_4_id;
    wire [31:0] read_data1_id;
    wire [31:0] read_data2_id;
    wire [31:0] imm_ext_id;
    wire [3:0]  rd_id;
    wire [3:0]  rn_id;
    wire [3:0]  rm_id;
    wire [1:0]  shift_type_id;
    wire [4:0]  shift_amt_id;

    // Control signals from ID
    wire reg_write_en_id, mem_read_en_id, mem_write_en_id, mem_to_reg_id;
    wire alu_src_id, alu_invert_rm_id;
    wire [3:0] alu_op_id;
    wire branch_id; // Is it a branch instruction?

    // ID/EX Register Outputs / EX Stage Inputs
    wire [31:0] pc_plus_4_idex;
    wire [31:0] read_data1_idex;
    wire [31:0] read_data2_idex;
    wire [31:0] imm_ext_idex;
    // wire [3:0]  rd_idex; // Already declared above
    // wire [3:0]  rn_idex; // Already declared above
    // wire [3:0]  rm_idex; // Already declared above
    wire [1:0]  shift_type_idex;
    wire [4:0]  shift_amt_idex;

    wire reg_write_en_idex, mem_read_en_idex, mem_write_en_idex, mem_to_reg_idex;
    wire alu_src_idex, alu_invert_rm_idex;
    wire [3:0] alu_op_idex;
    wire branch_idex;

    // EX Stage Outputs / EX/MEM Register Inputs
    wire [31:0] alu_result_ex;
    wire [31:0] write_data_ex;
    wire [3:0]  rd_ex;
    wire        zero_flag_ex;
    wire [31:0] branch_target_ex;
    wire        pc_src_ex; // Final branch taken decision

    wire reg_write_en_ex, mem_read_en_ex, mem_write_en_ex, mem_to_reg_ex;

    // EX/MEM Register Outputs / MEM Stage Inputs
    wire [31:0] alu_result_exmem;
    wire [31:0] write_data_exmem;
    wire [3:0]  rd_exmem;

    wire reg_write_en_exmem, mem_read_en_exmem, mem_write_en_exmem, mem_to_reg_exmem;

    // MEM Stage Outputs / MEM/WB Register Inputs
    wire [31:0] mem_read_data_mem;
    wire [31:0] alu_result_mem;
    wire [3:0]  rd_mem;

    wire reg_write_en_mem, mem_to_reg_mem;

    // MEM/WB Register Outputs / WB Stage Inputs
    wire [31:0] write_data_wb;
    wire [3:0]  rd_memwb;
    wire        reg_write_en_memwb;

    // Hazard Unit Outputs
    wire pc_write_en_hzd;
    wire if_id_write_en_hzd;
    wire id_ex_nop_hzd;

    // Forwarding Unit Outputs
    wire [1:0] forward_a_ex;
    wire [1:0] forward_b_ex;

    // ---------------------------------------------------------------------
    // Stage Instantiations
    // ---------------------------------------------------------------------

    // IF STAGE
    if_stage if_s (
        .clk(clk),
        .reset(reset),
        .pc_write_en(pc_write_en_hzd),
        .pc_src(pc_src_ex),
        .branch_target_addr(branch_target_ex),
        .pc_plus_4_out(pc_plus_4_if),
        .instr_out(instr_if)
    );

    // IF/ID REGISTER
    if_id_reg if_id_r (
        .clk(clk),
        .reset(reset),
        .enable(if_id_write_en_hzd),
        .pc_plus_4_in(pc_plus_4_if),
        .instr_in(instr_if),
        .pc_plus_4_out(pc_plus_4_ifid),
        .instr_out(instr_ifid)
    );

    // ID STAGE
    id_stage id_s (
        .clk(clk),
        .reset(reset),
        .instr_in_ifid(instr_ifid),
        .pc_plus_4_in_ifid(pc_plus_4_ifid),
        .reg_write_en_wb(reg_write_en_memwb),
        .write_reg_addr_wb(rd_memwb),
        .write_data_wb(write_data_wb),
        .id_ex_nop(id_ex_nop_hzd),
        .pc_plus_4_out(pc_plus_4_id),
        .read_data1_out(read_data1_id),
        .read_data2_out(read_data2_id),
        .imm_ext_out(imm_ext_id),
        .rd_out(rd_id),
        .rn_out(rn_id),
        .rm_out(rm_id),
        .shift_type_out(shift_type_id),
        .shift_amt_out(shift_amt_id),
        .reg_write_en_out(reg_write_en_id),
        .mem_read_en_out(mem_read_en_id),
        .mem_write_en_out(mem_write_en_id),
        .mem_to_reg_out(mem_to_reg_id),
        .alu_src_out(alu_src_id),
        .alu_invert_rm_out(alu_invert_rm_id),
        .alu_op_out(alu_op_id),
        .branch_out(branch_id),
        .rn_ifid_out(rn_ifid), // Pass Rn to hazard unit
        .rm_ifid_out(rm_ifid)  // Pass Rm to hazard unit
    );

    // ID/EX REGISTER
    id_ex_reg id_ex_r (
        .clk(clk),
        .reset(reset),
        .enable(1'b1), // This register is now controlled by id_ex_nop in the ID stage
        .pc_plus_4_in(pc_plus_4_id),
        .read_data1_in(read_data1_id),
        .read_data2_in(read_data2_id),
        .imm_ext_in(imm_ext_id),
        .rd_in(rd_id),
        .rn_in(rn_id),
        .rm_in(rm_id),
        .shift_type_in(shift_type_id),
        .shift_amt_in(shift_amt_id),
        .reg_write_en_in(reg_write_en_id),
        .mem_read_en_in(mem_read_en_id),
        .mem_write_en_in(mem_write_en_id),
        .mem_to_reg_in(mem_to_reg_id),
        .alu_src_in(alu_src_id),
        .alu_invert_rm_in(alu_invert_rm_id),
        .alu_op_in(alu_op_id),
        .branch_in(branch_id),
        .pc_plus_4_out(pc_plus_4_idex),
        .read_data1_out(read_data1_idex),
        .read_data2_out(read_data2_idex),
        .imm_ext_out(imm_ext_idex),
        .rd_out(rd_idex),
        .rn_out(rn_idex),
        .rm_out(rm_idex),
        .shift_type_out(shift_type_idex),
        .shift_amt_out(shift_amt_idex),
        .reg_write_en_out(reg_write_en_idex),
        .mem_read_en_out(mem_read_en_idex),
        .mem_write_en_out(mem_write_en_idex),
        .mem_to_reg_out(mem_to_reg_idex),
        .alu_src_out(alu_src_idex),
        .alu_invert_rm_out(alu_invert_rm_idex),
        .alu_op_out(alu_op_idex),
        .branch_out(branch_idex)
    );

    // EX STAGE
    ex_stage ex_s (
        .clk(clk),
        .reset(reset),
        .pc_plus_4_in(pc_plus_4_idex),
        .read_data1_in(read_data1_idex),
        .read_data2_in(read_data2_idex),
        .imm_ext_in(imm_ext_idex),
        .rd_in(rd_idex),
        .rn_in(rn_idex),
        .rm_in(rm_idex),
        .shift_type_in(shift_type_idex),
        .shift_amt_in(shift_amt_idex),
        .forward_a(forward_a_ex),
        .forward_b(forward_b_ex),
        .alu_result_exmem(alu_result_exmem),
        .write_data_wb(write_data_wb),
        .reg_write_en_in(reg_write_en_idex),
        .mem_read_en_in(mem_read_en_idex),
        .mem_write_en_in(mem_write_en_idex),
        .mem_to_reg_in(mem_to_reg_idex),
        .alu_src_in(alu_src_idex),
        .alu_invert_rm_in(alu_invert_rm_idex),
        .alu_op_in(alu_op_idex),
        .branch_in(branch_idex),
        .alu_result_out(alu_result_ex),
        .write_data_out(write_data_ex),
        .rd_out(rd_ex),
        .zero_flag_out(zero_flag_ex),
        .branch_target_out(branch_target_ex),
        .pc_src_out(pc_src_ex),
        .reg_write_en_out(reg_write_en_ex),
        .mem_read_en_out(mem_read_en_ex),
        .mem_write_en_out(mem_write_en_ex),
        .mem_to_reg_out(mem_to_reg_ex)
    );

    // EX/MEM REGISTER
    ex_mem_reg ex_mem_r (
        .clk(clk),
        .reset(reset),
        .alu_result_in(alu_result_ex),
        .write_data_in(write_data_ex),
        .rd_in(rd_ex),
        .reg_write_en_in(reg_write_en_ex),
        .mem_read_en_in(mem_read_en_ex),
        .mem_write_en_in(mem_write_en_ex),
        .mem_to_reg_in(mem_to_reg_ex),
        .alu_result_out(alu_result_exmem),
        .write_data_out(write_data_exmem),
        .rd_out(rd_exmem),
        .reg_write_en_out(reg_write_en_exmem),
        .mem_read_en_out(mem_read_en_exmem),
        .mem_write_en_out(mem_write_en_exmem),
        .mem_to_reg_out(mem_to_reg_exmem)
    );

    // MEM STAGE
    mem_stage mem_s (
        .clk(clk),
        .reset(reset),
        .alu_result_in(alu_result_exmem),
        .write_data_in(write_data_exmem),
        .rd_in(rd_exmem),
        .reg_write_en_in(reg_write_en_exmem),
        .mem_read_en_in(mem_read_en_exmem),
        .mem_write_en_in(mem_write_en_exmem), // Corrected typo
        .mem_to_reg_in(mem_to_reg_exmem),
        .mem_read_data_out(mem_read_data_mem),
        .alu_result_out(alu_result_mem),
        .rd_out(rd_mem),
        .reg_write_en_out(reg_write_en_mem),
        .mem_to_reg_out(mem_to_reg_mem)
    );

    // MEM/WB REGISTER
    mem_wb_reg mem_wb_r (
        .clk(clk),
        .reset(reset),
        .mem_read_data_in(mem_read_data_mem),
        .alu_result_in(alu_result_mem),
        .rd_in(rd_mem),
        .reg_write_en_in(reg_write_en_mem),
        .mem_to_reg_in(mem_to_reg_mem),
        .write_data_out(write_data_wb),
        .rd_out(rd_memwb),
        .reg_write_en_out(reg_write_en_memwb)
    );

    // HAZARD DETECTION UNIT
    hazard_detection_unit hdu (
        .rn_ifid(rn_ifid), // From ID stage
        .rm_ifid(rm_ifid), // From ID stage
        .rd_idex(rd_idex),
        .mem_read_en_idex(mem_read_en_idex),
        .pc_src_ex(pc_src_ex),
        .pc_write_en(pc_write_en_hzd),
        .if_id_write_en(if_id_write_en_hzd),
        .id_ex_nop(id_ex_nop_hzd)
    );

    // FORWARDING UNIT
    forwarding_unit fwd_unit (
        .rn_idex(rn_idex),
        .rm_idex(rm_idex),
        .rd_exmem(rd_exmem),
        .reg_write_en_exmem(reg_write_en_exmem),
        .rd_memwb(rd_memwb),
        .reg_write_en_memwb(reg_write_en_memwb),
        .forward_a(forward_a_ex),
        .forward_b(forward_b_ex)
    );

endmodule

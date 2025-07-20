// cpu_top.v
// This module integrates all pipeline stages, registers, and hazard units
// to form a complete 5-stage pipelined CPU.

module cpu_top (
    input wire clk,    // Global clock signal
    input wire reset   // Global asynchronous reset
);

    // ---------------------------------------------------------------------
    // Internal Wires for Pipeline Stage Connections
    // ---------------------------------------------------------------------

    // IF Stage Outputs / IF/ID Register Inputs
    wire [31:0] pc_if;
    wire [31:0] instr_if;
    wire [31:0] imem_addr_if;
    wire [31:0] imem_rdata_if;

    // IF/ID Register Outputs / ID Stage Inputs
    wire [31:0] pc_ifid;
    wire [31:0] instr_ifid;

    // ID Stage Outputs / ID/EX Register Inputs
    wire [31:0] pc_id;
    wire [4:0] opcode_id;
    wire [3:0] cond_id;
    wire [31:0] read_data1_id;
    wire [31:0] read_data2_id;
    wire [10:0] imm_id;
    wire [3:0] Rd_id;
    wire [1:0] shift_type_id;
    wire [4:0] shift_amt_id;

    wire reg_write_en_id;
    wire mem_read_en_id;
    wire mem_write_en_id;
    wire alu_src_id;
    wire [3:0] alu_op_id;
    wire alu_invert_rm_id;
    wire mem_to_reg_id;
    wire branch_taken_id;
    wire [31:0] branch_target_addr_id;

    // ID/EX Register Outputs / EX Stage Inputs
    wire [31:0] pc_idex;
    wire [4:0] opcode_idex;
    wire [3:0] cond_idex;
    wire [31:0] read_data1_idex;
    wire [31:0] read_data2_idex;
    wire [10:0] imm_idex;
    wire [3:0] Rd_idex;
    wire [1:0] shift_type_idex;
    wire [4:0] shift_amt_idex;

    wire reg_write_en_idex;
    wire mem_read_en_idex;
    wire mem_write_en_idex;
    wire alu_src_idex;
    wire [3:0] alu_op_idex;
    wire alu_invert_rm_idex;
    wire mem_to_reg_idex;
    wire branch_taken_idex;
    wire [31:0] branch_target_addr_idex;

    // EX Stage Outputs / EX/MEM Register Inputs
    wire [31:0] pc_ex;
    wire [31:0] alu_result_ex;
    wire [31:0] write_data_ex; // Data to write to memory (Rm)
    wire [3:0] Rd_ex;
    wire [4:0] opcode_ex;
    wire [3:0] cond_ex;

    wire reg_write_en_ex;
    wire mem_read_en_ex;
    wire mem_write_en_ex;
    wire mem_to_reg_ex;
    wire branch_taken_ex;
    wire [31:0] branch_target_addr_ex;

    // EX/MEM Register Outputs / MEM Stage Inputs
    wire [31:0] pc_exmem;
    wire [31:0] alu_result_exmem;
    wire [31:0] write_data_exmem;
    wire [3:0] Rd_exmem;
    wire [4:0] opcode_exmem;
    wire [3:0] cond_exmem;

    wire reg_write_en_exmem;
    wire mem_read_en_exmem;
    wire mem_write_en_exmem;
    wire mem_to_reg_exmem;
    wire branch_taken_exmem;
    wire [31:0] branch_target_addr_exmem;

    // MEM Stage Outputs / MEM/WB Register Inputs
    wire [31:0] pc_mem;
    wire [31:0] alu_result_mem;
    wire [31:0] mem_read_data_mem;
    wire [3:0] Rd_mem;
    wire [4:0] opcode_mem;

    wire reg_write_en_mem;
    wire mem_to_reg_mem;

    // MEM/WB Register Outputs / WB Stage Inputs
    wire [31:0] pc_memwb;
    wire [31:0] alu_result_memwb;
    wire [31:0] mem_read_data_memwb;
    wire [3:0] Rd_memwb;
    wire [4:0] opcode_memwb;

    wire reg_write_en_memwb;
    wire mem_to_reg_memwb;

    // WB Stage Outputs (to Register File in ID stage)
    wire reg_write_en_wb;
    wire [3:0] write_reg_addr_wb;
    wire [31:0] write_data_wb;

    // Hazard Unit Outputs
    wire pc_write_en_hzd;
    wire if_id_write_en_hzd;
    wire id_ex_flush_hzd;
    wire ex_mem_flush_hzd;

    // Forwarding Unit Outputs
    wire [1:0] forward_A_fwd;
    wire [1:0] forward_B_fwd;

    // ---------------------------------------------------------------------
    // Muxes for Forwarding Data to EX Stage (defined here in cpu_top)
    // ---------------------------------------------------------------------
    wire [31:0] forwarded_read_data1;
    wire [31:0] forwarded_read_data2;

    // Forwarding for Operand1 (Rn)
    assign forwarded_read_data1 = (forward_A_fwd == 2'b00) ? read_data1_idex :
                                  (forward_A_fwd == 2'b01) ? alu_result_ex : // From EX/MEM ALU result
                                  (forward_A_fwd == 2'b10) ? (mem_to_reg_memwb ? mem_read_data_memwb : alu_result_memwb) : // From MEM/WB (ALU or Mem)
                                  32'b0; // Should not happen

    // Forwarding for Operand2 (Rm)
    assign forwarded_read_data2 = (forward_B_fwd == 2'b00) ? read_data2_idex :
                                  (forward_B_fwd == 2'b01) ? alu_result_ex : // From EX/MEM ALU result
                                  (forward_B_fwd == 2'b10) ? (mem_to_reg_memwb ? mem_read_data_memwb : alu_result_memwb) : // From MEM/WB (ALU or Mem)
                                  32'b0; // Should not happen

    // ---------------------------------------------------------------------
    // Instantiation of Modules
    // ---------------------------------------------------------------------

    // Instruction Memory
    instruction_memory imem (
        .addr(imem_addr_if),
        .instr(imem_rdata_if)
    );

    // Data Memory
    data_memory dmem (
        .clk(clk),
        .reset(reset),
        .mem_read_en(mem_read_en_exmem),   // Control from EX/MEM
        .mem_write_en(mem_write_en_exmem), // Control from EX/MEM
        .addr(alu_result_exmem),           // Address from EX/MEM
        .write_data(write_data_exmem),     // Data to write from EX/MEM
        .read_data(mem_read_data_mem)      // Data read from memory
    );

    // IF Stage
    if_stage if_s (
        .clk(clk),
        .reset(reset),
        .pc_write_en(pc_write_en_hzd), // Controlled by Hazard Unit
        .branch_target_addr(branch_target_addr_ex), // Branch target from EX stage
        .pc_out_ifid(pc_if),
        .instr_out_ifid(instr_if),
        .imem_addr(imem_addr_if),
        .imem_rdata(imem_rdata_if)
    );

    // IF/ID Pipeline Register
    if_id_reg if_id_r (
        .clk(clk),
        .reset(reset),
        .enable(if_id_write_en_hzd), // Controlled by Hazard Unit (stall)
        .pc_in(pc_if),
        .instr_in(instr_if),
        .pc_out(pc_ifid),
        .instr_out(instr_ifid)
    );

    // ID Stage
    id_stage id_s (
        .clk(clk),
        .reset(reset),
        .enable(~id_ex_flush_hzd), // Flush control from Hazard Unit (insert NOP)
        .pc_in_ifid(pc_ifid),
        .instr_in_ifid(instr_ifid),
        .reg_write_en_wb(reg_write_en_wb),     // From WB stage
        .write_reg_addr_wb(write_reg_addr_wb), // From WB stage
        .write_data_wb(write_data_wb),         // From WB stage
        .branch_target_addr_out_if(branch_target_addr_id), // To IF stage
        .branch_taken_out_if(branch_taken_id),           // To IF stage
        .pc_out_idex(pc_id),
        .opcode_out_idex(opcode_id),
        .cond_out_idex(cond_id),
        .read_data1_out_idex(read_data1_id),
        .read_data2_out_idex(read_data2_id),
        .imm_out_idex(imm_id),
        .Rd_out_idex(Rd_id),
        .shift_type_out_idex(shift_type_id),
        .shift_amt_out_idex(shift_amt_id),
        .reg_write_en_out_idex(reg_write_en_id),
        .mem_read_en_out_idex(mem_read_en_id),
        .mem_write_en_out_idex(mem_write_en_id),
        .alu_src_out_idex(alu_src_id),
        .alu_op_out_idex(alu_op_id),
        .alu_invert_rm_out_idex(alu_invert_rm_id),
        .mem_to_reg_out_idex(mem_to_reg_id),
        .branch_taken_out_idex(branch_taken_id),
        .branch_target_addr_out_idex(branch_target_addr_id)
    );

    // ID/EX Pipeline Register
    id_ex_reg id_ex_r (
        .clk(clk),
        .reset(reset),
        .enable(~id_ex_flush_hzd), // Flush control from Hazard Unit (insert NOP)
        .pc_in(pc_id),
        .opcode_in(opcode_id),
        .cond_in(cond_id),
        .read_data1_in(read_data1_id),
        .read_data2_in(read_data2_id),
        .imm_in(imm_id),
        .Rd_in(Rd_id),
        .shift_type_in(shift_type_id),
        .shift_amt_in(shift_amt_id),
        .reg_write_en_in(reg_write_en_id),
        .mem_read_en_in(mem_read_en_id),
        .mem_write_en_in(mem_write_en_id),
        .alu_src_in(alu_src_id),
        .alu_op_in(alu_op_id),
        .alu_invert_rm_in(alu_invert_rm_id),
        .mem_to_reg_in(mem_to_reg_id),
        .branch_taken_in(branch_taken_id),
        .branch_target_addr_in(branch_target_addr_id),
        .pc_out(pc_idex),
        .opcode_out(opcode_idex),
        .cond_out(cond_idex),
        .read_data1_out(read_data1_idex),
        .read_data2_out(read_data2_idex),
        .imm_out(imm_idex),
        .Rd_out(Rd_idex),
        .shift_type_out(shift_type_idex),
        .shift_amt_out(shift_amt_idex),
        .reg_write_en_out(reg_write_en_idex),
        .mem_read_en_out(mem_read_en_idex),
        .mem_write_en_out(mem_write_en_idex),
        .alu_src_out(alu_src_idex),
        .alu_op_out(alu_op_idex),
        .alu_invert_rm_out(alu_invert_rm_idex),
        .mem_to_reg_out(mem_to_reg_idex),
        .branch_taken_out(branch_taken_idex),
        .branch_target_addr_out(branch_target_addr_idex)
    );

    // EX Stage
    ex_stage ex_s (
        .clk(clk),
        .reset(reset),
        .enable(~ex_mem_flush_hzd), // Flush control from Hazard Unit (insert NOP)
        .pc_in_idex(pc_idex),
        .opcode_in_idex(opcode_idex),
        .cond_in_idex(cond_idex),
        .read_data1_in_idex(read_data1_idex), // Original read data (not used directly by ALU now)
        .read_data2_in_idex(read_data2_idex), // Original read data (not used directly by ALU now)
        .imm_in_idex(imm_idex),
        .Rd_in_idex(Rd_idex),
        .shift_type_in_idex(shift_type_idex),
        .shift_amt_in_idex(shift_amt_idex),
        // NEW: Connect forwarded data to EX stage
        .forwarded_read_data1_in(forwarded_read_data1),
        .forwarded_read_data2_in(forwarded_read_data2),
        .reg_write_en_in_idex(reg_write_en_idex),
        .mem_read_en_in_idex(mem_read_en_idex),
        .mem_write_en_in_idex(mem_write_en_idex),
        .alu_src_in_idex(alu_src_idex),
        .alu_op_in_idex(alu_op_idex),
        .alu_invert_rm_in_idex(alu_invert_rm_idex),
        .mem_to_reg_in_idex(mem_to_reg_idex),
        .branch_taken_in_idex(branch_taken_idex),
        .branch_target_addr_in_idex(branch_target_addr_idex),
        .branch_target_addr_out_if(branch_target_addr_ex), // To IF stage
        .branch_taken_out_if(branch_taken_ex),           // To IF stage
        .pc_out_exmem(pc_ex),
        .alu_result_out_exmem(alu_result_ex),
        .write_data_out_exmem(write_data_ex),
        .Rd_out_exmem(Rd_ex),
        .opcode_out_exmem(opcode_ex),
        .cond_out_exmem(cond_ex),
        .reg_write_en_out_exmem(reg_write_en_ex),
        .mem_read_en_out_exmem(mem_read_en_ex),
        .mem_write_en_out_exmem(mem_write_en_ex),
        .mem_to_reg_out_exmem(mem_to_reg_ex),
        .branch_taken_out_exmem(branch_taken_ex),
        .branch_target_addr_out_exmem(branch_target_addr_ex)
    );

    // EX/MEM Pipeline Register
    ex_mem_reg ex_mem_r (
        .clk(clk),
        .reset(reset),
        .enable(1'b1), // Always enabled unless specific stall logic is added here
        .pc_in(pc_ex),
        .alu_result_in(alu_result_ex),
        .write_data_in(write_data_ex),
        .Rd_in(Rd_ex),
        .opcode_in(opcode_ex),
        .cond_in(cond_ex),
        .reg_write_en_in(reg_write_en_ex),
        .mem_read_en_in(mem_read_en_ex),
        .mem_write_en_in(mem_write_en_ex),
        .mem_to_reg_in(mem_to_reg_ex),
        .branch_taken_in(branch_taken_ex),
        .branch_target_addr_in(branch_target_addr_ex),
        .pc_out(pc_exmem),
        .alu_result_out(alu_result_exmem),
        .write_data_out(write_data_exmem),
        .Rd_out(Rd_exmem),
        .opcode_out(opcode_exmem),
        .cond_out(cond_exmem),
        .reg_write_en_out(reg_write_en_exmem),
        .mem_read_en_out(mem_read_en_exmem),
        .mem_write_en_out(mem_write_en_exmem),
        .mem_to_reg_out(mem_to_reg_exmem),
        .branch_taken_out(branch_taken_exmem),
        .branch_target_addr_out(branch_target_addr_exmem)
    );

    // MEM Stage
    mem_stage mem_s (
        .clk(clk),
        .reset(reset),
        .enable(1'b1), // Always enabled unless specific stall logic is added here
        .pc_in_exmem(pc_exmem),
        .alu_result_in_exmem(alu_result_exmem),
        .write_data_in_exmem(write_data_exmem),
        .Rd_in_exmem(Rd_exmem),
        .opcode_in_exmem(opcode_exmem),
        .reg_write_en_in_exmem(reg_write_en_exmem),
        .mem_read_en_in_exmem(mem_read_en_exmem),
        .mem_write_en_en_exmem(mem_write_en_exmem),
        .mem_to_reg_in_exmem(mem_to_reg_exmem),
        .dmem_addr(dmem_addr_mem),
        .dmem_wdata(dmem_wdata_mem),
        .dmem_read_en(dmem_read_en_mem),
        .dmem_write_en(dmem_write_en_mem),
        .dmem_rdata(dmem_rdata_mem),
        .pc_out_memwb(pc_mem),
        .alu_result_out_memwb(alu_result_mem),
        .mem_read_data_out_memwb(mem_read_data_mem),
        .Rd_out_memwb(Rd_mem),
        .opcode_out_memwb(opcode_mem),
        .reg_write_en_out_memwb(reg_write_en_mem),
        .mem_to_reg_out_memwb(mem_to_reg_mem)
    );

    // MEM/WB Pipeline Register
    mem_wb_reg mem_wb_r (
        .clk(clk),
        .reset(reset),
        .enable(1'b1), // Always enabled unless specific stall logic is added here
        .pc_in(pc_mem),
        .alu_result_in(alu_result_mem),
        .mem_read_data_in(mem_read_data_mem),
        .Rd_in(Rd_mem),
        .opcode_in(opcode_mem),
        .reg_write_en_in(reg_write_en_mem),
        .mem_to_reg_in(mem_to_reg_mem),
        .pc_out(pc_memwb),
        .alu_result_out(alu_result_memwb),
        .mem_read_data_out(mem_read_data_memwb),
        .Rd_out(Rd_memwb),
        .opcode_out(opcode_memwb),
        .reg_write_en_out(reg_write_en_memwb),
        .mem_to_reg_out(mem_to_reg_memwb)
    );

    // WB Stage
    wb_stage wb_s (
        .clk(clk),
        .reset(reset),
        .enable(1'b1), // Always enabled unless specific stall logic is added here
        .pc_in_memwb(pc_memwb),
        .alu_result_in_memwb(alu_result_memwb),
        .mem_read_data_in_memwb(mem_read_data_memwb),
        .Rd_in_memwb(Rd_memwb),
        .opcode_in_memwb(opcode_memwb),
        .reg_write_en_in_memwb(reg_write_en_memwb),
        .mem_to_reg_in_memwb(mem_to_reg_memwb),
        .reg_write_en_out_rf(reg_write_en_wb),
        .write_reg_addr_out_rf(write_reg_addr_wb),
        .write_data_out_rf(write_data_wb)
    );

    // ---------------------------------------------------------------------
    // Hazard Detection Unit Instantiation
    // ---------------------------------------------------------------------
    hazard_detection_unit hdu (
        .opcode_ifid(instr_ifid[27:23]), // Opcode of instruction in IF/ID
        .Rn_ifid(instr_ifid[22:19]),     // Rn of instruction in IF/ID
        .Rm_ifid(instr_ifid[18:15]),     // Rm of instruction in IF/ID
        .opcode_idex(opcode_idex),       // Opcode of instruction in ID/EX
        .Rd_idex(Rd_idex),               // Rd of instruction in ID/EX
        .mem_read_en_idex(mem_read_en_idex), // MemRead enable for instruction in ID/EX
        .branch_taken_exmem(branch_taken_ex), // Final branch taken decision from EX stage
        .pc_write_en(pc_write_en_hzd),
        .if_id_write_en(if_id_write_en_hzd),
        .id_ex_flush(id_ex_flush_hzd),
        .ex_mem_flush(ex_mem_flush_hzd)
    );

    // ---------------------------------------------------------------------
    // Forwarding Unit Instantiation
    // ---------------------------------------------------------------------
    forwarding_unit fwd_unit (
        .Rs1_idex(instr_ifid[22:19]), // Rn of instruction in ID stage (from IF/ID)
        .Rs2_idex(instr_ifid[18:15]), // Rm of instruction in ID stage (from IF/ID)
        .reg_write_en_exmem(reg_write_en_exmem), // RegWrite from EX/MEM
        .Rd_exmem(Rd_exmem),                     // Rd from EX/MEM
        .reg_write_en_memwb(reg_write_en_memwb), // RegWrite from MEM/WB
        .Rd_memwb(Rd_memwb),                     // Rd from MEM/WB
        .forward_A(forward_A_fwd),
        .forward_B(forward_B_fwd)
    );

    // ---------------------------------------------------------------------
    // Connect forwarded data to EX stage inputs
    // ---------------------------------------------------------------------
    // This is where the forwarded data is actually passed to the EX stage.
    assign ex_s.forwarded_read_data1_in = forwarded_read_data1;
    assign ex_s.forwarded_read_data2_in = forwarded_read_data2;

endmodule

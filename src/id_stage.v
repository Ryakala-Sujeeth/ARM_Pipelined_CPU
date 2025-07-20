// id_stage.v
// This module implements the Instruction Decode stage of the pipeline.
// It decodes the instruction, reads operands from the register file,
// and generates control signals for subsequent stages.

module id_stage (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from IF/ID pipeline register
    input wire [31:0] pc_in_ifid,        // PC value from IF/ID register
    input wire [31:0] instr_in_ifid,     // Instruction from IF/ID register

    // Inputs from WB stage (for write-back to register file)
    input wire reg_write_en_wb,         // Register write enable from WB stage
    input wire [3:0] write_reg_addr_wb, // Register address to write to from WB stage
    input wire [31:0] write_data_wb,    // Data to write from WB stage

    // Outputs to IF stage (for branch target)
    output wire [31:0] branch_target_addr_out_if, // Branch target address to IF stage
    output wire branch_taken_out_if,             // Branch taken signal to IF stage

    // Outputs to ID/EX pipeline register
    output wire [31:0] pc_out_idex,
    output wire [4:0] opcode_out_idex,
    output wire [3:0] cond_out_idex,
    output wire [31:0] read_data1_out_idex,
    output wire [31:0] read_data2_out_idex,
    output wire [10:0] imm_out_idex,
    output wire [3:0] Rd_out_idex,
    output wire [1:0] shift_type_out_idex, // Shift type for data processing
    output wire [4:0] shift_amt_out_idex,  // Shift amount for data processing

    // Control signals to ID/EX pipeline register
    output wire reg_write_en_out_idex,
    output wire mem_read_en_out_idex,
    output wire mem_write_en_out_idex,
    output wire alu_src_out_idex,
    output wire [3:0] alu_op_out_idex, // ALU operation type (now 4-bit)
    output wire alu_invert_rm_out_idex, // Control: Invert Rm for BIC
    output wire mem_to_reg_out_idex,
    output wire branch_taken_out_idex,
    output wire [31:0] branch_target_addr_out_idex
);

    // Wires for decoded instruction fields
    wire [3:0] cond_decoded;
    wire [4:0] opcode_decoded;
    wire [3:0] Rn_decoded;
    wire [3:0] Rm_decoded;
    wire [3:0] Rd_decoded;
    wire [10:0] imm_decoded;
    wire [1:0] shift_type_decoded;
    wire [4:0] shift_amt_decoded;

    // Instantiate the instruction decoder
    instruction_decoder decoder (
        .instruction(instr_in_ifid),
        .cond(cond_decoded),
        .opcode(opcode_decoded),
        .Rn(Rn_decoded),
        .Rm(Rm_decoded),
        .Rd(Rd_decoded),
        .imm(imm_decoded),
        .shift_type(shift_type_decoded),
        .shift_amt(shift_amt_decoded)
    );

    // Wires for data read from register file
    wire [31:0] reg_read_data1;
    wire [31:0] reg_read_data2;

    // Instantiate the register file
    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .reg_write_en(reg_write_en_wb), // Write enable comes from WB stage
        .write_reg_addr(write_reg_addr_wb), // Write address comes from WB stage
        .write_data(write_data_wb),     // Write data comes from WB stage
        .read_reg1_addr(Rn_decoded),    // Read Rn
        .read_reg2_addr(Rm_decoded),    // Read Rm
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2)
    );

    // Control Unit Logic (Combinational)
    // This block determines the control signals based on the decoded opcode.
    // This is a simplified control unit. A real one would be more complex
    // and handle all instruction types and their specific requirements.

    // Default control signals
    reg reg_write_en_ctrl;
    reg mem_read_en_ctrl;
    reg mem_write_en_ctrl;
    reg alu_src_ctrl; // 0: Reg, 1: Imm
    reg [3:0] alu_op_ctrl; // ALU operation type (now 4-bit)
    reg alu_invert_rm_ctrl; // Control: Invert Rm for BIC
    reg mem_to_reg_ctrl; // 0: ALU result, 1: Memory data
    reg branch_taken_ctrl; // For branch instructions
    reg [31:0] branch_target_addr_ctrl; // For branch instructions

    // Sign-extend the 11-bit immediate for use in ALU or PC calculation
    wire [31:0] extended_imm;
    assign extended_imm = {{21{imm_decoded[10]}}, imm_decoded}; // Sign-extend imm[10:0] to 32 bits

    // Branch target calculation (PC + (signed_offset * 4))
    // Branch offset is signed and word-aligned (multiplied by 4)
    assign branch_target_addr_ctrl = pc_in_ifid + (extended_imm << 2); // PC + (offset * 4)

    always @(*) begin
        // Initialize control signals to default (no operation)
        reg_write_en_ctrl = 1'b0;
        mem_read_en_ctrl = 1'b0;
        mem_write_en_ctrl = 1'b0;
        alu_src_ctrl = 1'b0; // Default to register source for ALU
        alu_op_ctrl = 4'b0000;  // Default ALU op (e.g., ADD)
        alu_invert_rm_ctrl = 1'b0; // Default no inversion
        mem_to_reg_ctrl = 1'b0; // Default to ALU result for write-back
        branch_taken_ctrl = 1'b0; // Default no branch
        // branch_target_addr_ctrl is combinational, already assigned above

        case (opcode_decoded)
            // Data Processing (Register-to-Register)
            5'b00000: begin // ADD
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn + Rm (shifted)
                alu_op_ctrl = 4'b0000; // ADD
                mem_to_reg_ctrl = 1'b0; // Write ALU result
            end
            5'b00001: begin // SUB
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn - Rm (shifted)
                alu_op_ctrl = 4'b0001; // SUB
                mem_to_reg_ctrl = 1'b0;
            end
            5'b00010: begin // MUL
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn * Rm (shifted)
                alu_op_ctrl = 4'b0010; // MUL
                mem_to_reg_ctrl = 1'b0;
            end
            5'b00011: begin // DIV
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn / Rm (shifted)
                alu_op_ctrl = 4'b0011; // DIV
                mem_to_reg_ctrl = 1'b0;
            end
            5'b00100: begin // MOD
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn % Rm (shifted)
                alu_op_ctrl = 4'b0100; // MOD
                mem_to_reg_ctrl = 1'b0;
            end
            5'b00101: begin // AND
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn & Rm (shifted)
                alu_op_ctrl = 4'b0101; // AND
                mem_to_reg_ctrl = 1'b0;
            end
            5'b00110: begin // ORR
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn | Rm (shifted)
                alu_op_ctrl = 4'b0110; // ORR
                mem_to_reg_ctrl = 1'b0;
            end
            5'b00111: begin // XOR
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn ^ Rm (shifted)
                alu_op_ctrl = 4'b0111; // XOR
                mem_to_reg_ctrl = 1'b0;
            end
            5'b01000: begin // BIC (Bit Clear)
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // Rn & (~Rm) (shifted)
                alu_op_ctrl = 4'b1000; // BIC (or AND with invert Rm)
                alu_invert_rm_ctrl = 1'b1; // Invert Rm for this operation
                mem_to_reg_ctrl = 1'b0;
            end
            5'b01001: begin // MVN (Move Not)
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b0; // ~Rm (shifted) - Rn is ignored
                alu_op_ctrl = 4'b1001; // MVN (or NOT)
                mem_to_reg_ctrl = 1'b0;
            end
            5'b01010: begin // CMP (Compare)
                // No write-back to register, only sets condition flags in ALU
                alu_src_ctrl = 1'b0; // Rn - Rm (shifted)
                alu_op_ctrl = 4'b1010; // CMP (SUB for flags)
            end
            5'b01011: begin // TST (Test)
                // No write-back to register, only sets condition flags in ALU
                alu_src_ctrl = 1'b0; // Rn & Rm (shifted)
                alu_op_ctrl = 4'b1011; // TST (AND for flags)
            end

            // Immediate Instructions
            5'b01100: begin // MVI (Move Immediate)
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Use immediate as source
                alu_op_ctrl = 4'b1100; // MVI (effectively pass-through or ADD with 0)
                mem_to_reg_ctrl = 1'b0;
            end
            5'b01101: begin // ADDI
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Rn + Imm
                alu_op_ctrl = 4'b0000; // ADD
                mem_to_reg_ctrl = 1'b0;
            end
            5'b01110: begin // SUBI
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Rn - Imm
                alu_op_ctrl = 4'b0001; // SUB
                mem_to_reg_ctrl = 1'b0;
            end
            5'b01111: begin // ANDI
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Rn & Imm
                alu_op_ctrl = 4'b0101; // AND
                mem_to_reg_ctrl = 1'b0;
            end
            5'b10000: begin // ORI
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Rn | Imm
                alu_op_ctrl = 4'b0110; // ORR
                mem_to_reg_ctrl = 1'b0;
            end
            5'b10001: begin // XORI
                reg_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Rn ^ Imm
                alu_op_ctrl = 4'b0111; // XOR
                mem_to_reg_ctrl = 1'b0;
            end

            // Load/Store Instructions
            5'b10010: begin // LDR (Load Register)
                reg_write_en_ctrl = 1'b1;
                mem_read_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Rn + Imm (address calculation)
                alu_op_ctrl = 4'b0000; // ADD for address calculation
                mem_to_reg_ctrl = 1'b1; // Write memory data
            end
            5'b10011: begin // STR (Store Register)
                mem_write_en_ctrl = 1'b1;
                alu_src_ctrl = 1'b1; // Rn + Imm (address calculation)
                alu_op_ctrl = 4'b0000; // ADD for address calculation
            end

            // Branch Instructions (simplified for now, full condition check in EX)
            5'b10100: begin // B (Unconditional Branch)
                branch_taken_ctrl = 1'b1; // Always taken
            end
            5'b10101: begin // BEQ (Branch if Equal)
                // Branch taken depends on condition flags from ALU in EX stage.
                // For now, we pass the potential branch target.
                // The actual branch_taken_out_if will be determined by the EX stage.
            end
            5'b10110: begin // BNE (Branch if Not Equal)
                // Similar to BEQ
            end
            5'b10111: begin // BLT (Branch if Less Than)
                // Similar to BEQ
            end
            5'b11000: begin // BGT (Branch if Greater Than)
                // Similar to BEQ
            end
            default: begin
                // No operation, all control signals remain at default (0)
            end
        endcase
    end

    // Outputs to IF stage (for branch prediction/actual branch)
    // For a simple pipeline, we assume branch is taken here for simplicity
    // and correct it later with a flush if not taken.
    // A more sophisticated design would have branch prediction.
    assign branch_taken_out_if = branch_taken_ctrl; // This will be refined with actual condition flags
    assign branch_target_addr_out_if = branch_target_addr_ctrl;

    // Outputs to ID/EX pipeline register
    assign pc_out_idex = pc_in_ifid;
    assign opcode_out_idex = opcode_decoded;
    assign cond_out_idex = cond_decoded;
    assign read_data1_out_idex = reg_read_data1;
    assign read_data2_out_idex = reg_read_data2;
    assign imm_out_idex = imm_decoded;
    assign Rd_out_idex = Rd_decoded;
    assign shift_type_out_idex = shift_type_decoded; // Pass shift type
    assign shift_amt_out_idex = shift_amt_decoded;   // Pass shift amount

    // Control signals to ID/EX pipeline register
    assign reg_write_en_out_idex = reg_write_en_ctrl;
    assign mem_read_en_out_idex = mem_read_en_ctrl;
    assign mem_write_en_out_idex = mem_write_en_ctrl;
    assign alu_src_out_idex = alu_src_ctrl;
    assign alu_op_out_idex = alu_op_ctrl;
    assign alu_invert_rm_out_idex = alu_invert_rm_ctrl; // Pass invert Rm control
    assign mem_to_reg_out_idex = mem_to_reg_ctrl;
    assign branch_taken_out_idex = branch_taken_ctrl; // This will be refined
    assign branch_target_addr_out_idex = branch_target_addr_ctrl;

endmodule

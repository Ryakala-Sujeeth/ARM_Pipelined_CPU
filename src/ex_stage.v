// ex_stage.v
// This module implements the Execute stage of the pipeline.
// It performs ALU operations, handles shifts, evaluates branch conditions,
// and determines the final branch taken decision.
// UPDATED to accept forwarded data for ALU operands.

module ex_stage (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from ID/EX pipeline register
    input wire [31:0] pc_in_idex,
    input wire [4:0] opcode_in_idex,
    input wire [3:0] cond_in_idex,
    // Original read data from register file (now potentially bypassed)
    input wire [31:0] read_data1_in_idex,
    input wire [31:0] read_data2_in_idex, // This is Rm
    input wire [10:0] imm_in_idex,
    input wire [3:0] Rd_in_idex,
    input wire [1:0] shift_type_in_idex,
    input wire [4:0] shift_amt_in_idex,

    // NEW: Forwarded data inputs from cpu_top
    input wire [31:0] forwarded_read_data1_in, // Forwarded data for Rn
    input wire [31:0] forwarded_read_data2_in, // Forwarded data for Rm

    // Control signals from ID/EX pipeline register
    input wire reg_write_en_in_idex,
    input wire mem_read_en_in_idex,
    input wire mem_write_en_in_idex,
    input wire alu_src_in_idex,
    input wire [3:0] alu_op_in_idex,
    input wire alu_invert_rm_in_idex,
    input wire mem_to_reg_in_idex,
    input wire branch_taken_in_idex, // Initial branch decision from ID
    input wire [31:0] branch_target_addr_in_idex,

    // Outputs to IF stage (for branch resolution)
    output wire [31:0] branch_target_addr_out_if, // Final branch target
    output wire branch_taken_out_if,             // Final branch taken decision (for PC update/flush)

    // Outputs to EX/MEM pipeline register
    output wire [31:0] pc_out_exmem,
    output wire [31:0] alu_result_out_exmem,
    output wire [31:0] write_data_out_exmem, // Data to write to memory (from Rm)
    output wire [3:0] Rd_out_exmem,
    output wire [4:0] opcode_out_exmem,
    output wire [3:0] cond_out_exmem,

    // Control signals to EX/MEM pipeline register
    output wire reg_write_en_out_exmem,
    output wire mem_read_en_out_exmem,
    output wire mem_write_en_out_exmem,
    output wire mem_to_reg_out_exmem,
    output wire branch_taken_out_exmem,
    output wire [31:0] branch_target_addr_out_exmem
);

    // Wires for ALU operands - NOW USING FORWARDED DATA
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;

    // Wires for ALU results and flags
    wire [31:0] alu_result_wire;
    wire zero_flag_wire;
    wire negative_flag_wire;
    wire carry_flag_wire;
    wire overflow_flag_wire;

    // Sign-extend the 11-bit immediate for use as ALU operand2
    wire [31:0] extended_imm;
    assign extended_imm = {{21{imm_in_idex[10]}}, imm_in_idex};

    // Mux for ALU operand1: Use forwarded data for Rn
    assign alu_operand1 = forwarded_read_data1_in;

    // Mux for ALU operand2: Select between forwarded Rm and immediate
    assign alu_operand2 = alu_src_in_idex ? extended_imm : forwarded_read_data2_in;

    // Instantiate the ALU
    alu alu_unit (
        .operand1(alu_operand1),
        .operand2(alu_operand2),
        .alu_op(alu_op_in_idex),
        .shift_type(shift_type_in_idex),
        .shift_amt(shift_amt_in_idex),
        .alu_invert_operand2(alu_invert_rm_in_idex),
        .alu_result(alu_result_wire),
        .zero_flag(zero_flag_wire),
        .negative_flag(negative_flag_wire),
        .carry_flag(carry_flag_wire),
        .overflow_flag(overflow_flag_wire)
    );

    // Condition Code Evaluation Logic
    reg condition_met;
    reg final_branch_taken;

    always @(*) begin
        condition_met = 1'b0; // Default to not met
        final_branch_taken = 1'b0; // Default no branch taken

        case (cond_in_idex)
            4'b0000: condition_met = zero_flag_wire;       // EQ (Equal)
            4'b0001: condition_met = ~zero_flag_wire;      // NE (Not Equal)
            4'b0010: condition_met = carry_flag_wire;      // CS/HS (Carry Set / Unsigned Higher or Same)
            4'b0011: condition_met = ~carry_flag_wire;     // CC/LO (Carry Clear / Unsigned Lower)
            4'b0100: condition_met = negative_flag_wire;   // MI (Minus / Negative)
            4'b0101: condition_met = ~negative_flag_wire;  // PL (Plus / Positive or Zero)
            4'b0110: condition_met = overflow_flag_wire;   // VS (Overflow Set)
            4'b0111: condition_met = ~overflow_flag_wire;  // VC (Overflow Clear)
            4'b1000: condition_met = carry_flag_wire && ~zero_flag_wire; // HI (Unsigned Higher)
            4'b1001: condition_met = ~carry_flag_wire || zero_flag_wire; // LS (Unsigned Lower or Same)
            4'b1010: condition_met = negative_flag_wire == overflow_flag_wire; // GE (Signed Greater Than or Equal)
            4'b1011: condition_met = negative_flag_wire != overflow_flag_wire; // LT (Signed Less Than)
            4'b1100: condition_met = ~zero_flag_wire && (negative_flag_wire == overflow_flag_wire); // GT (Signed Greater Than)
            4'b1101: condition_met = zero_flag_wire || (negative_flag_wire != overflow_flag_wire); // LE (Signed Less Than or Equal)
            4'b1110: condition_met = 1'b1; // AL (Always - unconditional execution)
            default: condition_met = 1'b0; // Undefined condition, default to false
        endcase

        // Determine final branch taken decision
        if (branch_taken_in_idex && condition_met) begin
            final_branch_taken = 1'b1;
        end else begin
            final_branch_taken = 1'b0;
        end
    end

    // Outputs to IF stage (for PC update and pipeline flush)
    assign branch_target_addr_out_if = branch_target_addr_in_idex;
    assign branch_taken_out_if = final_branch_taken;

    // Outputs to EX/MEM pipeline register
    assign pc_out_exmem = pc_in_idex;
    assign alu_result_out_exmem = alu_result_wire;
    // Data to write to memory for STR is the original Rm value, not the forwarded one
    assign write_data_out_exmem = read_data2_in_idex;
    assign Rd_out_exmem = Rd_in_idex;
    assign opcode_out_exmem = opcode_in_idex;
    assign cond_out_exmem = cond_in_idex;

    // Control signals to EX/MEM pipeline register
    // Register write enable is conditional on condition_met
    assign reg_write_en_out_exmem = reg_write_en_in_idex && condition_met;
    assign mem_read_en_out_exmem = mem_read_en_in_idex && condition_met;
    assign mem_write_en_out_exmem = mem_write_en_in_idex && condition_met;
    assign mem_to_reg_out_exmem = mem_to_reg_in_idex;
    assign branch_taken_out_exmem = final_branch_taken; // Pass final decision
    assign branch_target_addr_out_exmem = branch_target_addr_in_idex;

endmodule

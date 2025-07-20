// id_ex_reg.v
// This module implements the pipeline register between the Instruction Decode (ID)
// and Execute (EX) stages. It passes decoded instruction fields, read register data,
// immediate values, and control signals to the EX stage.

module id_ex_reg (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from ID stage
    input wire [31:0] pc_in,        // PC value of the instruction
    input wire [4:0] opcode_in,     // Decoded opcode
    input wire [3:0] cond_in,       // Condition code
    input wire [31:0] read_data1_in, // Data read from Rn
    input wire [31:0] read_data2_in, // Data read from Rm
    input wire [10:0] imm_in,       // Immediate value
    input wire [3:0] Rd_in,         // Destination register address
    input wire [1:0] shift_type_in, // Shift type for data processing
    input wire [4:0] shift_amt_in,  // Shift amount for data processing

    // Control signals
    input wire reg_write_en_in,     // Control: Register write enable
    input wire mem_read_en_in,      // Control: Memory read enable
    input wire mem_write_en_in,     // Control: Memory write enable
    input wire alu_src_in,          // Control: ALU source (0=Reg, 1=Imm)
    input wire [3:0] alu_op_in,     // Control: ALU operation type (now 4-bit)
    input wire alu_invert_rm_in,    // Control: Invert Rm before ALU (for BIC)
    input wire mem_to_reg_in,       // Control: Write data source (0=ALU, 1=Mem)
    input wire branch_taken_in,     // Control: Indicates if a branch is taken
    input wire [31:0] branch_target_addr_in, // Branch target address

    // Outputs to EX stage
    output reg [31:0] pc_out,
    output reg [4:0] opcode_out,
    output reg [3:0] cond_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [10:0] imm_out,
    output reg [3:0] Rd_out,
    output reg [1:0] shift_type_out,
    output reg [4:0] shift_amt_out,

    // Control signals passed to EX stage
    output reg reg_write_en_out,
    output reg mem_read_en_out,
    output reg mem_write_en_out,
    output reg alu_src_out,
    output reg [3:0] alu_op_out, // Now 4-bit
    output reg alu_invert_rm_out,
    output reg mem_to_reg_out,
    output reg branch_taken_out,
    output reg [31:0] branch_target_addr_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // On reset, clear all pipeline register outputs
            pc_out <= 32'b0;
            opcode_out <= 5'b0;
            cond_out <= 4'b0;
            read_data1_out <= 32'b0;
            read_data2_out <= 32'b0;
            imm_out <= 11'b0;
            Rd_out <= 4'b0;
            shift_type_out <= 2'b0;
            shift_amt_out <= 5'b0;

            reg_write_en_out <= 1'b0;
            mem_read_en_out <= 1'b0;
            mem_write_en_out <= 1'b0;
            alu_src_out <= 1'b0;
            alu_op_out <= 4'b0; // Now 4-bit
            alu_invert_rm_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_taken_out <= 1'b0;
            branch_target_addr_out <= 32'b0;
        end else if (enable) begin
            // On positive clock edge, if enabled, latch inputs to outputs
            pc_out <= pc_in;
            opcode_out <= opcode_in;
            cond_out <= cond_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            imm_out <= imm_in;
            Rd_out <= Rd_in;
            shift_type_out <= shift_type_in;
            shift_amt_out <= shift_amt_in;

            reg_write_en_out <= reg_write_en_in;
            mem_read_en_out <= mem_read_en_in;
            mem_write_en_out <= mem_write_en_in;
            alu_src_out <= alu_src_in;
            alu_op_out <= alu_op_in;
            alu_invert_rm_out <= alu_invert_rm_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_taken_out <= branch_taken_in;
            branch_target_addr_out <= branch_target_addr_in;
        end
    end

endmodule

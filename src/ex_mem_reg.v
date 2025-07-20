// ex_mem_reg.v
// This module implements the pipeline register between the Execute (EX)
// and Memory Access (MEM) stages. It passes ALU results, memory addresses,
// data to be written to memory, destination register, and control signals.

module ex_mem_reg (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from EX stage
    input wire [31:0] pc_in,            // PC value of the instruction
    input wire [31:0] alu_result_in,    // Result from ALU (address for Load/Store)
    input wire [31:0] write_data_in,    // Data to write to memory (for STR)
    input wire [3:0] Rd_in,             // Destination register address
    input wire [4:0] opcode_in,         // Opcode (for debugging/further control)
    input wire [3:0] cond_in,           // Condition code (for conditional writes)

    // Control signals from EX stage
    input wire reg_write_en_in,         // Control: Register write enable
    input wire mem_read_en_in,          // Control: Memory read enable
    input wire mem_write_en_in,         // Control: Memory write enable
    input wire mem_to_reg_in,           // Control: Write data source (0=ALU, 1=Mem)
    input wire branch_taken_in,         // Control: Indicates if a branch is taken (final decision)
    input wire [31:0] branch_target_addr_in, // Branch target address

    // Outputs to MEM stage
    output reg [31:0] pc_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [3:0] Rd_out,
    output reg [4:0] opcode_out,
    output reg [3:0] cond_out,

    // Control signals passed to MEM stage
    output reg reg_write_en_out,
    output reg mem_read_en_out,
    output reg mem_write_en_out,
    output reg mem_to_reg_out,
    output reg branch_taken_out,
    output reg [31:0] branch_target_addr_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // On reset, clear all pipeline register outputs
            pc_out <= 32'b0;
            alu_result_out <= 32'b0;
            write_data_out <= 32'b0;
            Rd_out <= 4'b0;
            opcode_out <= 5'b0;
            cond_out <= 4'b0;

            reg_write_en_out <= 1'b0;
            mem_read_en_out <= 1'b0;
            mem_write_en_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_taken_out <= 1'b0;
            branch_target_addr_out <= 32'b0;
        end else if (enable) begin
            // On positive clock edge, if enabled, latch inputs to outputs
            pc_out <= pc_in;
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in;
            Rd_out <= Rd_in;
            opcode_out <= opcode_in;
            cond_out <= cond_in;

            reg_write_en_out <= reg_write_en_in;
            mem_read_en_out <= mem_read_en_in;
            mem_write_en_out <= mem_write_en_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_taken_out <= branch_taken_in;
            branch_target_addr_out <= branch_target_addr_in;
        end
    end

endmodule

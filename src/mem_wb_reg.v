// mem_wb_reg.v
// This module implements the pipeline register between the Memory Access (MEM)
// and Write Back (WB) stages. It passes the final result (from ALU or memory),
// the destination register, and control signals.

module mem_wb_reg (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from MEM stage
    input wire [31:0] pc_in,            // PC value of the instruction
    input wire [31:0] alu_result_in,    // ALU result (for non-load instructions)
    input wire [31:0] mem_read_data_in, // Data read from memory (for LDR)
    input wire [3:0] Rd_in,             // Destination register address
    input wire [4:0] opcode_in,         // Opcode (for debugging/further control)

    // Control signals from MEM stage
    input wire reg_write_en_in,         // Control: Register write enable
    input wire mem_to_reg_in,           // Control: Write data source (0=ALU, 1=Mem)

    // Outputs to WB stage
    output reg [31:0] pc_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_read_data_out,
    output reg [3:0] Rd_out,
    output reg [4:0] opcode_out,

    // Control signals passed to WB stage
    output reg reg_write_en_out,
    output reg mem_to_reg_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // On reset, clear all pipeline register outputs
            pc_out <= 32'b0;
            alu_result_out <= 32'b0;
            mem_read_data_out <= 32'b0;
            Rd_out <= 4'b0;
            opcode_out <= 5'b0;

            reg_write_en_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else if (enable) begin
            // On positive clock edge, if enabled, latch inputs to outputs
            pc_out <= pc_in;
            alu_result_out <= alu_result_in;
            mem_read_data_out <= mem_read_data_in;
            Rd_out <= Rd_in;
            opcode_out <= opcode_in;

            reg_write_en_out <= reg_write_en_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end

endmodule

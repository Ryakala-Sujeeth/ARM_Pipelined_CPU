// if_id_reg.v
// This module implements the pipeline register between the Instruction Fetch (IF)
// and Instruction Decode (ID) stages. It holds the fetched instruction and
// the PC value of that instruction.

module if_id_reg (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from IF stage
    input wire [31:0] pc_in,        // PC value of the fetched instruction
    input wire [31:0] instr_in,     // Fetched instruction

    // Outputs to ID stage
    output reg [31:0] pc_out,       // PC value passed to ID stage
    output reg [31:0] instr_out     // Instruction passed to ID stage
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // On reset, clear the register outputs
            pc_out <= 32'b0;
            instr_out <= 32'b0;
        end else if (enable) begin
            // On positive clock edge, if enabled, latch the inputs to outputs
            pc_out <= pc_in;
            instr_out <= instr_in;
        end
    end

endmodule

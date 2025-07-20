// if_stage.v
// This module implements the Instruction Fetch stage of the pipeline.
// It includes the Program Counter (PC) and logic to fetch instructions.

module if_stage (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire pc_write_en,     // Enable writing to PC (for branches/jumps)
    input wire [31:0] branch_target_addr, // Address for branches/jumps

    // Outputs to IF/ID pipeline register
    output wire [31:0] pc_out_ifid,    // PC value to IF/ID register
    output wire [31:0] instr_out_ifid, // Instruction to IF/ID register

    // Interface to Instruction Memory
    output wire [31:0] imem_addr,      // Address to Instruction Memory
    input wire [31:0] imem_rdata      // Data read from Instruction Memory
);

    // Program Counter (PC) register
    reg [31:0] pc;

    // Assign PC value to instruction memory address input
    assign imem_addr = pc;

    // Assign fetched instruction and PC to the IF/ID pipeline register outputs
    assign pc_out_ifid = pc;
    assign instr_out_ifid = imem_rdata;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // On reset, PC starts at address 0
            pc <= 32'h00000000;
        end else if (pc_write_en) begin
            // If pc_write_en is high, it means a branch/jump is taken,
            // so update PC with the branch target address.
            pc <= branch_target_addr;
        end else begin
            // Otherwise, increment PC by 4 for the next instruction (word-aligned)
            pc <= pc + 4;
        end
    end

endmodule

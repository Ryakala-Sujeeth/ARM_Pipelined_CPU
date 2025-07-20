// mem_stage.v
// This module implements the Memory Access stage of the pipeline.
// It handles load (LDR) and store (STR) operations to data memory.

module mem_stage (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from EX/MEM pipeline register
    input wire [31:0] pc_in_exmem,
    input wire [31:0] alu_result_in_exmem,    // ALU result (memory address for LDR/STR)
    input wire [31:0] write_data_in_exmem,    // Data to write to memory (for STR)
    input wire [3:0] Rd_in_exmem,             // Destination register address
    input wire [4:0] opcode_in_exmem,         // Opcode (for debugging/further control)

    // Control signals from EX/MEM pipeline register
    input wire reg_write_en_in_exmem,         // Control: Register write enable
    input wire mem_read_en_in_exmem,          // Control: Memory read enable
    input wire mem_write_en_en_exmem,         // Control: Memory write enable
    input wire mem_to_reg_in_exmem,           // Control: Write data source (0=ALU, 1=Mem)

    // Interface to Data Memory
    output wire [31:0] dmem_addr,             // Address to Data Memory
    output wire [31:0] dmem_wdata,            // Data to write to Data Memory
    output wire dmem_read_en,                 // Data Memory Read Enable
    output wire dmem_write_en,                // Data Memory Write Enable
    input wire [31:0] dmem_rdata,             // Data read from Data Memory

    // Outputs to MEM/WB pipeline register
    output wire [31:0] pc_out_memwb,
    output wire [31:0] alu_result_out_memwb,
    output wire [31:0] mem_read_data_out_memwb,
    output wire [3:0] Rd_out_memwb,
    output wire [4:0] opcode_out_memwb,

    // Control signals to MEM/WB pipeline register
    output wire reg_write_en_out_memwb,
    output wire mem_to_reg_out_memwb
);

    // Memory address is the ALU result from the EX stage
    assign dmem_addr = alu_result_in_exmem;

    // Data to write to memory comes from the EX stage (read_data2_in_idex, which is Rm)
    assign dmem_wdata = write_data_in_exmem;

    // Data memory control signals are directly from the EX/MEM register
    assign dmem_read_en = mem_read_en_in_exmem;
    assign dmem_write_en = mem_write_en_en_exmem;

    // Outputs to MEM/WB pipeline register
    assign pc_out_memwb = pc_in_exmem;
    assign alu_result_out_memwb = alu_result_in_exmem;
    assign mem_read_data_out_memwb = dmem_rdata; // Data read from memory
    assign Rd_out_memwb = Rd_in_exmem;
    assign opcode_out_memwb = opcode_in_exmem;

    // Control signals to MEM/WB pipeline register
    assign reg_write_en_out_memwb = reg_write_en_in_exmem;
    assign mem_to_reg_out_memwb = mem_to_reg_in_exmem;

endmodule

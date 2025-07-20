// wb_stage.v
// This module implements the Write Back stage of the pipeline.
// It selects the data to be written back to the register file
// and asserts the write enable signal for the register file.

module wb_stage (
    input wire clk,             // Clock signal (for synchronous writes to reg file)
    input wire reset,           // Asynchronous reset
    input wire enable,          // Enable signal for pipeline (e.g., for stalls)

    // Inputs from MEM/WB pipeline register
    input wire [31:0] pc_in_memwb,            // PC value (for debugging)
    input wire [31:0] alu_result_in_memwb,    // ALU result (for non-load instructions)
    input wire [31:0] mem_read_data_in_memwb, // Data read from memory (for LDR)
    input wire [3:0] Rd_in_memwb,             // Destination register address
    input wire [4:0] opcode_in_memwb,         // Opcode (for debugging)

    // Control signals from MEM/WB pipeline register
    input wire reg_write_en_in_memwb,         // Control: Register write enable
    input wire mem_to_reg_in_memwb,           // Control: Write data source (0=ALU, 1=Mem)

    // Outputs to Register File (in ID stage)
    output wire reg_write_en_out_rf,         // Register write enable
    output wire [3:0] write_reg_addr_out_rf, // Address of register to write
    output wire [31:0] write_data_out_rf      // Data to write to register
);

    // Mux to select data to write back to the register file
    // If mem_to_reg is 1, write data from memory (LDR).
    // If mem_to_reg is 0, write data from ALU (Data Processing, Immediate, etc.).
    wire [31:0] final_write_data;
    assign final_write_data = mem_to_reg_in_memwb ? mem_read_data_in_memwb : alu_result_in_memwb;

    // Outputs to the Register File
    // The register write enable signal is directly from the MEM/WB register.
    assign reg_write_en_out_rf = reg_write_en_in_memwb;
    // The destination register address is also from the MEM/WB register.
    assign write_reg_addr_out_rf = Rd_in_memwb;
    // The data to write is the selected final_write_data.
    assign write_data_out_rf = final_write_data;

    // Note: The actual write to the register file happens synchronously
    // within the 'register_file' module (which is instantiated in the ID stage)
    // using the 'clk' and 'reg_write_en_out_rf' signals.
    // This 'wb_stage' module primarily prepares the data and control signals.

endmodule

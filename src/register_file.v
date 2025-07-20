// register_file.v
// This module implements a simple register file for the CPU.
// It supports reading from two source registers simultaneously and
// writing to one destination register.
// REVISED: Ensuring all 'reg' declarations are at the module level.

module register_file (
    input wire clk,             // Clock signal
    input wire reset,           // Asynchronous reset
    input wire reg_write_en,    // Enable signal for writing to a register
    input wire [3:0] write_reg_addr, // Address of the register to write to
    input wire [31:0] write_data,   // Data to write into the register

    input wire [3:0] read_reg1_addr, // Address of the first register to read
    input wire [3:0] read_reg2_addr, // Address of the second register to read

    output wire [31:0] read_data1,  // Data read from the first register
    output wire [31:0] read_data2   // Data read from the second register
);

    // Define the register array: 16 registers, each 32 bits wide (declared at module level)
    // Assuming 4-bit register addresses (0-15)
    reg [31:0] registers [0:15];

    // Initialize registers on reset
    initial begin
        integer i; // 'integer' is fine inside initial/always blocks
        for (i = 0; i < 16; i = i + 1) begin
            registers[i] = 32'b0; // Initialize all registers to 0
        end
        // Optionally, set some initial values for testing
        registers[1] = 32'd10; // R1 = 10
        registers[2] = 32'd20; // R2 = 20
        registers[3] = 32'd30; // R3 = 30
    end

    // Read operations (combinational)
    // Data is available immediately based on read addresses
    assign read_data1 = registers[read_reg1_addr];
    assign read_data2 = registers[read_reg2_addr];

    // Write operation (sequential - happens on positive clock edge)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Registers are initialized in the initial block on reset
            // No explicit write logic here for reset, as initial handles it.
        end else if (reg_write_en) begin
            // Only write if reg_write_en is high and the write address is not R0 (typically R0 is hardwired to 0)
            // If your ISA allows writing to R0, remove the 'write_reg_addr != 4'b0' check.
            if (write_reg_addr != 4'b0) begin
                registers[write_reg_addr] <= write_data;
            end
        end
    end

endmodule

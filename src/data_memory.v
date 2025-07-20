// data_memory.v
// Simple data memory module for simulation purposes.
// In a real system, this would interface with an external data memory.
// REVISED: Ensuring all 'reg' declarations are at the module level.

module data_memory (
    input wire clk,             // Clock signal for synchronous memory writes
    input wire reset,           // Asynchronous reset
    input wire mem_read_en,     // Enable signal for memory read
    input wire mem_write_en,    // Enable signal for memory write
    input wire [31:0] addr,     // 32-bit address for memory access
    input wire [31:0] write_data, // 32-bit data to write to memory

    output reg [31:0] read_data // 32-bit data read from memory
);

    // Memory array: 256 words of 32 bits each (declared at module level)
    reg [31:0] mem [0:255];

    // Initialize memory with some dummy data for testing
    initial begin
        integer i; // 'integer' is fine inside initial/always blocks
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'hDEADBEEF; // Fill with a recognizable pattern
        end
        mem[0] = 32'h000000A0; // Example data at address 0
        mem[4] = 32'h000000B0; // Example data at address 4
    end

    // Memory Read (combinational)
    // Data is available immediately based on address if read enabled
    always @(addr or mem_read_en) begin
        if (mem_read_en) begin
            // Assuming word-aligned access, so divide address by 4 for word index.
            read_data = mem[addr[31:2]]; // read_data = mem[addr / 4]
        end else begin
            read_data = 32'b0; // Output zero if not reading
        end
    end

    // Memory Write (synchronous)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Memory contents are initialized in the initial block
        end else if (mem_write_en) begin
            // Write data to memory at the given byte address on clock edge
            // Assuming word-aligned access.
            mem[addr[31:2]] <= write_data; // mem[addr / 4] <= write_data
        end
    end

endmodule

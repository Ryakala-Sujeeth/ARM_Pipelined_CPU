// data_memory_tb.v
// Test bench for the data_memory module.
// Verifies read and write operations to the data memory.

`timescale 1ns / 1ps

module data_memory_tb;

    // Inputs to the DUT
    reg clk;
    reg reset;
    reg mem_read_en;
    reg mem_write_en;
    reg [31:0] addr;
    reg [31:0] write_data;

    // Outputs from the DUT
    wire [31:0] read_data;

    // Instantiate the DUT
    data_memory dut (
        .clk(clk),
        .reset(reset),
        .mem_read_en(mem_read_en),
        .mem_write_en(mem_write_en),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100 MHz)
    end

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("data_memory.vcd");
        $dumpvars(0, data_memory_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting data_memory Test ---");
        $display("Time | Reset | Read_En | Write_En | Address | Write_Data | Read_Data");
        $display("---------------------------------------------------------------------");

        // Initialize signals
        reset = 0;
        mem_read_en = 0;
        mem_write_en = 0;
        addr = 32'b0;
        write_data = 32'b0;
        #10;

        // Test Case 1: Apply reset
        reset = 1;
        #20; // Hold reset for 2 clock cycles
        $display("%0t | %b | %b | %b | %h | %h | %h",
                 $time, reset, mem_read_en, mem_write_en, addr, write_data, read_data);
        reset = 0;
        #10;

        // Test Case 2: Read initial value at address 0 (should be 000000A0)
        mem_read_en = 1;
        addr = 32'h0000_0000;
        #10;
        $display("%0t | %b | %b | %b | %h | %h | %h",
                 $time, reset, mem_read_en, mem_write_en, addr, write_data, read_data);

        // Test Case 3: Write data to address 8
        mem_read_en = 0;
        mem_write_en = 1;
        addr = 32'h0000_0008;
        write_data = 32'hCAFE_F00D;
        #10; // Write happens on posedge clk
        $display("%0t | %b | %b | %b | %h | %h | %h",
                 $time, reset, mem_read_en, mem_write_en, addr, write_data, read_data);

        // Test Case 4: Read data from address 8 (should be CAFE_F00D)
        mem_read_en = 1;
        mem_write_en = 0;
        addr = 32'h0000_0008;
        #10;
        $display("%0t | %b | %b | %b | %h | %h | %h",
                 $time, reset, mem_read_en, mem_write_en, addr, write_data, read_data);

        // Test Case 5: Write data to address 12
        mem_read_en = 0;
        mem_write_en = 1;
        addr = 32'h0000_000C;
        write_data = 32'hDEAD_BEEF;
        #10;
        $display("%0t | %b | %b | %b | %h | %h | %h",
                 $time, reset, mem_read_en, mem_write_en, addr, write_data, read_data);

        // Test Case 6: Read data from address 12 (should be DEADBEEF)
        mem_read_en = 1;
        mem_write_en = 0;
        addr = 32'h0000_000C;
        #10;
        $display("%0t | %b | %b | %b | %h | %h | %h",
                 $time, reset, mem_read_en, mem_write_en, addr, write_data, read_data);

        $display("--- data_memory Test Finished ---");
        $finish;
    end

endmodule

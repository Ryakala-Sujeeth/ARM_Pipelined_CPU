// register_file_tb.v
// Test bench for the register_file module.
// Verifies read and write operations to the register file.

`timescale 1ns / 1ps

module register_file_tb;

    // Inputs to the DUT
    reg clk;
    reg reset;
    reg reg_write_en;
    reg [3:0] write_reg_addr;
    reg [31:0] write_data;
    reg [3:0] read_reg1_addr;
    reg [3:0] read_reg2_addr;

    // Outputs from the DUT
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    // Instantiate the register_file module
    register_file dut (
        .clk(clk),
        .reset(reset),
        .reg_write_en(reg_write_en),
        .write_reg_addr(write_reg_addr),
        .write_data(write_data),
        .read_reg1_addr(read_reg1_addr),
        .read_reg2_addr(read_reg2_addr),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100 MHz)
    end

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting register_file Test ---");
        $display("Time | Write_En | Wr_Addr | Wr_Data | Rd1_Addr | Rd2_Addr | Rd_Data1 | Rd_Data2");
        $display("----------------------------------------------------------------------------------");

        // Initialize signals
        reg_write_en = 0;
        write_reg_addr = 0;
        write_data = 0;
        read_reg1_addr = 0;
        read_reg2_addr = 0;

        // Apply reset
        reset = 1;
        #20; // Hold reset for 2 clock cycles
        reset = 0;
        #10; // Wait for one clock cycle after reset release

        // Test Case 1: Read initial values (R1=10, R2=20, R3=30 from initial block)
        read_reg1_addr = 4'd1; // Read R1
        read_reg2_addr = 4'd2; // Read R2
        #10;
        $display("%0t | %b | %h | %h | %h | %h | %h | %h",
                 $time, reg_write_en, write_reg_addr, write_data,
                 read_reg1_addr, read_reg2_addr, read_data1, read_data2);

        // Test Case 2: Write to R5, then read R5 and R1
        reg_write_en = 1;
        write_reg_addr = 4'd5;
        write_data = 32'hABCD_1234;
        read_reg1_addr = 4'd5; // Read R5
        read_reg2_addr = 4'd1; // Read R1
        #10; // Write happens on posedge clk
        $display("%0t | %b | %h | %h | %h | %h | %h | %h",
                 $time, reg_write_en, write_reg_addr, write_data,
                 read_reg1_addr, read_reg2_addr, read_data1, read_data2);

        // Test Case 3: Write to R10, then read R5 and R10
        reg_write_en = 1;
        write_reg_addr = 4'd10;
        write_data = 32'hDEAD_BEEF;
        read_reg1_addr = 4'd5;  // Read R5 (should be ABCD_1234)
        read_reg2_addr = 4'd10; // Read R10 (should be DEADBEEF)
        #10;
        $display("%0t | %b | %h | %h | %h | %h | %h | %h",
                 $time, reg_write_en, write_reg_addr, write_data,
                 read_reg1_addr, read_reg2_addr, read_data1, read_data2);

        // Test Case 4: Disable write, read R10 and R0 (R0 should always be 0)
        reg_write_en = 0;
        write_reg_addr = 0; // No write
        write_data = 0;     // No write
        read_reg1_addr = 4'd10; // Read R10
        read_reg2_addr = 4'd0;  // Read R0
        #10;
        $display("%0t | %b | %h | %h | %h | %h | %h | %h",
                 $time, reg_write_en, write_reg_addr, write_data,
                 read_reg1_addr, read_reg2_addr, read_data1, read_data2);

        // Test Case 5: Attempt to write to R0 (should not change R0)
        reg_write_en = 1;
        write_reg_addr = 4'd0;
        write_data = 32'hFFFFFFFF;
        read_reg1_addr = 4'd0;
        read_reg2_addr = 4'd1;
        #10;
        $display("%0t | %b | %h | %h | %h | %h | %h | %h",
                 $time, reg_write_en, write_reg_addr, write_data,
                 read_reg1_addr, read_reg2_addr, read_data1, read_data2);

        $display("--- register_file Test Finished ---");
        $finish;
    end

endmodule

// instruction_memory_tb.v
// Test bench for the instruction_memory module.
// Verifies that instructions are correctly read from memory.

`timescale 1ns / 1ps

module instruction_memory_tb;

    // Inputs to the DUT
    reg [31:0] addr;

    // Outputs from the DUT
    wire [31:0] instr;

    // Instantiate the DUT
    instruction_memory dut (
        .addr(addr),
        .instr(instr)
    );

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("instruction_memory.vcd");
        $dumpvars(0, instruction_memory_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting instruction_memory Test ---");
        $display("Time | Address | Instruction");
        $display("-----------------------------");

        // Test Case 1: Read instruction at address 0x00
        addr = 32'h0000_0000;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 2: Read instruction at address 0x04
        addr = 32'h0000_0004;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 3: Read instruction at address 0x08
        addr = 32'h0000_0008;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 4: Read instruction at address 0x0C
        addr = 32'h0000_000C;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 5: Read instruction at address 0x10
        addr = 32'h0000_0010;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 6: Read instruction at address 0x14
        addr = 32'h0000_0014;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 7: Read instruction at address 0x18
        addr = 32'h0000_0018;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 8: Read instruction at address 0x1C (Branch)
        addr = 32'h0000_001C;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        // Test Case 9: Read an uninitialized address (should be NOP or default)
        addr = 32'h0000_0040;
        #10;
        $display("%0t | %h | %h", $time, addr, instr);

        $display("--- instruction_memory Test Finished ---");
        $finish;
    end

endmodule

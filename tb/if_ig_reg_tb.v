// if_id_reg_tb.v
// Test bench for the IF/ID pipeline register module.
// Verifies data latching, reset, and enable functionality.

`timescale 1ns / 1ps

module if_id_reg_tb;

    // Inputs to the DUT
    reg clk;
    reg reset;
    reg enable;
    reg [31:0] pc_in;
    reg [31:0] instr_in;

    // Outputs from the DUT
    wire [31:0] pc_out;
    wire [31:0] instr_out;

    // Instantiate the DUT
    if_id_reg dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .pc_in(pc_in),
        .instr_in(instr_in),
        .pc_out(pc_out),
        .instr_out(instr_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100 MHz)
    end

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("if_id_reg.vcd");
        $dumpvars(0, if_id_reg_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting if_id_reg Test ---");
        $display("Time | Reset | Enable | PC_In | Instr_In | PC_Out | Instr_Out");
        $display("------------------------------------------------------------------");

        // Initialize signals
        reset = 0;
        enable = 1; // Enable by default
        pc_in = 32'h0000_0000;
        instr_in = 32'h0000_0000;
        #10; // Wait for initial values to propagate

        // Test Case 1: Apply reset
        reset = 1;
        #20; // Hold reset for 2 clock cycles
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, enable, pc_in, instr_in, pc_out, instr_out);
        reset = 0;
        #10; // Release reset, wait one cycle

        // Test Case 2: Latch normal values
        pc_in = 32'h0000_0004;
        instr_in = 32'hE680100A; // ADDI R1, R0, #10
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, enable, pc_in, instr_in, pc_out, instr_out);

        pc_in = 32'h0000_0008;
        instr_in = 32'hE0213000; // ADD R3, R1, R2
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, enable, pc_in, instr_in, pc_out, instr_out);

        // Test Case 3: Test enable (stall) - outputs should not change
        enable = 0; // Disable latching
        pc_in = 32'h0000_000C; // New inputs
        instr_in = 32'hE9234004; // LDR R4, [R3, #4]
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, enable, pc_in, instr_in, pc_out, instr_out);
        #10; // Another cycle with enable=0
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, enable, pc_in, instr_in, pc_out, instr_out);

        // Test Case 4: Re-enable - outputs should now latch new values
        enable = 1;
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, enable, pc_in, instr_in, pc_out, instr_out);

        $display("--- if_id_reg Test Finished ---");
        $finish;
    end

endmodule

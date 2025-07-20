// if_stage_tb.v
// Test bench for the if_stage module.
// Verifies PC incrementing and branching logic.

`timescale 1ns / 1ps

module if_stage_tb;

    // Inputs to the DUT
    reg clk;
    reg reset;
    reg pc_write_en;
    reg [31:0] branch_target_addr;

    // Outputs from the DUT (connected to instruction_memory and IF/ID reg)
    wire [31:0] pc_out_ifid;
    wire [31:0] instr_out_ifid; // This will be the output from instruction_memory
    wire [31:0] imem_addr;
    reg [31:0] imem_rdata; // Mock input from instruction_memory

    // Instantiate the IF Stage
    if_stage dut (
        .clk(clk),
        .reset(reset),
        .pc_write_en(pc_write_en),
        .branch_target_addr(branch_target_addr),
        .pc_out_ifid(pc_out_ifid),
        .instr_out_ifid(instr_out_ifid),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata) // Connected to mock instruction memory data
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100 MHz)
    end

    // Mock Instruction Memory behavior (simplified)
    // In a real test, you'd instantiate the instruction_memory module here.
    // For unit testing if_stage, we just provide data based on address.
    always @(imem_addr) begin
        // Provide dummy instruction data based on address
        case (imem_addr)
            32'h0000_0000: imem_rdata = 32'hE680100A; // ADDI R1, R0, #10
            32'h0000_0004: imem_rdata = 32'hE6802014; // ADDI R2, R0, #20
            32'h0000_0008: imem_rdata = 32'hE0213000; // ADD R3, R1, R2
            32'h0000_000C: imem_rdata = 32'hE9234004; // LDR R4, [R3, #4]
            default:       imem_rdata = 32'hE6000000; // NOP
        endcase
    end


    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("if_stage.vcd");
        $dumpvars(0, if_stage_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting if_stage Test ---");
        $display("Time | Reset | PC_WrEn | Branch_Target | PC_Out_IFID | Instr_Out_IFID | IMEM_Addr");
        $display("----------------------------------------------------------------------------------");

        // Initialize signals
        reset = 0;
        pc_write_en = 0; // Default PC increment
        branch_target_addr = 32'b0;
        #10; // Wait for initial values

        // Test Case 1: Apply reset
        reset = 1;
        #20; // Hold reset for 2 clock cycles
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, pc_write_en, branch_target_addr, pc_out_ifid, instr_out_ifid, imem_addr);
        reset = 0;
        #10; // Release reset, PC should be 0, next cycle 4

        // Test Case 2: Normal PC increment
        // PC should go 0 -> 4 -> 8 -> C ...
        #10; // PC=0, Instr=E680100A
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, pc_write_en, branch_target_addr, pc_out_ifid, instr_out_ifid, imem_addr);
        #10; // PC=4, Instr=E6802014
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, pc_write_en, branch_target_addr, pc_out_ifid, instr_out_ifid, imem_addr);
        #10; // PC=8, Instr=E0213000
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, pc_write_en, branch_target_addr, pc_out_ifid, instr_out_ifid, imem_addr);

        // Test Case 3: Branch taken
        pc_write_en = 1; // Enable PC write
        branch_target_addr = 32'h0000_0020; // Branch to address 0x20
        #10; // PC should update to 0x20
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, pc_write_en, branch_target_addr, pc_out_ifid, instr_out_ifid, imem_addr);

        // Test Case 4: Continue normal increment after branch
        pc_write_en = 0; // Disable PC write, allow increment
        #10; // PC should be 0x24
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, pc_write_en, branch_target_addr, pc_out_ifid, instr_out_ifid, imem_addr);
        #10; // PC should be 0x28
        $display("%0t | %b | %b | %h | %h | %h | %h",
                 $time, reset, pc_write_en, branch_target_addr, pc_out_ifid, instr_out_ifid, imem_addr);

        $display("--- if_stage Test Finished ---");
        $finish;
    end

endmodule

// wb_stage_tb.v
// Test bench for the wb_stage module.
// Verifies data selection for write-back and output of control signals.

`timescale 1ns / 1ps

module wb_stage_tb;

    // Inputs to the DUT (from MEM/WB pipeline register)
    reg clk; // Needed for completeness, though WB stage is combinational for outputs
    reg reset; // Needed for completeness
    reg enable; // Needed for completeness
    reg [31:0] pc_in_memwb;
    reg [31:0] alu_result_in_memwb;
    reg [31:0] mem_read_data_in_memwb;
    reg [3:0] Rd_in_memwb;
    reg [4:0] opcode_in_memwb; // For display/context
    reg reg_write_en_in_memwb;
    reg mem_to_reg_in_memwb;

    // Outputs from the DUT (to Register File)
    wire reg_write_en_out_rf;
    wire [3:0] write_reg_addr_out_rf;
    wire [31:0] write_data_out_rf;

    // Instantiate the DUT
    wb_stage dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .pc_in_memwb(pc_in_memwb),
        .alu_result_in_memwb(alu_result_in_memwb),
        .mem_read_data_in_memwb(mem_read_data_in_memwb),
        .Rd_in_memwb(Rd_in_memwb),
        .opcode_in_memwb(opcode_in_memwb),
        .reg_write_en_in_memwb(reg_write_en_in_memwb),
        .mem_to_reg_in_memwb(mem_to_reg_in_memwb),
        .reg_write_en_out_rf(reg_write_en_out_rf),
        .write_reg_addr_out_rf(write_reg_addr_out_rf),
        .write_data_out_rf(write_data_out_rf)
    );

    // Clock generation (minimal, as WB is mostly combinational)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("wb_stage.vcd");
        $dumpvars(0, wb_stage_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting wb_stage Test ---");
        $display("Time | RegWrEn_In | MemToReg_In | ALU_Result | Mem_Data | Rd_In | RegWrEn_Out | Wr_Addr_Out | Wr_Data_Out");
        $display("-------------------------------------------------------------------------------------------------------");

        // Initialize signals
        pc_in_memwb = 32'b0;
        alu_result_in_memwb = 32'b0;
        mem_read_data_in_memwb = 32'b0;
        Rd_in_memwb = 4'b0;
        opcode_in_memwb = 5'b0;
        reg_write_en_in_memwb = 0;
        mem_to_reg_in_memwb = 0;
        clk = 0;
        reset = 0;
        enable = 1;
        #10; // Allow combinational logic to settle

        // Test Case 1: ALU result write-back (ADD R1, R2, R3)
        reg_write_en_in_memwb = 1;
        mem_to_reg_in_memwb = 0; // Select ALU result
        alu_result_in_memwb = 32'd100;
        mem_read_data_in_memwb = 32'd999; // Dummy, should be ignored
        Rd_in_memwb = 4'd1;
        opcode_in_memwb = 5'b00000; // ADD
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %b | %h | %h",
                 $time, reg_write_en_in_memwb, mem_to_reg_in_memwb, alu_result_in_memwb,
                 mem_read_data_in_memwb, Rd_in_memwb, reg_write_en_out_rf, write_reg_addr_out_rf, write_data_out_rf);

        // Test Case 2: Memory read data write-back (LDR R2, [R0, #0])
        reg_write_en_in_memwb = 1;
        mem_to_reg_in_memwb = 1; // Select Memory data
        alu_result_in_memwb = 32'd123; // Dummy, should be ignored
        mem_read_data_in_memwb = 32'hFACE_B00C;
        Rd_in_memwb = 4'd2;
        opcode_in_memwb = 5'b10010; // LDR
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %b | %h | %h",
                 $time, reg_write_en_in_memwb, mem_to_reg_in_memwb, alu_result_in_memwb,
                 mem_read_data_in_memwb, Rd_in_memwb, reg_write_en_out_rf, write_reg_addr_out_rf, write_data_out_rf);

        // Test Case 3: No write-back (e.g., CMP, STR, or conditional not met)
        reg_write_en_in_memwb = 0; // Disable write
        mem_to_reg_in_memwb = 0;
        alu_result_in_memwb = 32'd50;
        mem_read_data_in_memwb = 32'd60;
        Rd_in_memwb = 4'd3;
        opcode_in_memwb = 5'b1010; // CMP
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %b | %h | %h",
                 $time, reg_write_en_in_memwb, mem_to_reg_in_memwb, alu_result_in_memwb,
                 mem_read_data_in_memwb, Rd_in_memwb, reg_write_en_out_rf, write_reg_addr_out_rf, write_data_out_rf);

        // Test Case 4: Write to R0 (should be ignored by register_file, but WB stage still outputs)
        reg_write_en_in_memwb = 1;
        mem_to_reg_in_memwb = 0;
        alu_result_in_memwb = 32'h11223344;
        Rd_in_memwb = 4'd0; // R0
        opcode_in_memwb = 5'b00000; // ADD
        #10;
        $display("%0t | %b | %b | %h | %h | %h | %b | %h | %h",
                 $time, reg_write_en_in_memwb, mem_to_reg_in_memwb, alu_result_in_memwb,
                 mem_read_data_in_memwb, Rd_in_memwb, reg_write_en_out_rf, write_reg_addr_out_rf, write_data_out_rf);


        $display("--- wb_stage Test Finished ---");
        $finish;
    end

endmodule

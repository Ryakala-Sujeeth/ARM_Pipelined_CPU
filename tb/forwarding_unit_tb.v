// forwarding_unit_tb.v
// Test bench for the forwarding_unit module.
// Verifies that correct forwarding signals are generated based on hazards.

`timescale 1ns / 1ps

module forwarding_unit_tb;

    // Inputs to the DUT
    reg [3:0] Rs1_idex;
    reg [3:0] Rs2_idex;
    reg reg_write_en_exmem;
    reg [3:0] Rd_exmem;
    reg reg_write_en_memwb;
    reg [3:0] Rd_memwb;

    // Outputs from the DUT
    wire [1:0] forward_A;
    wire [1:0] forward_B;

    // Instantiate the DUT
    forwarding_unit dut (
        .Rs1_idex(Rs1_idex),
        .Rs2_idex(Rs2_idex),
        .reg_write_en_exmem(reg_write_en_exmem),
        .Rd_exmem(Rd_exmem),
        .reg_write_en_memwb(reg_write_en_memwb),
        .Rd_memwb(Rd_memwb),
        .forward_A(forward_A),
        .forward_B(forward_B)
    );

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("forwarding_unit.vcd");
        $dumpvars(0, forwarding_unit_tb);
    end

    // Test stimulus
    initial begin
        $display("--- Starting forwarding_unit Test ---");
        $display("Time | Rs1_IDEX | Rs2_IDEX | EXMEM_WrEn | EXMEM_Rd | MEMWB_WrEn | MEMWB_Rd | Fwd_A | Fwd_B");
        $display("------------------------------------------------------------------------------------------");

        // Initialize signals
        Rs1_idex = 0;
        Rs2_idex = 0;
        reg_write_en_exmem = 0;
        Rd_exmem = 0;
        reg_write_en_memwb = 0;
        Rd_memwb = 0;
        #10; // Allow combinational logic to settle

        // Test Case 1: No hazard (default 00, 00)
        Rs1_idex = 4'd1;
        Rs2_idex = 4'd2;
        #10;
        $display("%0t | %h | %h | %b | %h | %b | %h | %b | %b",
                 $time, Rs1_idex, Rs2_idex, reg_write_en_exmem, Rd_exmem,
                 reg_write_en_memwb, Rd_memwb, forward_A, forward_B);

        // Test Case 2: EX/MEM hazard for Rs1 (Fwd_A = 01)
        // EX/MEM instruction writes to R1
        reg_write_en_exmem = 1;
        Rd_exmem = 4'd1;
        Rs1_idex = 4'd1; // ID/EX instruction reads R1
        Rs2_idex = 4'd2;
        #10;
        $display("%0t | %h | %h | %b | %h | %b | %h | %b | %b",
                 $time, Rs1_idex, Rs2_idex, reg_write_en_exmem, Rd_exmem,
                 reg_write_en_memwb, Rd_memwb, forward_A, forward_B);

        // Test Case 3: EX/MEM hazard for Rs2 (Fwd_B = 01)
        // EX/MEM instruction writes to R2
        reg_write_en_exmem = 1;
        Rd_exmem = 4'd2;
        Rs1_idex = 4'd1;
        Rs2_idex = 4'd2; // ID/EX instruction reads R2
        #10;
        $display("%0t | %h | %h | %b | %h | %b | %h | %b | %b",
                 $time, Rs1_idex, Rs2_idex, reg_write_en_exmem, Rd_exmem,
                 reg_write_en_memwb, Rd_memwb, forward_A, forward_B);

        // Test Case 4: MEM/WB hazard for Rs1 (Fwd_A = 10) - EX/MEM is clear
        // MEM/WB instruction writes to R3
        reg_write_en_exmem = 0; // Clear EX/MEM
        reg_write_en_memwb = 1;
        Rd_memwb = 4'd3;
        Rs1_idex = 4'd3; // ID/EX instruction reads R3
        Rs2_idex = 4'd4;
        #10;
        $display("%0t | %h | %h | %b | %h | %b | %h | %b | %b",
                 $time, Rs1_idex, Rs2_idex, reg_write_en_exmem, Rd_exmem,
                 reg_write_en_memwb, Rd_memwb, forward_A, forward_B);

        // Test Case 5: MEM/WB hazard for Rs2 (Fwd_B = 10) - EX/MEM is clear
        // MEM/WB instruction writes to R4
        reg_write_en_exmem = 0; // Clear EX/MEM
        reg_write_en_memwb = 1;
        Rd_memwb = 4'd4;
        Rs1_idex = 4'd3;
        Rs2_idex = 4'd4; // ID/EX instruction reads R4
        #10;
        $display("%0t | %h | %h | %b | %h | %b | %h | %b | %b",
                 $time, Rs1_idex, Rs2_idex, reg_write_en_exmem, Rd_exmem,
                 reg_write_en_memwb, Rd_memwb, forward_A, forward_B);

        // Test Case 6: Both EX/MEM and MEM/WB hazard for Rs1 (EX/MEM has priority, Fwd_A = 01)
        // EX/MEM writes R5, MEM/WB writes R5
        reg_write_en_exmem = 1;
        Rd_exmem = 4'd5;
        reg_write_en_memwb = 1;
        Rd_memwb = 4'd5;
        Rs1_idex = 4'd5;
        Rs2_idex = 4'd6;
        #10;
        $display("%0t | %h | %h | %b | %h | %b | %h | %b | %b",
                 $time, Rs1_idex, Rs2_idex, reg_write_en_exmem, Rd_exmem,
                 reg_write_en_memwb, Rd_memwb, forward_A, forward_B);

        // Test Case 7: No forwarding for R0 (R0 is read, but not written to)
        reg_write_en_exmem = 1;
        Rd_exmem = 4'd0; // Attempt to write to R0 (should be ignored by reg_file)
        reg_write_en_memwb = 1;
        Rd_memwb = 4'd0; // Attempt to write to R0
        Rs1_idex = 4'd0;
        Rs2_idex = 4'd0;
        #10;
        $display("%0t | %h | %h | %b | %h | %b | %h | %b | %b",
                 $time, Rs1_idex, Rs2_idex, reg_write_en_exmem, Rd_exmem,
                 reg_write_en_memwb, Rd_memwb, forward_A, forward_B);


        $display("--- forwarding_unit Test Finished ---");
        $finish;
    end

endmodule

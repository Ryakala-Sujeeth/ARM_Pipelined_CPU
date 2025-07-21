// cpu_top_tb.v
// Test bench for the 5-stage pipelined CPU (cpu_top module).
// This test bench will apply clock and reset, and monitor key signals
// to verify the CPU's functionality.

`timescale 1ns / 1ps

module cpu_top_tb;

    // Clock and Reset signals
    reg clk;
    reg reset;

    // Instantiate the CPU Top module
    cpu_top dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100 MHz clock)
    end

    // Test sequence
    initial begin
        // Apply reset
        reset = 1;
        #10; // Hold reset for a short period
        reset = 0; // Release reset

        // Monitor CPU state for a number of clock cycles
        // Adjust the simulation time based on the program length and pipeline depth
        #1000; // Run for 1000ns (100 clock cycles)

        $finish; // End simulation
    end

    // ---------------------------------------------------------------------
    // Monitoring and Display
    // ---------------------------------------------------------------------
    // Use $monitor to display CPU state at each positive clock edge.
    // This will help in debugging and observing pipeline flow.

    // ---------------------------------------------------------------------
    // Monitoring and Display (CORRECTED)
    // ---------------------------------------------------------------------
    initial begin
        $dumpfile("cpu_waves.vcd"); // Specify the VCD file for waveform viewing
        $dumpvars(0, cpu_top_tb);   // Dump all variables in the test bench and its hierarchy

        // CORRECTED: Updated paths to match the revised cpu_top and its sub-modules.
         $monitor("Time=%0t | PC=%h | IF/ID_Instr=%h | EX_ALU_Result=%h | WB_Write_Data=%h | R1=%h | R2=%h | R3=%h | R4=%h | R5=%h | R6=%h",
             $time,
             dut.if_s.pc,                  // Correct path to PC
             dut.if_id_r.instr_out,        // Correct path to instruction in IF/ID
             dut.ex_mem_r.alu_result_out,  // Correct path to ALU result in EX/MEM
             dut.mem_wb_r.write_data_out,  // Correct path to the final data for write-back
             dut.id_s.reg_file.registers[1], // Correct: R1
             dut.id_s.reg_file.registers[2], // Correct: R2
             dut.id_s.reg_file.registers[3], // Correct: R3
             dut.id_s.reg_file.registers[4], // Correct: R4
             dut.id_s.reg_file.registers[5], // Correct: R5
             dut.id_s.reg_file.registers[6]  // Correct: R6
            );
    end

endmodule

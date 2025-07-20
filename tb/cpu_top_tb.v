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

    initial begin
        $dumpfile("cpu_waves.vcd"); // Specify the VCD file for waveform viewing
        $dumpvars(0, cpu_top_tb);   // Dump all variables in the test bench and its hierarchy

        // Example of monitoring key signals (add more as needed for debugging)
        $monitor("Time=%0t | PC=%h | IF_ID_Instr=%h | ID_EX_PC=%h | EX_ALU_Result=%h | MEM_Read_Data=%h | WB_Write_Data=%h | R1=%h | R2=%h | R3=%h | R4=%h | R5=%h | R6=%h",
                 $time,
                 dut.if_s.pc,
                 dut.if_id_r.instr_out,
                 dut.id_ex_r.pc_out,
                 dut.ex_mem_r.alu_result_out,
                 dut.mem_wb_r.mem_read_data_out,
                 dut.wb_s.write_data_out_rf,
                 dut.id_s.reg_file.registers[1],
                 dut.id_s.reg_file.registers[2],
                 dut.id_s.reg_file.registers[3],
                 dut.id_s.reg_file.registers[4],
                 dut.id_s.reg_file.registers[5],
                 dut.id_s.reg_file.registers[6]
                );
    end

endmodule

ARM-like 5-Stage Pipelined CPU (Verilog)
Project Overview
This repository contains the Verilog HDL implementation of a 5-stage pipelined CPU, designed to execute a subset of an ARM-like instruction set architecture (ISA). This project was developed as part of an undergraduate curriculum to demonstrate the principles of CPU pipelining, hazard detection, and data forwarding.
Features
5-Stage Pipeline: Implements a classic Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB) pipeline.
Custom ARM-like ISA: Supports a unified 32-bit instruction format with various instruction types:
Data Processing (Register-to-Register): Operations like ADD, SUB, MUL, DIV, MOD, AND, ORR, XOR, BIC (Bit Clear), MVN (Move Not), CMP (Compare), and TST (Test). These instructions operate on two source registers (Rn, Rm) and write the result to a destination register (Rd). They also support an integrated barrel shifter for Rm.
Immediate Instructions: Operations like MVI (Move Immediate), ADDI, SUBI, ANDI, ORI, XORI. These instructions use a register (Rn) and an immediate value for computation, writing the result to a destination register (Rd).
Load/Store Instructions: LDR (Load Register) and STR (Store Register). These instructions facilitate data transfer between registers and memory using a base register (Rn) and an unsigned immediate offset.
Branch Instructions: B (Unconditional Branch), BEQ (Branch if Equal), BNE (Branch if Not Equal), BLT (Branch if Less Than), BGT (Branch if Greater Than). These instructions alter the program flow based on a signed immediate offset.
Hazard Handling:
Data Forwarding (Bypassing): Resolves read-after-write (RAW) data hazards by forwarding results from EX/MEM and MEM/WB stages to the EX stage.
Load-Use Stall: Stalls the pipeline for one cycle to resolve RAW hazards involving load instructions.
Branch Flush: Flushes incorrect instructions from the pipeline upon a taken branch.
Modular Design: The CPU is broken down into well-defined Verilog modules for each pipeline stage, pipeline registers, ALU, register file, and hazard units, promoting readability and maintainability.
ISA Specification
The detailed instruction format and opcode definitions for this custom microprocessor are available in the docs/ISA_Specification.pdf file.
Repository Structure
ARM_Pipelined_CPU/
├── src/                    # Contains all Verilog source files for CPU modules
├── tb/                     # Contains Verilog test benches
├── docs/                   # Documentation, including the ISA specification
├── .gitignore              # Specifies files/directories to ignore in Git
└── README.md               # This README file


Pipelined Stages Explained
This CPU implements a classic 5-stage pipeline to improve instruction throughput:
Instruction Fetch (IF): Fetches the instruction from instruction memory at the address specified by the Program Counter (PC).
Instruction Decode (ID): Decodes the fetched instruction, reads operand values from the register file, and determines control signals for subsequent stages.
Execute (EX): Performs arithmetic and logical operations using the ALU, calculates memory addresses for load/store instructions, and evaluates branch conditions.
Memory Access (MEM): Accesses data memory for load (read) or store (write) operations based on the address calculated in the EX stage.
Write Back (WB): Writes the final result (either from the ALU or data loaded from memory) back to the destination register in the register file.
ARM-like Characteristics vs. Generic RISC/MIPS
While adhering to fundamental RISC (Reduced Instruction Set Computer) principles, this CPU design incorporates several features that are characteristic of the ARM architecture, differentiating it from a more generic RISC or MIPS-like design:
Conditional Execution: A key ARM feature is the cond field in the instruction format, allowing almost all instructions to execute conditionally based on the CPU's flag status (Zero, Negative, Carry, Overflow). This reduces the need for explicit branch instructions for simple conditional operations.
Integrated Barrel Shifter: The imm field in data processing instructions includes shift_type and shift_amt. This allows one of the operands (Rm) to be shifted as part of the same instruction cycle as the ALU operation, a prominent feature of ARM's data path design. In contrast, MIPS typically requires a separate instruction to perform a shift before an arithmetic operation.
Flexible Addressing Modes: Load/Store instructions use a base register (Rn) plus an immediate offset. While common in RISC, the specific encoding and flexibility (e.g., potential for pre/post-indexing, though not fully implemented here) are more aligned with ARM's approach.
Register File Usage: The instruction format clearly distinguishes between two source registers (Rn, Rm) and a destination register (Rd), which is typical for many RISC architectures, including ARM and MIPS. However, the combination with the barrel shifter and conditional execution gives it an ARM flavor.
Differences from MIPS:
MIPS's Simplicity: MIPS instructions generally follow a very rigid 3-operand format, and its pipeline is often simpler due to fewer inter-instruction dependencies.
No Conditional Execution per Instruction: MIPS relies solely on explicit branch instructions (e.g., beq, bne) to handle conditional logic, rather than having a condition code field on every instruction.
Separate Shift Operations: MIPS typically performs shifts as standalone instructions or as part of specific instructions, not as a general pre-ALU operation via a barrel shifter.
This design aims to provide a practical understanding of pipelined CPU design with a flavor of ARM's architectural elegance in its instruction set features.
Simulation and Verification
The CPU design can be simulated and synthesized using Xilinx Vivado.
Prerequisites:
Xilinx Vivado Design Suite installed on your system.
Steps to Simulate (using Xilinx Vivado):
Open Xilinx Vivado: Launch the Vivado Design Suite.
Create a New Project:
Select Create New Project.
Choose RTL Project and click Next.
Specify a project name (e.g., ARM_Pipelined_CPU_Vivado) and location.
Crucially, when prompted, do NOT add source files yet. Click Next.
Add Sources:
In the Add Sources step, select Add or Create Design Sources.
Click Add Files... and navigate to your ARM_Pipelined_CPU/src/ directory. Select all .v files in this directory.
Click Add Files... again and navigate to your ARM_Pipelined_CPU/tb/ directory. Select cpu_top_tb.v.
Ensure cpu_top.v is set as the Top Module for your design sources.
Ensure cpu_top_tb.v is set as the Top Module for your simulation sources.
Add Constraints (Optional for Simulation):
For simulation, constraints are not strictly necessary, but for synthesis and implementation, you would add an XDC file here. Click Next.
Select Device:
Choose an appropriate FPGA device for your target. For simulation, this choice is less critical, but for eventual synthesis, it matters. Click Next and then Finish.
Run Behavioral Simulation:
Once the project is created and sources are added, in the Vivado Flow Navigator (left pane), under Simulation, click Run Behavioral Simulation.
Vivado will compile your Verilog files and launch the simulator. You will see the waveform viewer and a Tcl console.
View Waveforms and Console Output:
In the waveform viewer, you can drag and drop signals from the Scope or Objects window to observe their values over time.
The $display and $monitor outputs from your test bench will appear in the Vivado Tcl Console.
Test Program
The instruction_memory.v file in the src/ directory contains a sample test program written in the custom ISA. This program includes instructions demonstrating:
Register initialization (ADDI)
Arithmetic operations (ADD, SUB with shift)
Load (LDR) and Store (STR) operations
A load-use hazard scenario (handled by forwarding and stalling)
An unconditional branch (B) to loop the program.
Netlist of Modules
A visual representation of the CPU's top-level netlist (interconnections between modules) would be beneficial here. However, as an AI, I cannot directly generate graphical images or diagrams.
You can typically generate a netlist diagram using your synthesis or simulation tools (e.g., Xilinx Vivado's elaborated design view, ModelSim's hierarchy viewer, or dedicated EDA tools). This will show how cpu_top instantiates and connects if_stage, id_stage, ex_stage, mem_stage, wb_stage, pipeline registers, and hazard units.
Contributing
Feel free to fork this repository, open issues, or submit pull requests.
Author
Sujeeth

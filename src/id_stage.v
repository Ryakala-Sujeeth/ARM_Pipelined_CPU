// id_stage.v
// REVISED: Simplified control logic, proper branch handling, and outputting necessary register fields.

module id_stage (
    input wire clk,
    input wire reset,

    // Inputs from IF/ID
    input wire [31:0] instr_in_ifid,
    input wire [31:0] pc_plus_4_in_ifid,

    // Inputs from WB
    input wire       reg_write_en_wb,
    input wire [3:0] write_reg_addr_wb,
    input wire [31:0] write_data_wb,

    // Input from Hazard Unit
    input wire id_ex_nop,

    // Outputs to ID/EX Register
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] imm_ext_out,
    output reg [3:0]  rd_out,
    output reg [3:0]  rn_out,
    output reg [3:0]  rm_out,
    output reg [1:0]  shift_type_out,
    output reg [4:0]  shift_amt_out,

    // Control signal outputs
    output reg reg_write_en_out,
    output reg mem_read_en_out,
    output reg mem_write_en_out,
    output reg mem_to_reg_out,
    output reg alu_src_out,
    output reg alu_invert_rm_out,
    output reg [3:0] alu_op_out,
    output reg branch_out, // Is the instruction a branch?

    // Outputs to cpu_top for hazard/forwarding units
    output wire [3:0] rn_ifid_out,
    output wire [3:0] rm_ifid_out
);

    // --- Instruction Decoding ---
    wire [4:0] opcode;
    wire [3:0] Rn, Rm, Rd;
    wire [10:0] imm;
    wire [1:0] shift_type;
    wire [4:0] shift_amt;

    instruction_decoder decoder (
        .instruction(instr_in_ifid),
        .cond(), // cond is not used in this simplified model, handled in EX
        .opcode(opcode),
        .Rn(Rn),
        .Rm(Rm),
        .Rd(Rd),
        .imm(imm),
        .shift_type(shift_type),
        .shift_amt(shift_amt)
    );

    assign rn_ifid_out = Rn;
    assign rm_ifid_out = Rm;

    // --- Register File ---
    wire [31:0] read_data1, read_data2;

    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .reg_write_en(reg_write_en_wb),
        .write_reg_addr(write_reg_addr_wb),
        .write_data(write_data_wb),
        .read_reg1_addr(Rn),
        .read_reg2_addr(Rm),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // --- Control Logic ---
    always @(*) begin
        // Default control signals (for a NOP)
        reg_write_en_out  = 1'b0;
        mem_read_en_out   = 1'b0;
        mem_write_en_out  = 1'b0;
        mem_to_reg_out    = 1'b0;
        alu_src_out       = 1'b0;
        alu_invert_rm_out = 1'b0;
        alu_op_out        = 4'b0000; // ADD
        branch_out        = 1'b0;

        if (id_ex_nop) begin
            // If hazard unit says insert NOP, keep defaults
        end else begin
            case (opcode)
                // Data Processing (Register) [ADD, SUB, MUL, DIV, MOD, AND, ORR, XOR, BIC, MVN, CMP, TST]
                5'b00000, 5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101, 5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010, 5'b01011: begin
                    reg_write_en_out  = (opcode == 5'b01010 || opcode == 5'b01011) ? 1'b0 : 1'b1; // No write for CMP/TST
                    alu_src_out       = 1'b0; // Use register
                    alu_invert_rm_out = (opcode == 5'b01000); // Invert for BIC
                    alu_op_out        = {1'b0, opcode[3:0]}; // Map directly from ISA
                    if (opcode == 5'b01001) alu_op_out = 4'b1001; // MVN
                    if (opcode == 5'b01010) alu_op_out = 4'b0001; // CMP is SUB
                    if (opcode == 5'b01011) alu_op_out = 4'b0101; // TST is AND
                end
                // Immediate Instructions [MVI, ADDI, SUBI, ANDI, ORI, XORI]
                5'b01100, 5'b01101, 5'b01110, 5'b01111, 5'b10000, 5'b10001: begin
                    reg_write_en_out  = 1'b1;
                    alu_src_out       = 1'b1; // Use immediate
                    if(opcode == 5'b01100) alu_op_out = 4'b1100; // MVI is pass-through
                    else alu_op_out = {1'b0, opcode[3:0]}; // Map others directly
                end
                // Load/Store Instructions
                5'b10010: begin // LDR
                    reg_write_en_out = 1'b1;
                    mem_read_en_out  = 1'b1;
                    mem_to_reg_out   = 1'b1;
                    alu_src_out      = 1'b1; // Address is Rn + Imm
                    alu_op_out       = 4'b0000; // ADD for address calc
                end
                5'b10011: begin // STR
                    mem_write_en_out = 1'b1;
                    alu_src_out      = 1'b1; // Address is Rn + Imm
                    alu_op_out       = 4'b0000; // ADD for address calc
                end
                // Branch Instructions
                5'b10100, 5'b10101, 5'b10110, 5'b10111, 5'b11000: begin
                    branch_out       = 1'b1;
                    alu_op_out       = 4'b0001; // Use ALU for comparison (SUB) for conditional branches
                end
            endcase
        end

        // Pass values to the next stage
        pc_plus_4_out  = pc_plus_4_in_ifid;
        read_data1_out = read_data1;
        read_data2_out = read_data2;
        imm_ext_out    = {{21{imm[10]}}, imm}; // Sign-extend immediate
        rd_out         = Rd;
        rn_out         = Rn;
        rm_out         = Rm;
        shift_type_out = shift_type;
        shift_amt_out  = shift_amt;
    end
endmodule

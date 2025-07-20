// alu.v
// This module implements the Arithmetic Logic Unit (ALU) for the CPU.
// It performs various arithmetic, logical, and shift operations,
// and generates ARM-like condition flags (N, Z, C, V).
// CORRECTED: 'operand2_shifted' changed from wire to reg.

module alu (
    input wire [31:0] operand1,      // First operand (e.g., Rn)
    input wire [31:0] operand2,      // Second operand (e.g., Rm_shifted or immediate)
    input wire [3:0] alu_op,         // 4-bit ALU operation code
    input wire [1:0] shift_type,     // 2-bit shift type (00=LSL, 01=LSR, 10=ASR, 11=ROR)
    input wire [4:0] shift_amt,      // 5-bit shift amount
    input wire alu_invert_operand2,  // Control signal to invert operand2 (for BIC, MVN, SUB)

    output reg [31:0] alu_result,    // Result of the ALU operation
    output reg zero_flag,            // Zero flag (Z): result is zero
    output reg negative_flag,        // Negative flag (N): result is negative (MSB is 1)
    output reg carry_flag,           // Carry flag (C): for arithmetic operations (carry-out/borrow)
    output reg overflow_flag         // Overflow flag (V): for signed arithmetic operations
);

    // Internal wire for potentially inverted operand2
    wire [31:0] operand2_shifted_raw; // Operand2 after initial inversion (if any)

    // Internal reg for the shifted operand2 - CHANGED FROM WIRE TO REG
    reg [31:0] operand2_shifted;     // Final operand2 after shifting

    // Internal temporary registers for ALU calculations
    reg [32:0] sum_temp;
    reg [32:0] diff_temp;
    reg [31:0] temp_sub_result;
    reg [31:0] temp_and_result;


    // Apply inversion to operand2 if alu_invert_operand2 is high
    // This is used for BIC (~Rm) and for SUB/CMP (effectively adding ~Rm)
    assign operand2_shifted_raw = alu_invert_operand2 ? ~operand2 : operand2;

    // Shifter Logic (combinational - uses always block, so operand2_shifted must be reg)
    always @(*) begin
        operand2_shifted = operand2_shifted_raw; // Default: no shift

        // Only apply shift if shift_amt is not zero (avoid unnecessary shifts)
        if (shift_amt != 5'b0) begin
            case (shift_type)
                2'b00: begin // LSL (Logical Shift Left)
                    operand2_shifted = operand2_shifted_raw << shift_amt;
                end
                2'b01: begin // LSR (Logical Shift Right)
                    operand2_shifted = operand2_shifted_raw >> shift_amt;
                end
                2'b10: begin // ASR (Arithmetic Shift Right)
                    // Arithmetic shift preserves the sign bit (MSB)
                    operand2_shifted = $signed(operand2_shifted_raw) >>> shift_amt;
                end
                2'b11: begin // ROR (Rotate Right)
                    // Rotate right: bits shifted out from LSB re-enter at MSB
                    operand2_shifted = (operand2_shifted_raw >> shift_amt) |
                                       (operand2_shifted_raw << (32 - shift_amt));
                end
                default: begin
                    // Should not happen with 2-bit type, but for completeness
                    operand2_shifted = operand2_shifted_raw;
                end
            endcase
        end
    end

    // ALU Core Logic (combinational)
    always @(*) begin
        // Default flag values for operations that don't set them explicitly
        zero_flag = 1'b0;
        negative_flag = 1'b0;
        carry_flag = 1'b0;
        overflow_flag = 1'b0;
        alu_result = 32'b0;

        case (alu_op)
            4'b0000: begin // ADD (operand1 + operand2_shifted)
                // Use 33-bit intermediate to detect carry out
                sum_temp = {1'b0, operand1} + {1'b0, operand2_shifted};
                alu_result = sum_temp[31:0];

                // Flags: N, Z, C, V
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                carry_flag = sum_temp[32]; // Carry out from MSB
                overflow_flag = (operand1[31] == operand2_shifted[31]) && (operand1[31] != alu_result[31]);
            end
            4'b0001: begin // SUB (operand1 - operand2_shifted)
                // Subtraction is equivalent to A + (~B + 1)
                // Use 33-bit intermediate to detect carry out (borrow)
                diff_temp = {1'b0, operand1} - {1'b0, operand2_shifted};
                alu_result = diff_temp[31:0];

                // Flags: N, Z, C, V
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                carry_flag = ~diff_temp[32]; // ARM C flag for SUB is set if no borrow (i.e., A >= B)
                overflow_flag = (operand1[31] != operand2_shifted[31]) && (operand1[31] != alu_result[31]);
            end
            4'b0010: begin // MUL (operand1 * operand2_shifted)
                alu_result = operand1 * operand2_shifted;
                // Flags for multiplication usually only include Zero and Negative
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by MUL in ARM, or set to an undefined state.
                // We'll keep them cleared for simplicity.
            end
            4'b0011: begin // DIV (operand1 / operand2_shifted)
                if (operand2_shifted == 32'b0) begin
                    alu_result = 32'hFFFFFFFF; // Indicate error for division by zero
                    // Flags remain default or indicate error
                end else begin
                    alu_result = $signed(operand1) / $signed(operand2_shifted); // Signed division
                    if (alu_result == 32'b0) zero_flag = 1'b1;
                    if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                    // C and V flags are generally unaffected by DIV.
                end
            end
            4'b0100: begin // MOD (operand1 % operand2_shifted)
                if (operand2_shifted == 32'b0) begin
                    alu_result = 32'hFFFFFFFF; // Indicate error for modulo by zero
                end else begin
                    alu_result = $signed(operand1) % $signed(operand2_shifted); // Signed modulo
                    if (alu_result == 32'b0) zero_flag = 1'b1;
                    if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                    // C and V flags are generally unaffected by MOD.
                end
            end
            4'b0101: begin // AND (operand1 & operand2_shifted)
                alu_result = operand1 & operand2_shifted;
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by logical operations.
            end
            4'b0110: begin // ORR (operand1 | operand2_shifted)
                alu_result = operand1 | operand2_shifted;
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by logical operations.
            end
            4'b0111: begin // XOR (operand1 ^ operand2_shifted)
                alu_result = operand1 ^ operand2_shifted;
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by logical operations.
            end
            4'b1000: begin // BIC (Bit Clear: operand1 & ~operand2_shifted)
                // operand2_shifted already has inversion applied from alu_invert_operand2
                alu_result = operand1 & operand2_shifted;
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by logical operations.
            end
            4'b1001: begin // MVN (Move Not: ~operand2_shifted)
                // operand2_shifted already has inversion applied from alu_invert_operand2
                alu_result = operand2_shifted; // Effectively just pass through the inverted Rm
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by logical operations.
            end
            4'b1010: begin // CMP (Compare: operand1 - operand2_shifted, sets flags only)
                // Perform subtraction but do not write result to alu_result
                // Only update flags based on the subtraction result
                diff_temp = {1'b0, operand1} - {1'b0, operand2_shifted};
                temp_sub_result = diff_temp[31:0];

                if (temp_sub_result == 32'b0) zero_flag = 1'b1;
                if (temp_sub_result[31] == 1'b1) negative_flag = 1'b1;
                carry_flag = ~diff_temp[32]; // ARM C flag for SUB is set if no borrow (i.e., A >= B)
                overflow_flag = (operand1[31] != operand2_shifted[31]) && (operand1[31] != temp_sub_result[31]);
                alu_result = 32'b0; // Result is not used for CMP
            end
            4'b1011: begin // TST (Test: operand1 & operand2_shifted, sets flags only)
                // Perform AND but do not write result to alu_result
                // Only update flags based on the AND result
                temp_and_result = operand1 & operand2_shifted;

                if (temp_and_result == 32'b0) zero_flag = 1'b1;
                if (temp_and_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by logical operations.
                alu_result = 32'b0; // Result is not used for TST
            end
            4'b1100: begin // MVI (Move Immediate: operand2_shifted is the immediate)
                alu_result = operand2_shifted; // Pass the immediate value
                if (alu_result == 32'b0) zero_flag = 1'b1;
                if (alu_result[31] == 1'b1) negative_flag = 1'b1;
                // C and V flags are generally unaffected by MVI.
            end
            default: begin
                // Default to 0 and clear flags for unsupported/unknown opcodes
                alu_result = 32'b0;
                zero_flag = 1'b0;
                negative_flag = 1'b0;
                carry_flag = 1'b0;
                overflow_flag = 1'b0;
            end
        endcase
    end

endmodule

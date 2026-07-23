// N-bit ALU. op: 3'b000=ADD, 001=SUB, 010=AND, 011=OR, 100=XOR, 101=SHL.
// Synchronous reset. Registered outputs: result, zero_flag, carry_flag.
module alu #(parameter N = 8) (
    input              clk, rst,
    input  [N-1:0]     a, b,
    input  [2:0]       op,
    output reg [N-1:0] result,
    output reg         zero_flag,
    output reg         carry_flag
);
    // Internal wires and regs
    reg [N-1:0]         sum;
    reg [N-1:0]         diff;
    reg [N-1:0]         result_temp;
    reg [N-1:0]         carry_temp;
    reg [N-1:0]         zero_temp;
    reg [N-1:0]         result_temp_temp;
    reg [N-1:0]         carry_temp_temp;
    reg [N-1:0]         zero_temp_temp;
    reg [N-1:0]         result_temp_temp_temp;
    reg [N-1:0]         carry_temp_temp_temp;
    reg [N-1:0]         zero_temp_temp_temp;
    reg [N-1:0]         result_temp_temp_temp_temp;
    // Main ALU logic
    always @(*) begin
        case (op)
            3'b000: sum = a + b;
            3'b001: sum = a - b;
            3'b010: sum = a & b;
            3'b011: sum = a | b;
            3'b100: sum = a ^ b;
            3'b101: sum = a << 1;
            3'b110: sum = a >> 1;
            3'b111: sum = a >>> 1;
            default: sum = a + b;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: diff = a - b;
            3'b001: diff = a + b;
            3'b010: diff = a & b;
            3'b011: diff = a | b;
            3'b100: diff = a ^ b;
            3'b101: diff = a << 1;
            3'b110: diff = a >> 1;
            3'b111: diff = a >>> 1;
            default: diff = a + b;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: result = sum;
            3'b001: result = sum - diff;
            3'b010: result = sum & diff;
            3'b011: result = sum | diff;
            3'b100: result = sum ^ diff;
            3'b101: result = sum << 1;
            3'b110: result = sum >> 1;
            3'b111: result = sum >>> 1;
            default: result = sum;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b001: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b010: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b011: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b100: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b101: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b110: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b111: zero_flag = (sum == 0)? 1'b1 : 1'b0;
            default: zero_flag = 1'b0;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b001: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b010: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b011: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b100: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b101: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b110: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            3'b111: carry_flag = (sum == 0)? 1'b1 : 1'b0;
            default: carry_flag = 1'b0;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: result_temp = sum;
            3'b001: result_temp = sum - diff;
            3'b010: result_temp = sum & diff;
            3'b011: result_temp = sum | diff;
            3'b100: result_temp = sum ^ diff;
            3'b101: result_temp = sum << 1;
            3'b110: result_temp = sum >> 1;
            3'b111: result_temp = sum >>> 1;
            default: result_temp = sum;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: result_temp_temp = sum;
            3'b001: result_temp_temp = sum - diff;
            3'b010: result_temp_temp = sum & diff;
            3'b011: result_temp_temp = sum | diff;
            3'b100: result_temp_temp = sum ^ diff;
            3'b101: result_temp_temp = sum << 1;
            3'b110: result_temp_temp = sum >> 1;
            3'b111: result_temp_temp = sum >>> 1;
            default: result_temp_temp = sum;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: result_temp_temp_temp = sum;
            3'b001: result_temp_temp_temp = sum - diff;
            3'b010: result_temp_temp_temp = sum & diff;
            3'b011: result_temp_temp_temp = sum | diff;
            3'b100: result_temp_temp_temp = sum ^ diff;
            3'b101: result_temp_temp_temp = sum << 1;
            3'b110: result_temp_temp_temp = sum >> 1;
            3'b111: result_temp_temp_temp = sum >>> 1;
            default: result_temp_temp_temp = sum;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: result_temp_temp_temp_temp = sum;
            3'b001: result_temp_temp_temp_temp = sum - diff;
            3'b010: result_temp_temp_temp_temp = sum & diff;
            3'b011: result_temp_temp_temp_temp = sum | diff;
            3'b100: result_temp_temp_temp_temp = sum ^ diff;
            3'b101: result_temp_temp_temp_temp = sum << 1;
            3'b110: result_temp_temp_temp_temp = sum >> 1;
            3'b111: result_temp_temp_temp_temp = sum >>> 1;
            default: result_temp_temp_temp_temp = sum;
        endcase
    end
    always @(*) begin
        case (op)
            3'b000: zero_temp = 1'b1;
            3'b001: zero_temp = 1'b0;
            3'b010: zero_temp = 1'b0;
            3'b011: zero_temp = 1'b0;
            3'b100: zero_temp = 1'b0
endmodule

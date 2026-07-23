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
    reg [N-1:0] res;
    reg [8:0] a_1, b_1;
    reg [9:0] a_2, b_2;
    reg [N-1:0] b_N;
    reg [2:0] op_add, op_sub, op_and, op_or, op_xor;
    reg [9:0] result_add, result_sub, result_and, result_or, result_xor;
    reg [N-1:0] operand_a, operand_b;
    reg [3:0] i;
    reg [7:0] a_comp, b_comp;
    reg zero_flag_comp, carry_flag_comp;
    // Complementa el numero de operandos.
    always @(*) begin
        if (op_add == 3'b000)
            operand_a = a_comp;
        else if (op_sub == 3'b000)
            operand_a = b_comp;
        else
            operand_a = {~a[N-1], a[N-2:0]};
        if (op_add == 3'b000)
            operand_b = a_comp;
        else if (op_sub == 3'b000)
            operand_b = b_comp;
        else
            operand_b = {~b[N-1], b[N-2:0]};
    end
    // Si el operador es add, suman numeros.
    // Si el operador es subtract, restan numeros.
    always @(*) begin
        if (op_add == 3'b000) begin
            result_add = operand_a + operand_b;
            result_sub = operand_a - operand_b;
        end
        else if (op_sub == 3'b000) begin
            result_add = operand_a - operand_b;
            result_sub = operand_a + operand_b;
        end
        else
            result_add = operand_a * operand_b;
        result_and = operand_a & operand_b;
        result_or  = operand_a | operand_b;
        result_xor = operand_a ^ operand_b;
    end
    // Comprobamos que el resultado de la suma es de la misma longitud que el input.
    always @(*) begin
        if (result_add[N-1] == operand_a[N-1]) begin
            if (result_add[N-2:0] == operand_a[N-2:0])
                $display("\n------------ Tecla arriba ------------\n");
            else
                $display("\n------------ Tecla abajo ------------\n");
        end
        else
            $display("\n------------ Tecla arriba ------------\n");
    end
    // Comprobamos que el resultado de la resta es de la misma longitud que el input.
    always @(*) begin
        if (result_sub[N-1] == operand_a[N-1]) begin
            if (result_sub[N-2:0] == operand_a[N-2:0])
                $display("\n------------ Tecla arriba ------------\n");
            else
                $display("\n------------ Tecla abajo ------------\n");
        end
        else
            $display("\n------------ Tecla arriba ------------\n");
    end
    // Comprobamos que el resultado de AND es de la misma longitud que el input.
    always @(*) begin
        if (result_and[N-1] == operand_a[N-1]) begin
            if (result_and[N-2:0] == operand_a[N-2:0])
                $display("\n------------ Tecla arriba ------------\n");
            else
                $display("\n------------ Tecla abajo ------------\n");
        end
        else
            $display("\n------------ Tecla arriba ------------\n");
    end
    // Comprobamos que el resultado de OR es de la misma longitud que el input.
    always @(*) begin
        if (result_or[N-1] == operand_a[N-1]) begin
            if (result_or[N-2:0] == operand_a[N-2:0])
                $display("\n------------ Tecla arriba ------------\n");
            else
                $display("\n------------ Tecla abajo ------------\n");
        end
        else
            $display("\n------------ Tecla arriba ------------\n");
    end
    // Comprobamos que el resultado de XOR es de la misma longitud que el input.
    always @(*) begin
        if (result_xor[N-1] == operand_a[N-1]) begin
            if (result_xor[N-2:0] == operand_a[N-2:0])
                $display("\n------------ Tecla arriba ------------\n");
            else
                $display("\n------------ Tecla abajo ------------\n");
        end
        else
            $display("\n------------ Tecla arriba ------------\n");
    end
    // Comparator.
    always @(*) begin
        a_comp = operand_a;
        b_comp = operand_b;
    end
    // Comparator.
    always @(*) begin
        if (a_comp == b_comp)
            $display("\n------------ Tecla cercana ------------\n");
        else
            $display("\n------------ Tecla fuera de cercana ------------\n");
    end
    // Comparator.
    always @(*) begin
        if (a_comp < b_comp)
            $display("\n------------ Tecla atras ------------\n");
        else
            $display("\n------------ Tecla detras ------------\n");
    end
    // Comparator.
    always @(*) begin
        if (a_comp <= b_comp)
            $display("\n------------ Tecla dentro de cercana ------------\n");
        else
            $display("\n------------ Tecla fuera de cercana ------------\n");
    end
    // Comparator.
    always @(*) begin
        if (a_comp >= b_comp)
            $display("\n------------ Tecla atras ------------\n");
        else
            $display("\n------------ Tecla detras ------------\n");
    end
    // Comparator.
    always @(*) begin
        if (a_comp > b_comp)
            $display("\n------------ Tecla atras ------------\n");
        else
            $display("\n------------ Tecla detras ------------\n");
    end
    // Comparator.
    always @(*) begin
        if (a_comp < b_comp)
            $display("\n------------ Tecla atras ------------\n");
        else
            $display("\n------------ Tecla detras ------------\n");
    end
    // Comparator.
    always @(*) begin
        if (a_comp <= b_comp)
            $display("\n------------ Tecla atras ------------\n");
        else
            $display("\n------------ Tecla detras ------------\n");
    end
    // Comparator.
    always @(*) begin
        if (a_comp > b_comp)
            $display("\n------------ Tecla atras ------------\n");
        else
            $display("\n------------ Tecla detras ------------\n");
    end
    //
endmodule

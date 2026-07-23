// AES MixColumns: GF(2^8) matrix multiply on each of 4 columns. Combinational.
module aes_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);
    // input/output declarations
    reg [7:0] state_out_reg [0:31];
    reg [7:0] state_out_reg_reg [0:31];
    reg [31:0] temp_reg [0:31];
    reg [127:0] state_in_reg;
    //registers
    integer i;
    //assign state
    assign state_out = state_out_reg;
    //assign state_out = state_out_reg_reg;
    //initialize
    initial begin
        for(i=0; i<32; i=i+1)begin
            state_out_reg[i] = 8'h00;
            state_out_reg_reg[i] = 8'h00;
        end
        state_in_reg = 128'h00;
    end
    //main mixcolumns
    always @(*) begin
        //add_round_key
        state_in_reg = state_in;
        for(i=0; i<32; i=i+1)begin
            state_out_reg[i] = state_in_reg[4*i+:4];
        end
        //mix
        state_out_reg_reg[0] = mix_cols(state_out_reg[0]);
        state_out_reg_reg[1] = mix_cols(state_out_reg[1]);
        state_out_reg_reg[2] = mix_cols(state_out_reg[2]);
        state_out_reg_reg[3] = mix_cols(state_out_reg[3]);
        state_out_reg_reg[4] = mix_cols(state_out_reg[4]);
        state_out_reg_reg[5] = mix_cols(state_out_reg[5]);
        state_out_reg_reg[6] = mix_cols(state_out_reg[6]);
        state_out_reg_reg[7] = mix_cols(state_out_reg[7]);
        state_out_reg_reg[8] = mix_cols(state_out_reg[8]);
        state_out_reg_reg[9] = mix_cols(state_out_reg[9]);
        state_out_reg_reg[10] = mix_cols(state_out_reg[10]);
        state_out_reg_reg[11] = mix_cols(state_out_reg[11]);
        state_out_reg_reg[12] = mix_cols(state_out_reg[12]);
        state_out_reg_reg[13] = mix_cols(state_out_reg[13]);
        state_out_reg_reg[14] = mix_cols(state_out_reg[14]);
        state_out_reg_reg[15] = mix_cols(state_out_reg[15]);
        state_out_reg_reg[16] = mix_cols(state_out_reg[16]);
        state_out_reg_reg[17] = mix_cols(state_out_reg[17]);
        state_out_reg_reg[18] = mix_cols(state_out_reg[18]);
        state_out_reg_reg[19] = mix_cols(state_out_reg[19]);
        state_out_reg_reg[20] = mix_cols(state_out_reg[20]);
        state_out_reg_reg[21] = mix_cols(state_out_reg[21]);
        state_out_reg_reg[22] = mix_cols(state_out_reg[22]);
        state_out_reg_reg[23] = mix_cols(state_out_reg[23]);
        state_out_reg_reg[24] = mix_cols(state_out_reg[24]);
        state_out_reg_reg[25] = mix_cols(state_out_reg[25]);
        state_out_reg_reg[26] = mix_cols(state_out_reg[26]);
        state_out_reg_reg[27] = mix_cols(state_out_reg[27]);
        state_out_reg_reg[28] = mix_cols(state_out_reg[28]);
        state_out_reg_reg[29] = mix_cols(state_out_reg[29]);
        state_out_reg_reg[30] = mix_cols(state_out_reg[30]);
        state_out_reg_reg[31] = mix_cols(state_out_reg[31]);
    end
    //function g
    function [7:0] g(input [7:0] in);
        begin
            if(in[7]==1'b0)
                g = 8'h1b;
            else
                g = 8'h0;
        end
    endfunction
    //function h
    function [7:0] h(input [7:0] in);
        begin
            if(in[7]==1'b1)
                h = 8'h6b;
            else
                h = 8'h0;
        end
    endfunction
    //function mixw
    function [7:0] mixw(input [7:0] w);
        begin
            mixw = {w[6:0],g(w[7:1])};
        end
    endfunction
    //function mixcolumns
    function [127:0] mix_cols(input [127:0] cols);
        reg [7:0] cols_reg [0:31];
        integer i;
        begin
            for(i=0; i<32; i=i+1)begin
                cols_reg[i] = cols[4*i+:4];
            end
            mix_cols = {cols_reg[0],cols_reg[1],cols_reg[2],cols_reg[3],cols_reg[4],cols_reg[5],cols_reg[6],cols_reg[7],cols_reg[8],cols_reg[9],cols_reg[10],cols_reg[11],cols_reg[12],cols_reg[13],cols_reg[14],cols_reg[15],cols_reg[16],cols_reg[17],cols_reg[18],cols_reg[19],cols_reg[20],cols_reg[21],cols_reg[22],cols_reg[23],cols_reg[24],cols_reg[25],cols_reg[26],cols_reg[27],cols_reg[28],cols_reg[29],cols_reg[30],cols_reg[31]};
        end
    endfunction

endmodule

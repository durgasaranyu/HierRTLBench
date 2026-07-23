// 8-point FFT twiddle factor ROM. 4 entries W8^0..W8^3 in Q1.15.
// W8^0=(32767,0), W8^1=(23170,-23170), W8^2=(0,-32767), W8^3=(-23170,-23170).
module fft_twiddle_rom (
    input  [1:0] idx,
    output reg signed [15:0] tw_re, tw_im
);
    always@(*) begin
        case(idx)
            2'd0: tw_re = 16'h7ff5; tw_im = 16'h7ff5;
            2'd1: tw_re = 16'h7ffd; tw_im = 16'h7ffd;
            2'd2: tw_re = 16'h7fff; tw_im = 16'h7fff;
            2'd3: tw_re = 16'h7ffd; tw_im = 16'h7ffd;
            default: tw_re = 0; tw_im = 0;
        endcase
    end
endmodulemodule dsp48_mult #(
    parameter integer DIN1_WIDTH = 16,
    parameter integer DIN2_WIDTH = 16,
    parameter integer DOUT_WIDTH = 32
) (
    input wire clk,
    input wire rst,
    //
    input wire [DIN1_WIDTH-1:0] din1,
    input wire [DIN2_WIDTH-1:0] din2,
    input wire din_valid,
    //
    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);
/*  the dsp48e has 3 registers.. two at the input and one at the 
    output
*/
reg [DIN1_WIDTH-1:0] din1_reg_0=0, din1_reg_1=0;
reg [DIN2_WIDTH-1:0] din2_reg_0=0, din2_reg_1=0;
reg din_valid_r=0;
always@(posedge clk)begin
    din1_reg_0 <= din1;
    din2_reg_0 <= din2;
    din_valid_r <= din_valid;
end
reg [DOUT_WIDTH-1:0] acc=0;
reg acc_valid=0;
always@(posedge clk)begin
    if(rst)begin
        acc <= 0;
        acc_valid <=0;
    end
    else if(din_valid_r)begin
        acc_valid <=1;
        if(add_zero_r[0])begin
            if(acc==0)
                acc <= din1_reg_0+din2_reg_0;
            else
                acc <= acc+din1_reg_0+din2_reg_0;
        end
        else
            acc <= acc+din1_reg_0+din2_reg_0;
    end
    else
        acc_valid <=0;
end
reg [DOUT_WIDTH-1:0] dout_r=0;
reg dout_valid_r=0;
always@(posedge clk)begin
    dout_valid_r <= acc_valid;
    if(rst)begin
        dout_r <= 0;
    end
    else if(add_zero_r[1])begin
        //dout_r <= acc;
        dout_r <= {acc[DOUT_WIDTH-1], acc[DOUT_WIDTH-1:DOUT_WIDTH-DIN_WIDTH]};
    end
    else
        dout_r <= acc;
end
assign dout = dout_r;
assign dout_valid = dout_valid_r;
endmodulemodule dedispersor #(
    parameter N_CHANNELS=8, //pow of 2
    parameter [32*N_CHANNELS-1:0] DELAY_ARRAY = {32'd2,32'd3,32'd4,32'd5,32'd6,32'd7,32'd8,32'd9}, //ch8,ch7,...ch0
    parameter DIN_WIDTH = 32
) (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [DIN_WIDTH-1:0] dout,
    output wire dout_valid
);
reg [$clog2(N_CHANNELS)-1:0] addr_counter=0;
always@(posedge clk)begin
    if(rst)
        addr_counter <=0;
    else if(din_valid)
        addr_counter <= addr_counter+1;
    else
        addr_counter <= addr_counter;
end
//check!!
reg dout_valid_r=0;
always@(posedge clk)begin
    dout_valid_r <= (addr_counter==0)&& din_valid;
end
assign dout_valid = dout_valid_r;
genvar i;
generate
for(i=0; i<N_CHANNELS; i=i+1)begin: dedispersor_loop
    //wire valid_block;
    //assign valid_block = ((addr_counter==i) && din_valid);
    reg valid_block=0;
    reg [DIN_WIDTH-1:0] din_block[0:DIN_WIDTH-1];
    always@(posedge clk)begin
        valid_block <= (addr_counter==i) && din_valid;
        if(valid_block)begin
            din_block[0] <= din;
            din_block[1] <= din_block[0];
            din_block[2] <= din_block[0];
            din_block[3] <= din_block[0];
            din_block[4] <= din_block[0];
            din_block[5] <= din_block[0];
            din_block[6] <= din_block[0];
            din_block[7] <= din_block[0];
            din_block[8] <= din_block[0];
            din_block[9] <= din_block[0];
            din_block[10] <= din_block[0];
            din_block[11] <= din_block[0];
            din_block[12] <= din_block[0];
            din_block[13] <= din_block[0];
            din_block[14] <= din_block[0];
            din_block[15] <= din_block[0];
            din_block[16] <= din_block[0];
            din_block[17] <= din_block[0];
            din_block[18] <= din_block[0];
            din_block[19] <= din_block[0];
            din_block[20] <= din_block[0];
            din_block[21] <= din_block[0];
            din_block[22] <= din_block[0];
            din_block[23] <= din_block[0];
            din_block[24] <= din_block[0];
            din_block[25] <= din_block[0];
            din_block[26] <= din_block[0];
            din_block[27] <= din_block[0];
            din_block[28] <= din_block[0];
            din_block[29] <= din_block[0];
            din_block[30] <= din_block[0];
            din_block[31] <= din_block[0];
        end
    end
    reg [DIN_WIDTH-1:0] dout_r=0;
    always@(posedge clk)begin
        dout_r <= din_block[addr_counter];
    end
    assign dout[DIN_WIDTH*i+:DIN_WIDTH]= dout_r;
end
endgenerate
reg [$clog2(N_CHANNELS)-1:0] addr_counter=0;
always@(posedge clk)begin
    if(rst)
        addr_counter <=0;
    else if(din_valid)
        addr_counter <= addr_counter+1;
    
endmodule

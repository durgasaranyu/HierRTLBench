// 8-point fixed-point FFT top. Cooley-Tukey DIT, 3 stages, Q1.15 complex arithmetic.
// Output is in bit-reversed order.
module fft8 (
    input  signed [127:0] xre_flat, xim_flat,
    output signed [127:0] Xre_flat, Xim_flat
);
    reg signed [15:0] xre [0:7], xim [0:7];
    reg signed [15:0] xre_temp [0:7], xim_temp [0:7];
    reg signed [15:0] xre_temp2 [0:7], xim_temp2 [0:7];
    integer i;
    always @(*) begin
        xre[0]   = xre_flat[127:120];
        xre[1]   = xre_flat[119:112];
        xre[2]   = xre_flat[111:104];
        xre[3]   = xre_flat[103:96];
        xre[4]   = xre_flat[95:88];
        xre[5]   = xre_flat[87:80];
        xre[6]   = xre_flat[79:72];
        xre[7]   = xre_flat[71:64];
        xim[0]   = xim_flat[127:120];
        xim[1]   = xim_flat[119:112];
        xim[2]   = xim_flat[111:104];
        xim[3]   = xim_flat[103:96];
        xim[4]   = xim_flat[95:88];
        xim[5]   = xim_flat[87:80];
        xim[6]   = xim_flat[79:72];
        xim[7]   = xim_flat[71:64];
    end
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp[i]   = xre[i]   + xre[i+4];
            xre_temp[i+4] = xre[i]   - xre[i+4];
            xim_temp[i]   = xim[i]   + xim[i+4];
            xim_temp[i+4] = xim[i]   - xim[i+4];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i]   = xre_temp[i]   + xre_temp[i+8];
            xre_temp2[i+8] = xre_temp[i]   - xre_temp[i+8];
            xim_temp2[i]   = xim_temp[i]   + xim_temp[i+8];
            xim_temp2[i+8] = xim_temp[i]   - xim_temp[i+8];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+16] = xre_temp2[i]   + xre_temp2[i+16];
            xre_temp2[i+16+8] = xre_temp2[i]   - xre_temp2[i+16];
            xim_temp2[i+16] = xim_temp2[i]   + xim_temp2[i+16];
            xim_temp2[i+16+8] = xim_temp2[i]   - xim_temp2[i+16];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+32] = xre_temp2[i+16]   + xre_temp2[i+24];
            xre_temp2[i+32+16] = xre_temp2[i+16]   - xre_temp2[i+24];
            xim_temp2[i+32] = xim_temp2[i+16]   + xim_temp2[i+24];
            xim_temp2[i+32+16] = xim_temp2[i+16]   - xim_temp2[i+24];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+64] = xre_temp2[i+32]   + xre_temp2[i+56];
            xre_temp2[i+64+32] = xre_temp2[i+32]   - xre_temp2[i+56];
            xim_temp2[i+64] = xim_temp2[i+32]   + xim_temp2[i+56];
            xim_temp2[i+64+32] = xim_temp2[i+32]   - xim_temp2[i+56];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+128] = xre_temp2[i+64]   + xre_temp2[i+96];
            xre_temp2[i+128+64] = xre_temp2[i+64]   - xre_temp2[i+96];
            xim_temp2[i+128] = xim_temp2[i+64]   + xim_temp2[i+96];
            xim_temp2[i+128+64] = xim_temp2[i+64]   - xim_temp2[i+96];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+192] = xre_temp2[i+128]   + xre_temp2[i+160];
            xre_temp2[i+192+128] = xre_temp2[i+128]   - xre_temp2[i+160];
            xim_temp2[i+192] = xim_temp2[i+128]   + xim_temp2[i+160];
            xim_temp2[i+192+128] = xim_temp2[i+128]   - xim_temp2[i+160];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+256] = xre_temp2[i+192]   + xre_temp2[i+224];
            xre_temp2[i+256+192] = xre_temp2[i+192]   - xre_temp2[i+224];
            xim_temp2[i+256] = xim_temp2[i+192]   + xim_temp2[i+224];
            xim_temp2[i+256+192] = xim_temp2[i+192]   - xim_temp2[i+224];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+320] = xre_temp2[i+256]   + xre_temp2[i+288];
            xre_temp2[i+320+256] = xre_temp2[i+256]   - xre_temp2[i+288];
            xim_temp2[i+320] = xim_temp2[i+256]   + xim_temp2[i+288];
            xim_temp2[i+320+256] = xim_temp2[i+256]   - xim_temp2[i+288];
        end
        for (i = 0; i < 8; i = i + 1) begin
            xre_temp2[i+384] = xre_temp2[i+320]   + xre_temp2[i+352];
            xre_temp2[i+384+320] = xre_temp2[i+320]   - xre_temp2[i+352];
            xim_temp2[i+384] = xim_temp2[i+320]   + xim_temp2[i+352];
            xim_temp2[i+384+320] = xim_temp2[i+320
endmodule

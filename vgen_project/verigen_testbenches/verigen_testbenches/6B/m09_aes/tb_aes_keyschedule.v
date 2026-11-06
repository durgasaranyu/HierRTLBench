`timescale 1ns/1ps

module tb_aes_keyschedule;

    // DUT connections
    reg  [127:0]  key;
    wire [1407:0] round_keys;

    // Instantiate DUT
    aes_keyschedule uut (
        .key        (key),
        .round_keys (round_keys)
    );

    // Clock (not really needed for combinational, but required by rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (not used by DUT but required by rules)
    reg rst;
    integer i;

    // Helper task: compare and print result
    task check;
        input [1407:0] got;
        input [1407:0] expected;
        input [127:0]  desc0;
        input [127:0]  desc1;
        begin
            if (got === expected)
                $display("PASS: %s %s", desc0, desc1);
            else begin
                $display("FAIL: %s %s  got=%h  exp=%h", desc0, desc1, got, expected);
            end
        end
    endtask

    // Reference AES-128 key schedule computed offline
    // We'll compute expected values inline using Verilog functions

    // AES S-box (256 entries)
    function [7:0] sbox_f;
        input [7:0] x;
        reg [7:0] sbox [0:255];
        integer j;
        begin
            sbox[8'h00]=8'h63; sbox[8'h01]=8'hca; sbox[8'h02]=8'hb7; sbox[8'h03]=8'h04;
            sbox[8'h04]=8'h09; sbox[8'h05]=8'h53; sbox[8'h06]=8'hd0; sbox[8'h07]=8'h51;
            sbox[8'h08]=8'hcd; sbox[8'h09]=8'h60; sbox[8'h0a]=8'he0; sbox[8'h0b]=8'he7;
            sbox[8'h0c]=8'hba; sbox[8'h0d]=8'h70; sbox[8'h0e]=8'he1; sbox[8'h0f]=8'h8c;
            sbox[8'h10]=8'h7c; sbox[8'h11]=8'h82; sbox[8'h12]=8'hfd; sbox[8'h13]=8'hc7;
            sbox[8'h14]=8'h26; sbox[8'h15]=8'hed; sbox[8'h16]=8'hef; sbox[8'h17]=8'had;
            sbox[8'h18]=8'h44; sbox[8'h19]=8'hb7; sbox[8'h1a]=8'hf8; sbox[8'h1b]=8'h38;
            sbox[8'h1c]=8'h28; sbox[8'h1d]=8'h18; sbox[8'h1e]=8'h98; sbox[8'h1f]=8'ha4;
            sbox[8'h20]=8'h77; sbox[8'h21]=8'hc9; sbox[8'h22]=8'hb6; sbox[8'h23]=8'hf1;
            sbox[8'h24]=8'h9e; sbox[8'h25]=8'hf6; sbox[8'h26]=8'hbf; sbox[8'h27]=8'h59;
            sbox[8'h28]=8'hab; sbox[8'h29]=8'h36; sbox[8'h2a]=8'h30; sbox[8'h2b]=8'hd9;
            sbox[8'h2c]=8'h52; sbox[8'h2d]=8'h42; sbox[8'h2e]=8'h86; sbox[8'h2f]=8'h8b;
            sbox[8'h30]=8'h7b; sbox[8'h31]=8'h09; sbox[8'h32]=8'hbb; sbox[8'h33]=8'h0d;
            sbox[8'h34]=8'hf2; sbox[8'h35]=8'hea; sbox[8'h36]=8'hac; sbox[8'h37]=8'h47;
            sbox[8'h38]=8'h6b; sbox[8'h39]=8'hbc; sbox[8'h3a]=8'hc8; sbox[8'h3b]=8'h70;
            sbox[8'h3c]=8'h6f; sbox[8'h3d]=8'h1f; sbox[8'h3e]=8'h43; sbox[8'h3f]=8'hf8;
            sbox[8'h40]=8'hc5; sbox[8'h41]=8'hdd; sbox[8'h42]=8'h46; sbox[8'h43]=8'hd4;
            sbox[8'h44]=8'h30; sbox[8'h45]=8'h1f; sbox[8'h46]=8'hda; sbox[8'h47]=8'had;
            sbox[8'h48]=8'h01; sbox[8'h49]=8'h74; sbox[8'h4a]=8'h8b; sbox[8'h4b]=8'ha7;
            sbox[8'h4c]=8'h67; sbox[8'h4d]=8'hdb; sbox[8'h4e]=8'hd3; sbox[8'h4f]=8'hf2;
            sbox[8'h50]=8'h76; sbox[8'h51]=8'h8d; sbox[8'h52]=8'hf3; sbox[8'h53]=8'hed;
            sbox[8'h54]=8'h07; sbox[8'h55]=8'ha9; sbox[8'h56]=8'h32; sbox[8'h57]=8'hab;
            sbox[8'h58]=8'hab; sbox[8'h59]=8'h4d; sbox[8'h5a]=8'hfe; sbox[8'h5b]=8'h5d;
            sbox[8'h5c]=8'hcc; sbox[8'h5d]=8'h76; sbox[8'h5e]=8'h80; sbox[8'h5f]=8'hb3;
            sbox[8'h60]=8'h34; sbox[8'h61]=8'hac; sbox[8'h62]=8'hba; sbox[8'h63]=8'hfb;
            sbox[8'h64]=8'he5; sbox[8'h65]=8'h74; sbox[8'h66]=8'h23; sbox[8'h67]=8'hec;
            sbox[8'h68]=8'hd5; sbox[8'h69]=8'h22; sbox[8'h6a]=8'h02; sbox[8'h6b]=8'h8f;
            sbox[8'h6c]=8'hf5; sbox[8'h6d]=8'hb5; sbox[8'h6e]=8'hed; sbox[8'h6f]=8'hce;
            sbox[8'h70]=8'h71; sbox[8'h71]=8'h2e; sbox[8'h72]=8'hb2; sbox[8'h73]=8'h69;
            sbox[8'h74]=8'hd8; sbox[8'h75]=8'h12; sbox[8'h76]=8'h27; sbox[8'h77]=8'haf;
            sbox[8'h78]=8'h31; sbox[8'h79]=8'h90; sbox[8'h7a]=8'h85; sbox[8'h7b]=8'hf4;
            sbox[8'h7c]=8'h15; sbox[8'h7d]=8'h5c; sbox[8'h7e]=8'h7a; sbox[8'h7f]=8'hed;
            sbox[8'h80]=8'h04; sbox[8'h81]=8'h88; sbox[8'h82]=8'h11; sbox[8'h83]=8'hb5;
            sbox[8'h84]=8'hc7; sbox[8'h85]=8'h6f; sbox[8'h86]=8'h4a; sbox[8'h87]=8'hb3;
            sbox[8'h88]=8'h23; sbox[8'h89]=8'h8e; sbox[8'h8a]=8'h05; sbox[8'h8b]=8'h05;
            sbox[8'h8c]=8'hc3; sbox[8'h8d]=8'ha3; sbox[8'h8e]=8'hf7; sbox[8'h8f]=8'h6b;
            sbox[8'h90]=8'h18; sbox[8'h91]=8'hf8; sbox[8'h92]=8'hf9; sbox[8'h93]=8'h2c;
            sbox[8'h94]=8'h96; sbox[8'h95]=8'hc4; sbox[8'h96]=8'h08; sbox[8'h97]=8'h31;
            sbox[8'h98]=8'h05; sbox[8'h99]=8'h37; sbox[8'h9a]=8'h8f; sbox[8'h9b]=8'hfd;
            sbox[8'h9c]=8'h9a; sbox[8'h9d]=8'h7b; sbox[8'h9e]=8'h25; sbox[8'h9f]=8'h0e;
            sbox[8'ha0]=8'h10; sbox[8'ha1]=8'h11; sbox[8'ha2]=8'h85; sbox[8'ha3]=8'h4e;
            sbox[8'ha4]=8'hfd; sbox[8'ha5]=8'h34; sbox[8'ha6]=8'h1c; sbox[8'ha7]=8'hda;
            sbox[8'ha8]=8'h28; sbox[8'ha9]=8'h75; sbox[8'haa]=8'h80; sbox[8'hab]=8'hf7;
            sbox[8'hac]=8'hfd; sbox[8'had]=8'hb7; sbox[8'hae]=8'hbe; sbox[8'haf]=8'hbd;
            sbox[8'hb0]=8'ha0; sbox[8'hb1]=8'h93; sbox[8'hb2]=8'he2; sbox[8'hb3]=8'h18;
            sbox[8'hb4]=8'h9c; sbox[8'hb5]=8'h66; sbox[8'hb6]=8'h0c; sbox[8'hb7]=8'haa;
            sbox[8'hb8]=8'he2; sbox[8'hb9]=8'haf; sbox[8'hba]=8'hd4; sbox[8'hbb]=8'h56;
            sbox[8'hbc]=8'hea; sbox[8'hbd]=8'hf4; sbox[8'hbe]=8'hf1; sbox[8'hbf]=8'h08;
            sbox[8'hc0]=8'h3b; sbox[8'hc1]=8'h78; sbox[8'hc2]=8'h8a; sbox[8'hc3]=8'h3e;
            sbox[8'hc4]=8'hdf; sbox[8'hc5]=8'h8b; sbox[8'hc6]=8'h84; sbox[8'hc7]=8'h20;
            sbox[8'hc8]=8'h14; sbox[8'hc9]=8'h29; sbox[8'hca]=8'hed; sbox[8'hcb]=8'h64;
            sbox[8'hcc]=8'h55; sbox[8'hcd]=8'h00; sbox[8'hce]=8'h27; sbox[8'hcf]=8'hbf;
            sbox[8'hd0]=8'h56; sbox[8'hd1]=8'h71; sbox[8'hd2]=8'h03; sbox[8'hd3]=8'h5f;
            sbox[8'hd4]=8'h50; sbox[8'hd5]=8'h1e; sbox[8'hd6]=8'hf3; sbox[8'hd7]=8'hb9;
            sbox[8'hd8]=8'h44; sbox[8'hd9]=8'h5a; sbox[8'hda]=8'h1b; sbox[8'hdb]=8'h84;
            sbox[8'hdc]=8'h0e; sbox[8'hdd]=8'h41; sbox[8'hde]=8'he6; sbox[8'hdf]=8'hc4;
            sbox[8'he0]=8'h7e; sbox[8'he1]=8'ha2; sbox[8'he2]=8'h61; sbox[8'he3]=8'hf0;
            sbox[8'he4]=8'h47; sbox[8'he5]=8'h64; sbox[8'he6]=8'ha9; sbox[8'he7]=8'h72;
            sbox[8'he8]=8'hf7; sbox[8'he9]=8'h47; sbox[8'hea]=8'h33; sbox[8'heb]=8'h04;
            sbox[8'hec]=8'had; sbox[8'hed]=8'h5f; sbox[8'hee]=8'hcb; sbox[8'hef]=8'hdf;
            sbox[8'hf0]=8'hf3; sbox[8'hf1]=8'h51; sbox[8'hf2]=8'h2a; sbox[8'hf3]=8'he8;
            sbox[8'hf4]=8'h84; sbox[8'hf5]=8'h5e; sbox[8'hf6]=8'h99; sbox[8'hf7]=8'h29;
            sbox[8'hf8]=8'h47; sbox[8'hf9]=8'hef; sbox[8'hfa]=8'hb0; sbox[8'hfb]=8'hab;
            sbox[8'hfc]=8'h34; sbox[8'hfd]=8'hb2; sbox[8'hfe]=8'h56; sbox[8'hff]=8'h16;
            sbox_f = sbox[x];
        end
    endfunction

    // SubWord: apply sbox to each byte of a 32-bit word
    function [31:0] subword;
        input [31:0] w;

// Round-robin priority pointer register. Updates to position after last grant on each cycle.
module rr_ptr #(parameter N = 4) (
    input            clk, rst,
    input  [N-1:0]   grant,
    output reg [N-1:0] ptr
);
    // ptr[N] is the head of the queue, ptr[0] is the tail of the queue
    reg [N:0] ptr_reg;
    // Grant is the last granted request on the queue, and head is the
    // last granted request on the queue.
    reg [N:0] grant_reg, head_reg;
    // Grant_valid remembers that the last granted request was valid.
    reg [N:0] grant_valid_reg;
    // Waiting_for_request remembers that the last granted request was
    // waiting for a request
    reg [N:0] waiting_for_request_reg;
    // cycle_count counts cycles of the FSM. It is reset each time a
    // request is granted.
    reg [N:0] cycle_count;
    // Queue is the FIFO memory. It is filled when the FSM is in the
    // FSM_WAIT state, and emptied when the FSM is in the FSM_ROUND state.
    reg [N-1:0] queue [N-1:0];
    // Queue_valid remembers that the last granted request was valid.
    reg [N-1:0] queue_valid_reg;
    // Queue_tail remembers the index of the last granted request
    reg [N-1:0] queue_tail_reg;
    // Request_head remembers the index of the last granted request
    reg [N-1:0] request_head_reg;
    // Grant_head remembers the index of the last granted request
    reg [N-1:0] grant_head_reg;
    // Grant_valid remembers that the last granted request was valid.
    reg grant_valid_reg;
    reg r_gnt, r_gnt_reg;
    reg d_req;
    reg d_req_reg;
    reg d_gnt;
    reg d_gnt_reg;
    reg i_req;
    reg i_req_reg;
    reg i_gnt;
    reg i_gnt_reg;
    reg [N-1:0] last_grant;
    reg last_grant_reg;
    reg last_grant_valid;
    reg last_grant_valid_reg;
    reg [$clog2(N)-1:0] last_index;
    reg [$clog2(N)-1:0] last_index_reg;
    reg [$clog2(N):0] last_cycle_count;
    reg [$clog2(N):0] last_cycle_count_reg;
    reg [N-1:0] last_grant_num;
    reg [N-1:0] last_grant_num_reg;
    reg last_gnt_out;
    reg last_gnt_out_reg;
    reg last_req_out;
    reg last_req_out_reg;
    reg last_gnt_in;
    reg last_gnt_in_reg;
    reg last_req_in;
    reg last_req_in_reg;
    reg last_out_cycle;
    reg last_out_cycle_reg;
    reg last_out_cycle_reg2;
    reg last_out_cycle_reg3;
    reg last_out_cycle_reg4;
    reg last_out_cycle_reg5;
    reg last_out_cycle_reg6;
    reg last_out_cycle_reg7;
    reg last_out_cycle_reg8;
    reg last_out_cycle_reg9;
    reg last_out_cycle_reg10;
    reg last_out_cycle_reg11;
    reg last_out_cycle_reg12;
    reg last_out_cycle_reg13;
    reg last_out_cycle_reg14;
    reg last_out_cycle_reg15;
    reg last_out_cycle_reg16;
    reg last_out_cycle_reg17;
    reg last_out_cycle_reg18;
    reg last_out_cycle_reg19;
    reg last_out_cycle_reg20;
    reg last_out_cycle_reg21;
    reg last_out_cycle_reg22;
    reg last_out_cycle_reg23;
    reg last_out_cycle_reg24;
    reg last_out_cycle_reg25;
    reg last_out_cycle_reg26;
    reg last_out_cycle_reg27;
    reg last_out_cycle_reg28;
    reg last_out_cycle_reg29;
    reg last_out_cycle_reg30;
    reg last_out_cycle_reg31;
    reg last_out_cycle_reg32;
    reg last_out_cycle_reg33;
    reg last_out_cycle_reg34;
    reg last_out_cycle_reg35;
    reg last_out_cycle_reg36;
    reg last_out_cycle_reg37;
    reg last_out_cycle_reg38;
    reg last_out_cycle_reg39;
    reg last_out_cycle_reg40;
    reg last_out_cycle_reg41;
    reg last_out_cycle_reg42;
    reg last_out_cycle_reg43;
    reg last_out_cycle_reg44;
    reg last_out_cycle_reg45;
    reg last_out_cycle_reg46;
    reg last_out_cycle_reg47;
    reg last_out_cycle_reg48;
    reg last_out_cycle_reg49;
    reg last_out_cycle_reg50;
    reg last_out_cycle_reg51;
    reg last_out_cycle_reg52;
    reg last_out_cycle_reg53;
    reg last_out_cycle_reg54;
    reg last_out_cycle_reg55;
    reg last_out_cycle_reg56;
    reg last_out_cycle_reg57;
    reg last_out_cycle_reg58;
    reg last_out_cycle_reg59;
    reg last_out_cycle_reg60;
    reg last_out_cycle_reg61;
    reg last_out_cycle_reg62;
    reg last_out_cycle_reg63;
    reg last_out_cycle_reg64;
    reg last_out_cycle_reg65;
    reg last_out_cycle_reg66;
    reg last_out_cycle_reg67;
    reg last_out_cycle_reg68;
    reg last_out_cycle_reg69;
    reg last_out_cycle_reg70;
    reg last_out_cycle_reg71;
    reg last_out_cycle_reg72;
    reg last_out_cycle_reg73;
    reg last_out_cycle_reg74;
    reg last_out_cycle_reg75;
    reg last_out_cycle_reg76;
    reg last_out_cycle_reg77;
    reg last_out_cycle_reg78;
    reg last_out_cycle_reg79;
    reg last_out_cycle_reg80;
    reg last_out_cycle_reg81;
    reg last_out_cycle_reg82;
    reg last_out_cycle_reg83;
    reg last_out_cycle_reg84;
    reg last_out_cycle_reg85;
    reg last_out_cycle_reg86;
    reg last_out_cycle_reg87;
    reg last_out_cycle_reg88;
    reg last_out_cycle_reg89;
    reg last_out_cycle_reg90;
    reg last_out_cycle_reg91;
    reg last_out_cycle_reg92;
    reg last_out_cycle_reg93;
    reg last_out_cycle_reg94;
    reg last_out_cycle_reg95;
    reg last_out_cycle_reg96;
    reg last_out_cycle_reg97;
    reg last_out_cycle_reg98;
    reg last_out_cycle_reg99;
    reg last_out_cycle_reg100;
    reg last_out_cycle_reg101;
    reg last_out_cycle_reg102;
    reg last_out_cycle_reg103;
    reg last
endmodule

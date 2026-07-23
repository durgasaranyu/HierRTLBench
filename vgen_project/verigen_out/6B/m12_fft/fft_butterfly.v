// Single Cooley-Tukey DIT butterfly. Q1.15 complex arithmetic.
// out_hi = in_hi + tw*in_lo, out_lo = in_hi - tw*in_lo. Truncates to 16-bit.
module fft_butterfly (
    input  signed [15:0] re_hi, im_hi, re_lo, im_lo, tw_re, tw_im,
    output signed [15:0] out_re_hi, out_im_hi, out_re_lo, out_im_lo
);
    reg signed [15:0] temp_re_hi, temp_im_hi, temp_re_lo, temp_im_lo;
    reg signed [15:0] temp_tw_re, temp_tw_im;
    reg signed [15:0] out_re_hi_d, out_im_hi_d, out_re_lo_d, out_im_lo_d;
    reg signed [15:0] out_re_hi_temp, out_im_hi_temp, out_re_lo_temp, out_im_lo_temp;
    reg signed [15:0] out_tw_re_temp, out_tw_im_temp;
    always @(*) begin
        // temp_re_hi = 0;
        // temp_re_lo = 0;
        // temp_im_hi = 0;
        // temp_im_lo = 0;
        temp_re_hi = re_hi;
        temp_re_lo = re_lo;
        temp_im_hi = im_hi;
        temp_im_lo = im_lo;
        // out_re_hi = 0;
        // out_re_lo = 0;
        out_re_hi_temp = re_hi;
        out_re_lo_temp = re_lo;
        out_im_hi_temp = im_hi;
        out_im_lo_temp = im_lo;
        out_tw_re_temp = tw_re;
        out_tw_im_temp = tw_im;
        // case(state)
        // 2'b00: begin
        //     temp_re_hi = 0;
        //     temp_re_lo = 0;
        //     temp_im_hi = 0;
        //     temp_im_lo = 0;
        //     out_re_hi = 0;
        //     out_re_lo = 0;
        //     out_im_hi = 0;
        //     out_im_lo = 0;
        //     out_tw_re = 0;
        //     out_tw_im = 0;
        // end
        // 2'b01: begin
        //     temp_re_hi = in_re_hi;
        //     temp_re_lo = in_re_lo;
        //     temp_im_hi = in_im_hi;
        //     temp_im_lo = in_im_lo;
        //     out_re_hi = temp_re_hi;
        //     out_re_lo = temp_re_lo;
        //     out_im_hi = temp_im_hi;
        //     out_im_lo = temp_im_lo;
        //     out_tw_re = temp_re_lo;
        //     out_tw_im = temp_im_lo;
        // end
        // 2'b10: begin
        //     temp_re_hi = in_re_hi;
        //     temp_re_lo = in_re_lo;
        //     temp_im_hi = in_im_hi;
        //     temp_im_lo = in_im_lo;
        //     out_re_hi = temp_re_hi;
        //     out_re_lo = temp_re_lo;
        //     out_im_hi = temp_im_hi;
        //     out_im_lo = temp_im_lo;
        //     out_tw_re = temp_re_lo;
        //     out_tw_im = temp_im_lo;
        // end
        // 2'b11: begin
        //     temp_re_hi = in_re_hi;
        //     temp_re_lo = in_re_lo;
        //     temp_im_hi = in_im_hi;
        //     temp_im_lo = in_im_lo;
        //     out_re_hi = temp_re_hi;
        //     out_re_lo = temp_re_lo;
        //     out_im_hi = temp_im_hi;
        //     out_im_lo = temp_im_lo;
        //     out_tw_re = temp_re_lo;
        //     out_tw_im = temp_im_lo;
        // end
        // endcase
    end
    assign out_re_hi = out_re_hi_temp;
    assign out_re_lo = out_re_lo_temp;
    assign out_im_hi = out_im_hi_temp;
    assign out_im_lo = out_im_lo_temp;
    assign out_tw_re = out_tw_re_temp;
    assign out_tw_im = out_tw_im_temp;
endmodulemodule fft_chann_flag (
    input  wire        clk,       // clk.clk
    input  wire        rst_n,     // rst.reset_n
    input  wire [135:0] data_in,  //  data_in.fifo_data_in
    input  wire        push,      //     push.push_valid
    output wire        push_out,  //       .push_out
    input  wire        pop,       //     pop.pop_valid
    output wire [135:0] data_out   //       .fifo_data_out
);
    // fft_chann_flag.v
    //    `include "fft_chann_flag.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_rx_localparam_defs.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_defs.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_localparam_defs.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_defs.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_top.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_top.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_cancel.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_cancel_top.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_top_cancel.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_data.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_data_top.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_data_cancel.v"
    //    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_data_cancel_top.v"
    //    `include
endmodule

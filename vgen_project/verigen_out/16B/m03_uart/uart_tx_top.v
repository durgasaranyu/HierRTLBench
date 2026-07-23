// UART transmitter top (8-N-1). Parametric CLK_FREQ/BAUD_RATE. tx_start pulses send.
module uart_tx #(parameter CLK_FREQ=50000000, parameter BAUD_RATE=115200) (
    input       clk, rst, tx_start,
    input [7:0] tx_data,
    output      tx, busy
);
    localparam  baud_rate = CLK_FREQ/BAUD_RATE;
    localparam  baud_cnt  = $clog2(baud_rate);
    reg [baud_cnt-1:0] baud_cnt_r;
    reg        baud_tick;
    reg [7:0]  tx_data_r;
    reg        tx_r;
    reg        busy_r;
    assign     tx = tx_r;
    assign     busy = busy_r;
    always @(posedge clk) begin
        if (rst) begin
            baud_cnt_r <= 0;
            baud_tick  <= 0;
            tx_data_r  <= 0;
            tx_r       <= 1;
            busy_r     <= 0;
        end else begin
            tx_data_r <= tx_data;
            if (tx_start) begin
                tx_r       <= 1;
                busy_r     <= 1;
                baud_cnt_r <= 0;
                baud_tick  <= 0;
            end else if (baud_cnt_r == 0) begin
                baud_cnt_r <= baud_cnt;
                baud_tick  <= 1;
                if (baud_tick) begin
                    baud_cnt_r <= baud_cnt_r - 1;
                end
            end else begin
                tx_r       <= 0;
                busy_r     <= 0;
            end
        end
    end

endmodule

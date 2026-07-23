// UART transmitter top (8-N-1). Parametric CLK_FREQ/BAUD_RATE. tx_start pulses send.
module uart_tx #(parameter CLK_FREQ=50000000, parameter BAUD_RATE=115200) (
    input       clk, rst, tx_start,
    input [7:0] tx_data,
    output      tx, busy
);
    reg [7:0] tx_data_r;
    reg        tx_start_r;
    reg        tx_start_s;
    reg        tx_s;
    reg        busy_r;
    reg        busy_s;
    reg        busy_t;
    reg        busy_s_r;
    reg        busy_s_s;
    reg        busy_t_r;
    reg        busy_t_s;
    reg        busy_t_s_r;
    reg        busy_t_s_s;
    always @(posedge clk) begin
        if (rst) begin
            tx_start_r <= 0;
            tx_start_s <= 0;
            tx_s <= 0;
            busy_r <= 0;
            busy_s <= 0;
            busy_t <= 0;
            busy_s_r <= 0;
            busy_s_s <= 0;
            busy_t_r <= 0;
            busy_t_s <= 0;
            busy_t_s_r <= 0;
            busy_t_s_s <= 0;
        end else begin
            tx_start_r <= tx_start;
            tx_start_s <= tx_start_r;
            tx_s <= tx_start_s;
            busy_r <= tx_start_s;
            busy_s <= busy_r;
            busy_t <= busy_s;
            busy_s_r <= busy_s;
            busy_s_s <= busy_s_r;
            busy_t_r <= busy_s_s;
            busy_t_s <= busy_t_r;
            busy_t_s_r <= busy_t_s;
            busy_t_s_s <= busy_t_s_r;
        end
    end
    always @(posedge clk) begin
        tx_data_r <= tx_data;
    end
    always @(posedge clk) begin
        tx_start_s <= tx_start;
        tx_start_s_r <= tx_start_s;
        tx_s <= tx_start_s_r;
        busy_s_r <= busy_s;
        busy_s_s <= busy_s_r;
        busy_t_r <= busy_s_s;
        busy_t_s <= busy_t_r;
        busy_t_s_r <= busy_t_s;
        busy_t_s_s <= busy_t_s_r;
    end
    assign tx = tx_s;
    assign busy = busy_s_s;

endmodule

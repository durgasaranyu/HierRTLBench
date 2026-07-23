// 8-bit UART shift register. Loads byte on load. Shifts LSB first on shift_en.
module uart_tx_shift (
    input        clk, rst,
    input        load, shift_en,
    input  [7:0] data,
    output       serial_out,
    output       empty
);
    parameter  parity =  `UartParityType;
    parameter  width  =  `UartWidth;
    parameter  shift  =  `UartShift;
    reg [width-1:0] data_reg;
    reg [shift-1:0] shift_reg;
    reg [7:0]       bit_counter;
    reg [7:0]       parity_counter;
    reg [3:0]       state;
    reg [3:0]       parity_state;
    assign empty = (bit_counter == 0);
    assign serial_out = data[0];
    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 0;
            shift_reg <= 0;
            bit_counter <= 0;
            parity_counter <= 0;
            state <= 0;
            parity_state <= 0;
        end
        else begin
            if (load) begin
                data_reg <= data;
                shift_reg <= 0;
                bit_counter <= 0;
                parity_counter <= 0;
            end
            else if (shift_en) begin
                shift_reg[0] <= parity_counter[0];
                shift_reg[1] <= parity_counter[1];
                shift_reg[2] <= parity_counter[2];
                shift_reg[3] <= parity_counter[3];
                shift_reg[4] <= parity_counter[4];
                shift_reg[5] <= parity_counter[5];
                shift_reg[6] <= parity_counter[6];
                shift_reg[7] <= parity_counter[7];
                parity_counter <= {parity_counter[6:0], 1'b0};
                bit_counter <= bit_counter + 1;
                if (bit_counter == 0) begin
                    if (parity == `UartParityType_defaultEncoding_NONE) begin
                        parity_state <= `UartParityState_defaultEncoding_IDLE;
                    end
                    else begin
                        parity_state <= `UartParityState_defaultEncoding_STOP;
                    end
                end
                else if (bit_counter == 1) begin
                    parity_state <= `UartParityState_defaultEncoding_START;
                end
                else begin
                    if (parity == `UartParityType_defaultEncoding_ODD) begin
                        parity_state <= `UartParityState_defaultEncoding_ODD;
                    end
                    else begin
                        parity_state <= `UartParityState_defaultEncoding_EVEN;
                    end
                end
            end
            else begin
                shift_reg <= shift_reg;
                parity_counter <= parity_counter;
                bit_counter <= bit_counter;
                parity_state <= parity_state;
            end
            if (rst) begin
                state <= `UartCtrlTxState_defaultEncoding_IDLE;
            end
            else begin
                if (parity_state == `UartParityState_defaultEncoding_ODD) begin
                    parity_counter <= {parity_counter[0], parity_counter[1:1]};
                end
                else begin
                    parity_counter <= parity_counter;
                end
                case (state)
                    `UartCtrlTxState_defaultEncoding_IDLE : begin
                        if (parity_state == `UartParityState_defaultEncoding_ODD) begin
                            parity_counter <= {parity_counter[0], parity_counter[1:1]};
                        end
                        else begin
                            parity_counter <= parity_counter;
                        end
                        if (load) begin
                            state <= `UartCtrlTxState_defaultEncoding_START;
                        end
                        else begin
                            state <= `UartCtrlTxState_defaultEncoding_IDLE;
                        end
                    end
                    `UartCtrlTxState_defaultEncoding_START : begin
                        if (parity_state == `UartParityState_defaultEncoding_ODD) begin
                            parity_counter <= {parity_counter[0], parity_counter[1:1]};
                        end
                        else begin
                            parity_counter <= parity_counter;
                        end
                        if (parity == `UartParityType_defaultEncoding_NONE) begin
                            parity_state <= `UartParityState_defaultEncoding_IDLE;
                        end
                        else begin
                            parity_state <= `UartParityState_defaultEncoding_STOP;
                        end
                        state <= `UartCtrlTxState_defaultEncoding_DATA;
                    end
                    `UartCtrlTxState_defaultEncoding_DATA : begin
                        if (parity_state == `UartParityState_defaultEncoding_ODD) begin
                            parity_counter <= {parity_counter[0], parity_counter[1:1]};
                        end
                        else begin
                            parity_counter <= parity_counter;
                        end
                        if (parity == `UartParityType_defaultEncoding_NONE) begin
                            parity_state <= `UartParityState_defaultEncoding_IDLE;
                        end
                        else begin
                            parity_state <= `UartParityState_defaultEncoding_STOP;
                        end
                        if (bit_counter == bit_count) begin
                            state <= `UartCtrlTxState_defaultEncoding_PARITY;
                        end
                        else begin
                            state <= `UartCtrlTxState_defaultEncoding_DATA;
                        end
                    end
                    `UartCtrlTxState_defaultEncoding_PARITY : begin
                        if (parity_state == `UartParityState_defaultEncoding_ODD) begin
                            parity_counter <= {parity_counter[0], parity_counter[1:1]};
                        end
                        else begin
                            parity_counter <= parity_counter;
                        end
                        if (parity == `UartParityType_defaultEncoding_NONE) begin
                            parity_state <= `UartParityState_defaultEncoding_IDLE;
                        end
                        else begin
                            parity_state <= `UartParityState_defaultEncoding_STOP;
                        end
                        state <= `UartCtrlTxState_defaultEncoding_STOP;
                    end
                    default : begin
                        if (parity_state == `UartParityState_defaultEncoding_ODD) begin
                            parity_counter <= {parity_counter[0], parity_counter[1:1]};
                        end
                        else begin
                            parity_counter <= parity_counter;
                        end
                        parity_state <= `UartParityState_defaultEncoding_IDLE;
                        state <= `UartCtrlTxState_defaultEncoding_IDLE;
                    end
                endcase
            end
        end
    end
endmodulemodule UartCtrlRx (
    input               clk,
    input               rst,
    // UART lines
    input               uart_rxd,
    output reg          uart_rxd_out,
    // Modem lines
    input               rxd_in,
    output reg          rxd_out,
    // Line status
    output reg [3:0]    modem_inputs,
    // Line control
    input               cts,
    input               dtr,
    // Receive buffer
    input               uart_rx,
    // Receive buffer full
    output reg          uart_rx_full,
    // Receive buffer empty
    output reg          uart_rx_empty,
    // Receive buffer [7:0]
    output reg [7:0]    uart_rx_data
);
    parameter  parity =  `UartParityType;
    parameter  stop  =  `UartStopType;
    reg [3:0]   r_parity_errors;
    reg [3:0]   r_parity_errors_cnt;
    reg [7:0]   r_uart_rx_data;
    reg [7:0]   r_uart_rx_data_cnt;
    reg [7:0]   r_uart_rx_data_tmp;
    reg [7
endmodule

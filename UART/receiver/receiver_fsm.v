module receiver_fsm #(
    parameter n = 8,
    parameter CLK_FREQ = 1000,
    parameter BAUD_RATE = 10
)(
    input clk,
    input rst,
    input UART_EN_N,
    input rx,
    output start_valid,
    output stop_valid,
    output sipo_enable,
    output load_out,
    output rx_busy,
    output rx_done,
    output rx_error,
    output [3:0] bit_count_out
);

localparam BIT_CLKS = CLK_FREQ / BAUD_RATE;
localparam HALF_BIT_CLKS = BIT_CLKS / 2;

localparam IDLE      = 2'd0;
localparam START_BIT = 2'd1;
localparam DATA_BITS = 2'd2;
localparam STOP_BIT  = 2'd3;

reg [1:0] state;
reg [15:0] clk_count;
reg [3:0] bit_count;
reg rx_sync1, rx_sync;

always @(posedge clk) begin
    if (rst || UART_EN_N) begin
        rx_sync1 <= 1'b1;
        rx_sync  <= 1'b1;
    end else begin
        rx_sync1 <= rx;
        rx_sync  <= rx_sync1;
    end
end

assign start_valid   = (state == START_BIT) && (clk_count == HALF_BIT_CLKS - 1) && (!rx_sync) && (bit_count == 4'd0);
assign stop_valid    = (state == STOP_BIT) && (clk_count == BIT_CLKS - 1) && (rx_sync) && (bit_count == n - 1);
assign sipo_enable   = (state == DATA_BITS) && (clk_count == BIT_CLKS - 1);
assign load_out      = stop_valid;
assign rx_done       = stop_valid;
assign rx_busy       = (state != IDLE);
assign rx_error      = (state == STOP_BIT) && (clk_count == BIT_CLKS - 1) && (!rx_sync);
assign bit_count_out = bit_count;

always @(posedge clk) begin
    if (rst || UART_EN_N) begin
        state      <= IDLE;
        clk_count  <= 16'd0;
        bit_count  <= 4'd0;
    end else begin
        case (state)
            IDLE: begin
                clk_count <= 16'd0;
                bit_count <= 4'd0;
                if (!rx_sync)
                    state <= START_BIT;
                else
                    state <= IDLE;
            end

            START_BIT: begin
                if (clk_count == HALF_BIT_CLKS - 1) begin
                    clk_count <= 16'd0;
                    if (!rx_sync)
                        state <= DATA_BITS;
                    else
                        state <= IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            DATA_BITS: begin
                if (clk_count == BIT_CLKS - 1) begin
                    clk_count <= 16'd0;
                    if (bit_count == n - 1) begin
                        state <= STOP_BIT;
                    end else begin
                        bit_count <= bit_count + 1'b1;
                    end
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            STOP_BIT: begin
                if (clk_count == BIT_CLKS - 1) begin
                    clk_count <= 16'd0;
                    bit_count <= 4'd0;
                    state     <= IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            default: begin
                state     <= IDLE;
                clk_count <= 16'd0;
                bit_count <= 4'd0;
            end
        endcase
    end
end

endmodule

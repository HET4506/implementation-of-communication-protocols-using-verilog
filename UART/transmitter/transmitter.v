module transmitter #(
    parameter BAUD_RATE = 10,
    parameter n = 8,
    parameter CLK_FREQ = 1000
)(
    input clk,
    input rst,
    input UART_EN_N,
    input load,
    input [n-1:0] data_frame,
    output transmitted_signal,
    output tx_ready,
    output tx_busy,
    output tx_done
);

wire [n-1:0] out;
wire baud_tick;
wire load_input;
wire load_piso;
wire piso_shift;
wire baud_rst;
wire baud_en;
wire tx_idle;
wire piso_out;

transmitter_fsm #(.n(n)) fsm (
    .clk(clk),
    .rst(rst),
    .UART_EN_N(UART_EN_N),
    .load(load),
    .baud_tick(baud_tick),
    .tx_ready(tx_ready),
    .tx_busy(tx_busy),
    .tx_done(tx_done),
    .load_input(load_input),
    .load_piso(load_piso),
    .piso_shift(piso_shift),
    .baud_rst(baud_rst),
    .baud_en(baud_en),
    .tx_idle(tx_idle)
);

counter #(.n(16), .MAX_COUNT(CLK_FREQ/BAUD_RATE)) c (
    .clk(clk),
    .rst(rst | UART_EN_N | baud_rst),
    .enable(baud_en & ~UART_EN_N),
    .out_enable(baud_tick)
);

register #(.n(n)) input_register (
    .clk(clk),
    .rst(rst),
    .enable(load_input),
    .data(data_frame),
    .out(out)
);

wire [n+1:0] stream;
assign stream = {1'b1, out, 1'b0};

wire piso_select;
wire piso_enable;

assign piso_select = ~load_piso;
assign piso_enable = load_piso | piso_shift;

parallel_to_serial #(.n(n)) output_register (
    .clk(clk),
    .rst(rst | UART_EN_N),
    .enable(piso_enable),
    .select(piso_select),
    .data_in(stream),
    .out(piso_out)
);

assign transmitted_signal = (UART_EN_N | tx_idle) ? 1'b1 : piso_out;

endmodule

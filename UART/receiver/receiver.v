module receiver #(
    parameter BAUD_RATE = 10,
    parameter n = 8,
    parameter CLK_FREQ = 1000
)(
    input clk,
    input rst,
    input UART_EN_N,
    input rx,
    output [n-1:0] received_signal,
    output rx_valid,
    output rx_busy,
    output rx_done,
    output rx_error
);

wire start_valid;
wire stop_valid;
wire sipo_enable;
wire load_out;
wire [3:0] bit_count;
wire [n-1:0] sipo_out;
wire [n-1:0] parallel_out;

receiver_fsm #(
    .n(n),
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) fsm (
    .clk(clk),
    .rst(rst),
    .UART_EN_N(UART_EN_N),
    .rx(rx),
    .start_valid(start_valid),
    .stop_valid(stop_valid),
    .sipo_enable(sipo_enable),
    .load_out(load_out),
    .rx_busy(rx_busy),
    .rx_done(rx_done),
    .rx_error(rx_error),
    .bit_count_out(bit_count)
);

serial_to_parallel #(.n(n)) sipo (
    .clk(clk),
    .rst(rst | UART_EN_N),
    .enable(sipo_enable),
    .data_in(rx),
    .out(sipo_out)
);

register #(.n(n)) output_register (
    .clk(clk),
    .rst(rst | UART_EN_N),
    .enable(load_out),
    .data(sipo_out),
    .out(parallel_out)
);

assign rx_valid = rx_done;
assign received_signal = UART_EN_N ? {n{1'b0}} : parallel_out;

endmodule

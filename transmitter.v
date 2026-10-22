module transmitter #(parameter BAUD_RATE = 10, parameter n = 8, parameter CLK_FREQ = 1000)(
    input UART_EN_N,
    input clk,rst,
    input load,
    input [n-1:0] data_frame,
    output transmitted_signal
);

wire [n-1:0] out;
wire baud_tick;

counter #(.n(2*n),.MAX_COUNT(CLK_FREQ/BAUD_RATE)) c(
    .clk(clk),
    .rst(rst | UART_EN_N | load),
    .enable(~UART_EN_N),
    .out_enable(baud_tick)
);

register #(.n(n)) input_register(
    .clk(clk),
    .rst(rst),
    .enable(load),
    .data(data_frame),
    .out(out)
);

wire [n+1:0] stream;
wire start_bit,stop_bit;
assign start_bit = 1'b0;
assign stop_bit = 1'b1;

assign stream = {stop_bit,out,start_bit};

wire piso_out;

parallel_to_serial #(.n(n)) output_register(.clk(clk),
    .rst(rst | UART_EN_N),
    .enable(load | baud_tick),
    .select(~load),
    .data_in(stream),
    .out(piso_out)
);

assign transmitted_signal = UART_EN_N ? 1'b1 : piso_out;

endmodule
module transmitter #(parameter n = 8)(
    input start_bit,
    input [n-1:0] data_frame,
    input stop_bit,
    input select,
    input clk, rst,
    output transmitted_signal
);

wire [n-1:0] out;

register #(.n(n)) input_register (
    .clk(clk),
    .rst(rst),
    .data(data_frame),
    .out(out)
);

wire [n+1:0] stream;
assign stream = {stop_bit, out, start_bit};

parallel_to_serial #(.n(n)) output_register (
    .clk(clk),
    .rst(rst),
    .select(select),
    .data(stream),
    .out(transmitted_signal)
);

endmodule

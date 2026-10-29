module serial_to_parallel #(parameter n = 8)(
    input data_in,
    input rst,
    input clk,
    input enable,
    output [n-1:0] out
);

wire [n-1:0] d_in;
wire [n-1:0] q_out;

mux_2_1 mux_msb (
    .a(q_out[n-1]),
    .b(data_in),
    .select(enable),
    .out(d_in[n-1])
);

D_ff dff_msb (
    .clk(clk),
    .rst(rst),
    .D(d_in[n-1]),
    .Q(q_out[n-1])
);

genvar i;
generate
    for (i = 0; i < n - 1; i = i + 1) begin : gen_shift
        mux_2_1 m (
            .a(q_out[i]),
            .b(q_out[i+1]),
            .select(enable),
            .out(d_in[i])
        );
        D_ff d (
            .clk(clk),
            .rst(rst),
            .D(d_in[i]),
            .Q(q_out[i])
        );
    end
endgenerate

assign out = q_out;

endmodule

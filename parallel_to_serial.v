module parallel_to_serial #(parameter n = 8)(
    input [n+1:0] data,
    input select,      
    input rst, clk,
    output out
);

wire [n+1:0] next;
wire [n+1:0] muxin;

genvar i;
generate
    for (i = 0; i <= n; i = i + 1) begin : gen_shift_reg
        mux_2_1 m (
            .a(data[i]),
            .b(muxin[i+1]),
            .select(select),
            .out(next[i])
        );
        D_ff d (
            .clk(clk),
            .rst(rst),
            .D(next[i]),
            .Q(muxin[i])
        );
    end
endgenerate


mux_2_1 m_tail (
    .a(data[n+1]),
    .b(1'b1),           
    .select(select),
    .out(next[n+1])
);
D_ff d_tail (
    .clk(clk),
    .rst(rst),
    .D(next[n+1]),
    .Q(muxin[n+1])
);


assign out = muxin[0];

endmodule

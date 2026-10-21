module register #(parameter n = 8)(
    input [n-1:0] data,
    input clk, rst,
    output [n-1:0] out
);
genvar i;
generate
    for (i = 0; i < n; i = i + 1) begin : gen_reg
        D_ff d(.clk(clk), .rst(rst), .D(data[i]), .Q(out[i]));
    end
endgenerate
endmodule

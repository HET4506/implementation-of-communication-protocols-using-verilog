module parallel_to_serial #(parameter n = 8) (
    input [n+1:0] data_in,
    input enable,clk,rst,select,
    output out
);

wire [n+1:0] mux_in;
wire [n+1:0] mux_out;
wire [n+1:0] d_in;

mux_2_1 mn   (.a(data_in[n+1]), .b(1'b1), .select(select), .out(mux_out[n+1]));                                                                                                                         
mux_2_1 mn_e (.a(mux_in[n+1]),  .b(mux_out[n+1]), .select(enable), .out(d_in[n+1]));                                                                                                                    
D_ff dn      (.rst(rst), .clk(clk), .D(d_in[n+1]), .Q(mux_in[n+1]));

genvar i;
generate
for(i=0;i<=n;i=i+1) begin
    mux_2_1 m(.a(data_in[i]),.b(mux_in[i+1]),.select(select),.out(mux_out[i]));
    mux_2_1 m_e (.a(mux_in[i]),  .b(mux_out[i]),  .select(enable), .out(d_in[i]));
    D_ff d(.rst(rst),.clk(clk),.Q(mux_in[i]),.D(d_in[i]));
end
endgenerate

assign out = mux_in[0];

endmodule
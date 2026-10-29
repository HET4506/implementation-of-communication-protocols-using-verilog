module register #(parameter n = 8)(
    input [n-1:0] data,
    input clk, rst, enable,
    output [n-1:0] out
);
    wire [n-1:0] d_in;                                                                                                                                                                                                                                                                                                                                                                                 
    genvar i;                                                                                                                                                                                               
    generate                                                                                                                                                                                                
        for (i = 0; i < n; i = i + 1) begin : gen_reg                                                                                                                                                       
            mux_2_1 m (.a(out[i]),.b(data[i]),.select(enable),.out(d_in[i]));                                                                                                                            
            D_ff d    (.clk(clk),.rst(rst),.D(d_in[i]),.Q(out[i]));                                                                                                                              
        end                                                                                                                                                                                                 
    endgenerate
endmodule

module D_ff(
    input rst,clk,D,
    output reg Q
);
always @(posedge clk)
begin
    if(!rst)
    Q <= D;
    else 
    Q <= 1'b0;
end
endmodule
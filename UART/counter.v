module counter #(
    parameter n = 8,
    parameter MAX_COUNT = 100
)(
    input clk,
    input rst,
    input enable,
    output reg out_enable
);

reg [n-1:0] count;

always @(posedge clk) begin
    if (rst) begin
        count      <= {n{1'b0}};
        out_enable <= 1'b0;
    end else if (enable) begin
        if (count >= MAX_COUNT - 1) begin
            count      <= {n{1'b0}};
            out_enable <= 1'b1;
        end else begin
            count      <= count + 1'b1;
            out_enable <= 1'b0;
        end
    end else begin
        out_enable <= 1'b0;
    end
end

endmodule

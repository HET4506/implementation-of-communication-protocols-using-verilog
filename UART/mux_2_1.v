module mux_2_1(
    input a, b, select,
    output out
);
assign out = select ? b : a;
endmodule

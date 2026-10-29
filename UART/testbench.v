`timescale 1ns / 1ps

module testbench;

parameter BAUD_RATE = 10;
parameter n = 8;
parameter CLK_FREQ = 100;
localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

reg clk;
reg rst;
reg UART_EN_N;
reg load;
reg [n-1:0] data_frame;

wire transmitted_signal;
wire tx_ready;
wire tx_busy;
wire tx_done;

transmitter #(
    .BAUD_RATE(BAUD_RATE),
    .n(n),
    .CLK_FREQ(CLK_FREQ)
) uut (
    .clk(clk),
    .rst(rst),
    .UART_EN_N(UART_EN_N),
    .load(load),
    .data_frame(data_frame),
    .transmitted_signal(transmitted_signal),
    .tx_ready(tx_ready),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
);

always #5 clk = ~clk;

task write_byte(input [n-1:0] byte_in);
begin
    wait(tx_ready);
    @(posedge clk);
    #1;
    data_frame = byte_in;
    load = 1'b1;
    @(posedge clk);
    #1;
    load = 1'b0;
end
endtask

task verify_uart_frame(input [n-1:0] expected_byte);
    integer j;
    reg [n-1:0] captured_byte;
    begin
        wait(transmitted_signal == 1'b0);
        repeat(CLKS_PER_BIT / 2) @(posedge clk);
        #1;
        if (transmitted_signal !== 1'b0)
            $display("[FAIL] Invalid Start bit: %b", transmitted_signal);

        for (j = 0; j < n; j = j + 1) begin
            repeat(CLKS_PER_BIT) @(posedge clk);
            #1;
            captured_byte[j] = transmitted_signal;
        end

        repeat(CLKS_PER_BIT) @(posedge clk);
        #1;
        if (transmitted_signal !== 1'b1)
            $display("[FAIL] Invalid Stop bit: %b", transmitted_signal);

        if (captured_byte === expected_byte)
            $display("[PASS] Received byte 0x%0h (%b) correctly", captured_byte, captured_byte);
        else
            $display("[FAIL] Expected 0x%0h, Got 0x%0h", expected_byte, captured_byte);
    end
endtask

initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, testbench);

    clk = 0;
    rst = 1;
    UART_EN_N = 0;
    load = 0;
    data_frame = 8'h00;

    #40;
    @(posedge clk);
    #1;
    rst = 0;

    @(posedge clk);
    #1;
    if (transmitted_signal !== 1'b1)
        $display("[FAIL] Idle line not high after reset");

    $display("Test 1: Single byte transmission (0xA5)");
    fork
        write_byte(8'hA5);
        verify_uart_frame(8'hA5);
    join

    wait(!tx_busy);
    repeat(10) @(posedge clk);

    $display("Test 2: Single byte transmission (0x3C)");
    fork
        write_byte(8'h3C);
        verify_uart_frame(8'h3C);
    join

    wait(!tx_busy);
    repeat(10) @(posedge clk);

    $display("Test 3: Back-to-back transmission (0x55 then 0xF0)");
    fork
        begin
            write_byte(8'h55);
            repeat(20) @(posedge clk);
            write_byte(8'hF0);
        end
        begin
            verify_uart_frame(8'h55);
            verify_uart_frame(8'hF0);
        end
    join

    wait(!tx_busy);
    repeat(20) @(posedge clk);

    $display("All tests completed.");
    $finish;
end

endmodule

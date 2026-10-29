`timescale 1ns / 1ps

module testbench_receiver;

parameter BAUD_RATE = 10;
parameter n = 8;
parameter CLK_FREQ = 100;
localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

reg clk;
reg rst;
reg UART_EN_N;
reg load;
reg [n-1:0] tx_data_frame;

wire transmitted_signal;
wire tx_ready;
wire tx_busy;
wire tx_done;

reg rx_override_en;
reg rx_override_val;

wire rx_line = rx_override_en ? rx_override_val : transmitted_signal;

wire [n-1:0] received_signal;
wire rx_valid;
wire rx_busy;
wire rx_done;
wire rx_error;
reg error_detected;

transmitter #(
    .BAUD_RATE(BAUD_RATE),
    .n(n),
    .CLK_FREQ(CLK_FREQ)
) tx_inst (
    .clk(clk),
    .rst(rst),
    .UART_EN_N(UART_EN_N),
    .load(load),
    .data_frame(tx_data_frame),
    .transmitted_signal(transmitted_signal),
    .tx_ready(tx_ready),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
);

receiver #(
    .BAUD_RATE(BAUD_RATE),
    .n(n),
    .CLK_FREQ(CLK_FREQ)
) rx_inst (
    .clk(clk),
    .rst(rst),
    .UART_EN_N(UART_EN_N),
    .rx(rx_line),
    .received_signal(received_signal),
    .rx_valid(rx_valid),
    .rx_busy(rx_busy),
    .rx_done(rx_done),
    .rx_error(rx_error)
);

always #5 clk = ~clk;

task write_byte(input [n-1:0] byte_in);
begin
    wait(tx_ready);
    @(posedge clk);
    #1;
    tx_data_frame = byte_in;
    load = 1'b1;
    @(posedge clk);
    #1;
    load = 1'b0;
end
endtask

task check_received_byte(input [n-1:0] expected_byte);
begin
    wait(rx_done);
    @(posedge clk);
    #1;
    if (received_signal === expected_byte)
        $display("[PASS] Received byte 0x%0h (%b) correctly", received_signal, received_signal);
    else
        $display("[FAIL] Expected 0x%0h, Got 0x%0h", expected_byte, received_signal);
end
endtask

initial begin
    $dumpfile("waveform_receiver.vcd");
    $dumpvars(0, testbench_receiver);

    clk = 0;
    rst = 1;
    UART_EN_N = 0;
    load = 0;
    tx_data_frame = 8'h00;
    rx_override_en = 0;
    rx_override_val = 1;

    #40;
    @(posedge clk);
    #1;
    rst = 0;

    @(posedge clk);
    #1;
    if (rx_busy !== 1'b0 || rx_done !== 1'b0)
        $display("[FAIL] Receiver not idle after reset deassertion");

    $display("Test 1: Single byte transmission & reception (0xA5)");
    fork
        write_byte(8'hA5);
        check_received_byte(8'hA5);
    join

    wait(!tx_busy && !rx_busy);
    repeat(10) @(posedge clk);

    $display("Test 2: Single byte transmission & reception (0x3C)");
    fork
        write_byte(8'h3C);
        check_received_byte(8'h3C);
    join

    wait(!tx_busy && !rx_busy);
    repeat(10) @(posedge clk);

    $display("Test 3: Back-to-back transmission (0x55 then 0xF0)");
    fork
        begin
            write_byte(8'h55);
            repeat(20) @(posedge clk);
            write_byte(8'hF0);
        end
        begin
            check_received_byte(8'h55);
            check_received_byte(8'hF0);
        end
    join

    wait(!tx_busy && !rx_busy);
    repeat(10) @(posedge clk);

    $display("Test 4: False start-bit glitch rejection");
    rx_override_en = 1;
    rx_override_val = 1;
    repeat(5) @(posedge clk);
    @(posedge clk);
    rx_override_val = 0;
    repeat(2) @(posedge clk);
    rx_override_val = 1;
    repeat(15) @(posedge clk);
    if (!rx_busy && !rx_done)
        $display("[PASS] Glitch successfully rejected, receiver remained idle");
    else
        $display("[FAIL] Receiver falsely triggered on noise glitch");

    $display("Test 5: Framing error detection (Stop bit = 0)");
    @(posedge clk);
    rx_override_val = 0;
    repeat(CLKS_PER_BIT) @(posedge clk);
    repeat(n) begin
        rx_override_val = ~rx_override_val;
        repeat(CLKS_PER_BIT) @(posedge clk);
    end
    rx_override_val = 0;
    error_detected = 0;
    repeat(12 * CLKS_PER_BIT) begin
        @(posedge clk);
        if (rx_error)
            error_detected = 1;
    end

    if (error_detected && !rx_done)
        $display("[PASS] Framing error correctly flagged on invalid stop bit");
    else
        $display("[FAIL] Framing error not detected or rx_done asserted falsely");

    repeat(20) @(posedge clk);
    $display("All receiver tests completed.");
    $finish;
end

endmodule

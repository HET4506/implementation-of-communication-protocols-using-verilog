module transmitter_fsm #(parameter n = 8)(
    input clk,
    input rst,
    input UART_EN_N,
    input load,
    input baud_tick,
    output tx_ready,
    output tx_busy,
    output tx_done,
    output load_input,
    output load_piso,
    output piso_shift,
    output baud_rst,
    output baud_en,
    output tx_idle
);

localparam IDLE      = 3'd0;
localparam LOAD_PISO = 3'd1;
localparam START_BIT = 3'd2;
localparam DATA_BITS = 3'd3;
localparam STOP_BIT  = 3'd4;

reg [2:0] state, next_state;
reg [3:0] bit_count;
reg input_valid;

wire load_accepted;
assign load_accepted = load && tx_ready;
assign load_input    = load_accepted;
assign tx_ready      = ~input_valid || (state == LOAD_PISO);
assign tx_busy       = (state != IDLE);
assign tx_done       = (state == STOP_BIT) && baud_tick;

assign load_piso     = (state == LOAD_PISO);
assign piso_shift    = ((state == START_BIT) || (state == DATA_BITS)) && baud_tick;
assign baud_rst      = (state == IDLE) || (state == LOAD_PISO);
assign baud_en       = ~baud_rst;
assign tx_idle       = (state == IDLE) || (state == LOAD_PISO);

always @(posedge clk) begin
    if (rst || UART_EN_N) begin
        input_valid <= 1'b0;
    end else begin
        if (load_accepted)
            input_valid <= 1'b1;
        else if (load_piso)
            input_valid <= 1'b0;
    end
end

always @(posedge clk) begin
    if (rst || UART_EN_N)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        IDLE: begin
            if (input_valid || load_accepted)
                next_state = LOAD_PISO;
            else
                next_state = IDLE;
        end

        LOAD_PISO: begin
            next_state = START_BIT;
        end

        START_BIT: begin
            if (baud_tick)
                next_state = DATA_BITS;
            else
                next_state = START_BIT;
        end

        DATA_BITS: begin
            if (baud_tick && (bit_count == n - 1))
                next_state = STOP_BIT;
            else
                next_state = DATA_BITS;
        end

        STOP_BIT: begin
            if (baud_tick) begin
                if (input_valid || load_accepted)
                    next_state = LOAD_PISO;
                else
                    next_state = IDLE;
            end else begin
                next_state = STOP_BIT;
            end
        end

        default: next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    if (rst || UART_EN_N) begin
        bit_count <= 4'd0;
    end else if (state == DATA_BITS) begin
        if (baud_tick) begin
            if (bit_count == n - 1)
                bit_count <= 4'd0;
            else
                bit_count <= bit_count + 1'b1;
        end
    end else begin
        bit_count <= 4'd0;
    end
end

endmodule

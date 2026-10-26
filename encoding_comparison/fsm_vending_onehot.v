`timescale 1ns/1ps

module fsm_vending_onehot (
    input  wire clk,
    input  wire rst_n,
    input  wire coin_in,
    input  wire select_btn,
    input  wire timeout,
    input  wire [7:0] balance,
    input  wire [7:0] price,
    output reg  collecting_en,
    output reg  dispensing_en,
    output reg  return_change_en,
    output reg  refund_en
);

    // One-hot encoding: 6 trang thai -> 6 bit, moi trang thai 1 bit '1'
    localparam [5:0] S0_IDLE          = 6'b000001;
    localparam [5:0] S1_COLLECTING    = 6'b000010;
    localparam [5:0] S2_SELECT        = 6'b000100;
    localparam [5:0] S3_DISPENSING    = 6'b001000;
    localparam [5:0] S4_RETURN_CHANGE = 6'b010000;
    localparam [5:0] S5_TIMEOUT_REFUND= 6'b100000;

    reg [5:0] state, next_state;

    // ---- State register ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S0_IDLE;
        else
            state <= next_state;
    end

    // ---- Next-state logic ----
    always @(*) begin
        next_state = state;
        case (state)
            S0_IDLE: begin
                if (coin_in)
                    next_state = S1_COLLECTING;
            end

            S1_COLLECTING: begin
                if (timeout)
                    next_state = S5_TIMEOUT_REFUND;
                else if (select_btn)
                    next_state = S2_SELECT;
            end

            S2_SELECT: begin
                if (timeout)
                    next_state = S5_TIMEOUT_REFUND; // FIX: thieu tien + het gio -> hoan tien, khong ket o S2
                else if (balance >= price)
                    next_state = S3_DISPENSING;
            end

            S3_DISPENSING: begin
                if (balance > price)
                    next_state = S4_RETURN_CHANGE;
                else
                    next_state = S0_IDLE;
            end

            S4_RETURN_CHANGE: begin
                next_state = S0_IDLE;
            end

            S5_TIMEOUT_REFUND: begin
                next_state = S0_IDLE;
            end

            default: next_state = S0_IDLE;
        endcase
    end

    // ---- Output logic (Moore) ----
    always @(*) begin
        collecting_en    = (state == S1_COLLECTING);
        dispensing_en    = (state == S3_DISPENSING);
        return_change_en = (state == S4_RETURN_CHANGE);
        refund_en        = (state == S5_TIMEOUT_REFUND);
    end

endmodule

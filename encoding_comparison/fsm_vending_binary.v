`timescale 1ns/1ps

module fsm_vending_binary (
    input  wire clk,
    input  wire rst_n,
    input  wire coin_in,        // co tien duoc bo vao
    input  wire select_btn,     // khach nhan chon hang (out)
    input  wire timeout,        // het thoi gian cho ma chua select
    input  wire [7:0] balance,  // tong tien da bo vao
    input  wire [7:0] price,    // gia san pham da chon
    output reg  collecting_en,  // dang o trang thai cong tien
    output reg  dispensing_en,  // dang nha hang
    output reg  return_change_en, // dang tra tien thua
    output reg  refund_en       // dang hoan tien do timeout
);

    // Binary encoding: 6 trang thai -> 3 bit
    localparam [2:0] S0_IDLE          = 3'b000;
    localparam [2:0] S1_COLLECTING    = 3'b001;
    localparam [2:0] S2_SELECT        = 3'b010;
    localparam [2:0] S3_DISPENSING    = 3'b011;
    localparam [2:0] S4_RETURN_CHANGE = 3'b100;
    localparam [2:0] S5_TIMEOUT_REFUND= 3'b101;

    reg [2:0] state, next_state;

    // ---- State register ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S0_IDLE;
        else
            state <= next_state;
    end

    // ---- Next-state logic ----
    always @(*) begin
        next_state = state; // default: giu trang thai
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
                // balance < price: o lai S2 cho bo them tien, hoac timeout de hoan tien
            end

            S3_DISPENSING: begin
                if (balance > price)
                    next_state = S4_RETURN_CHANGE; // co tien thua
                else
                    next_state = S0_IDLE;          // vua du tien, ve IDLE luon
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

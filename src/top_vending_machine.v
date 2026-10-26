`timescale 1ns / 1ps

module top_vending_machine #(
    parameter TIMEOUT_SEC  = 0,
    parameter PRICE_A      = 1,
    parameter PRICE_B      = 2,
    parameter PRICE_C      = 3,
    parameter MAX_MONEY    = 99
)(
    input  wire clk,
    input  wire reset_n,
    input  wire coin_10k_n,
    input  wire coin_20k_n,
    input  wire coin_50k_n,
    input  wire btn_A_n,
    input  wire btn_B_n,
    input  wire btn_C_n,
    output wire buzzer,
    output wire ds,
    output wire stcp,
    output wire shcp,
    output wire led_product_A,
    output wire led_product_B,
    output wire led_product_C
);
    wire tick_1hz;
    wire tick_1khz;
    wire pulse_10k, pulse_20k, pulse_50k;
    wire pulse_A, pulse_B, pulse_C;
    wire pulse_reset;
    wire [3:0] bcd0, bcd1;

    Chiaxung_1hz u_clk1hz (.clk(clk), .tick_1hz(tick_1hz));
    Chiaxung_N #(.DIV(5)) u_clk1khz (.clk(clk), .tick(tick_1khz));

    // Bo debounce (ban mo phong)
    assign pulse_10k = ~coin_10k_n;
    assign pulse_20k = ~coin_20k_n;
    assign pulse_50k = ~coin_50k_n;
    assign pulse_A = btn_A_n;
    assign pulse_B = btn_B_n;
    assign pulse_C = btn_C_n;
    assign pulse_reset = reset_n;

    // BINARY ENCODING
    localparam [2:0] IDLE           = 3'b000,
                     INSERT_COIN    = 3'b001,
                     SELECT_PRODUCT = 3'b010,
                     TIMEOUT        = 3'b011,
                     BUZZER_ON      = 3'b100,
                     BUZZER_OFF     = 3'b101;

    reg [2:0] current_state, next_state;
    reg [6:0] money;
    reg [3:0] timeout_cnt;
    reg has_money;
    reg [1:0] buzz_count;
    reg [15:0] buzz_delay;
    reg buzz_active;
    reg buzz_state;
    reg [3:0] buzz_duty;
    reg [1:0] selected_product;

    // NEXT STATE LOGIC
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (pulse_reset)
                    next_state = IDLE;
                else if (pulse_10k || pulse_20k || pulse_50k)
                    next_state = INSERT_COIN;
                else if (pulse_A || pulse_B || pulse_C)
                    next_state = SELECT_PRODUCT;
            end

            INSERT_COIN: begin
                if (pulse_reset)
                    next_state = IDLE;
                else if (pulse_A || pulse_B || pulse_C)
                    next_state = SELECT_PRODUCT;
                else if (TIMEOUT_SEC > 0 && timeout_cnt >= TIMEOUT_SEC)
                    next_state = TIMEOUT;
                else if (pulse_10k || pulse_20k || pulse_50k)
                    next_state = INSERT_COIN;
            end

            SELECT_PRODUCT: begin
                if (pulse_reset)
                    next_state = IDLE;
                else if (buzz_active)
                    next_state = BUZZER_ON;
                else if (money < PRICE_A)
                    next_state = IDLE;
                else
                    next_state = INSERT_COIN;
            end

            TIMEOUT: begin
                if (pulse_reset)
                    next_state = IDLE;
                else
                    next_state = IDLE;
            end

            BUZZER_ON: begin
                if (pulse_reset)
                    next_state = IDLE;
                else if (!buzz_active)
                    next_state = BUZZER_OFF;
                else
                    next_state = BUZZER_ON;
            end

            BUZZER_OFF: begin
                if (pulse_reset)
                    next_state = IDLE;
                else
                    next_state = INSERT_COIN;
            end

            default: next_state = IDLE;
        endcase
    end

    // STATE REGISTER
    always @(posedge clk) begin
        if (pulse_reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    assign buzzer = buzz_state;

    // DATAPATH
    always @(posedge clk) begin
        if (pulse_reset) begin
            money <= 0;
            timeout_cnt <= 0;
            has_money <= 0;
            buzz_count <= 0;
            buzz_delay <= 0;
            buzz_active <= 0;
            buzz_state <= 0;
            buzz_duty <= 0;
            selected_product <= 2'b11;
        end else begin
            case (current_state)
                IDLE: begin
                    money <= 0;
                    timeout_cnt <= 0;
                    has_money <= 0;
                    buzz_active <= 0;
                    buzz_state <= 0;
                    buzz_duty <= 0;
                    buzz_delay <= 0;
                    buzz_count <= 0;
                    selected_product <= 2'b11;

                    if (pulse_10k && money < MAX_MONEY) begin
                        money <= money + 1;
                        has_money <= 1;
                    end
                    if (pulse_20k && money <= MAX_MONEY - 2) begin
                        money <= money + 2;
                        has_money <= 1;
                    end
                    if (pulse_50k && money <= MAX_MONEY - 5) begin
                        money <= money + 5;
                        has_money <= 1;
                    end
                end

                INSERT_COIN: begin
                    if (pulse_10k || pulse_20k || pulse_50k || pulse_A || pulse_B || pulse_C) begin
                        timeout_cnt <= 0;
                    end

                    if (pulse_10k && money < MAX_MONEY) begin
                        money <= money + 1;
                        has_money <= 1;
                    end
                    if (pulse_20k && money <= MAX_MONEY - 2) begin
                        money <= money + 2;
                        has_money <= 1;
                    end
                    if (pulse_50k && money <= MAX_MONEY - 5) begin
                        money <= money + 5;
                        has_money <= 1;
                    end

                    if (pulse_A && money >= PRICE_A) begin
                        money <= money - PRICE_A;
                        buzz_count <= 2'd1;
                        buzz_active <= 1;
                        buzz_delay <= 0;
                        buzz_state <= 0;
                        buzz_duty <= 0;
                        selected_product <= 2'b00;
                        if (money - PRICE_A == 0) has_money <= 0;
                    end
                    if (pulse_B && money >= PRICE_B) begin
                        money <= money - PRICE_B;
                        buzz_count <= 2'd2;
                        buzz_active <= 1;
                        buzz_delay <= 0;
                        buzz_state <= 0;
                        buzz_duty <= 0;
                        selected_product <= 2'b01;
                        if (money - PRICE_B == 0) has_money <= 0;
                    end
                    if (pulse_C && money >= PRICE_C) begin
                        money <= money - PRICE_C;
                        buzz_count <= 2'd3;
                        buzz_active <= 1;
                        buzz_delay <= 0;
                        buzz_state <= 0;
                        buzz_duty <= 0;
                        selected_product <= 2'b10;
                        if (money - PRICE_C == 0) has_money <= 0;
                    end

                    if (has_money && tick_1hz && TIMEOUT_SEC > 0) begin
                        timeout_cnt <= timeout_cnt + 1;
                    end
                end

                SELECT_PRODUCT: begin
                    if (pulse_A && money >= PRICE_A) begin
                        money <= money - PRICE_A;
                        buzz_count <= 2'd1;
                        buzz_active <= 1;
                        buzz_delay <= 0;
                        buzz_state <= 0;
                        buzz_duty <= 0;
                        selected_product <= 2'b00;
                        if (money - PRICE_A == 0) has_money <= 0;
                    end
                    if (pulse_B && money >= PRICE_B) begin
                        money <= money - PRICE_B;
                        buzz_count <= 2'd2;
                        buzz_active <= 1;
                        buzz_delay <= 0;
                        buzz_state <= 0;
                        buzz_duty <= 0;
                        selected_product <= 2'b01;
                        if (money - PRICE_B == 0) has_money <= 0;
                    end
                    if (pulse_C && money >= PRICE_C) begin
                        money <= money - PRICE_C;
                        buzz_count <= 2'd3;
                        buzz_active <= 1;
                        buzz_delay <= 0;
                        buzz_state <= 0;
                        buzz_duty <= 0;
                        selected_product <= 2'b10;
                        if (money - PRICE_C == 0) has_money <= 0;
                    end
                end

                TIMEOUT: begin
                    money <= 0;
                    has_money <= 0;
                    timeout_cnt <= 0;
                    selected_product <= 2'b11;
                end

                BUZZER_ON: begin
                    if (buzz_active && tick_1khz) begin
                        if (buzz_duty < 2) begin
                            buzz_duty <= buzz_duty + 1;
                            buzz_state <= 1;
                        end else if (buzz_duty < 4) begin
                            buzz_duty <= buzz_duty + 1;
                            buzz_state <= 0;
                        end else begin
                            buzz_duty <= 0;
                        end

                        buzz_delay <= buzz_delay + 1;

                        if (buzz_delay >= 30) begin
                            buzz_delay <= 0;
                            buzz_count <= buzz_count - 1;
                            buzz_state <= 0;
                            if (buzz_count == 0) begin
                                buzz_active <= 0;
                            end
                        end
                    end
                end

                BUZZER_OFF: begin
                    buzz_state <= 0;
                    buzz_delay <= 0;
                    buzz_duty <= 0;
                end

                default: begin
                end
            endcase
        end
    end

    assign led_product_A = (selected_product == 2'b00);
    assign led_product_B = (selected_product == 2'b01);
    assign led_product_C = (selected_product == 2'b10);

    binary_to_bcd_2digit u_bcd (.bin(money), .bcd0(bcd0), .bcd1(bcd1));
    Display_595_Driver_2digit u_disp (.clk(clk), .bcd0(bcd0), .bcd1(bcd1), .ds(ds), .stcp(stcp), .shcp(shcp));
endmodule

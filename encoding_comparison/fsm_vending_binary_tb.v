`timescale 1ns/1ps

// Testbench tu kiem tra cho fsm_vending_binary
// Dau vao doi sau 1 ns ke tu canh clock, ket qua duoc kiem tra sau khi state da cap nhat
module fsm_vending_binary_tb;

    reg clk;
    reg rst_n;
    reg coin_in;
    reg select_btn;
    reg timeout;
    reg [7:0] balance;
    reg [7:0] price;

    wire collecting_en;
    wire dispensing_en;
    wire return_change_en;
    wire refund_en;

    integer pass_cnt = 0;
    integer fail_cnt = 0;

    fsm_vending_binary dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .coin_in          (coin_in),
        .select_btn       (select_btn),
        .timeout          (timeout),
        .balance          (balance),
        .price            (price),
        .collecting_en    (collecting_en),
        .dispensing_en    (dispensing_en),
        .return_change_en (return_change_en),
        .refund_en        (refund_en)
    );

    // Clock 50 MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // 1 chu ky: cho canh clock, doi 1 ns de state cap nhat xong
    task tick;
    begin
        @(posedge clk);
        #1;
    end
    endtask

    // Kiem tra 4 tin hieu ra: {collecting, dispensing, return_change, refund}
    task expect_out;
        input [3:0] exp;
        input [8*40:1] name;
    begin
        if ({collecting_en, dispensing_en, return_change_en, refund_en} === exp) begin
            pass_cnt = pass_cnt + 1;
            $display("  PASS: %0s", name);
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("  FAIL: %0s | mong doi=%b, thuc te=%b", name, exp,
                     {collecting_en, dispensing_en, return_change_en, refund_en});
        end
    end
    endtask

    task do_reset;
    begin
        rst_n = 0; coin_in = 0; select_btn = 0; timeout = 0; balance = 0; price = 0;
        tick; tick;
        rst_n = 1;
        tick;
    end
    endtask

    // Dua FSM vao S1 COLLECTING
    task go_collecting;
    begin
        coin_in = 1; tick;
        coin_in = 0; tick;
    end
    endtask

    initial begin
        $display("=== TESTBENCH FSM VENDING (binary) ===");
        do_reset;

        $display("[TC1] Sau reset o IDLE, khong tin hieu nao bat");
        expect_out(4'b0000, "IDLE: tat ca output = 0");

        $display("[TC2] IDLE -> COLLECTING khi coin_in = 1");
        go_collecting;
        expect_out(4'b1000, "COLLECTING: collecting_en = 1");

        $display("[TC3] Du tien dung gia (khong thua): COLLECTING -> SELECT -> DISPENSING -> IDLE");
        balance = 8'd10; price = 8'd10;
        select_btn = 1; tick;
        select_btn = 0;
        expect_out(4'b0000, "S2 SELECT: output = 0");
        tick;
        expect_out(4'b0100, "S3 DISPENSING: dispensing_en = 1");
        tick;
        expect_out(4'b0000, "Ve IDLE, khong qua RETURN_CHANGE");

        $display("[TC4] Co tien thua: ... -> DISPENSING -> RETURN_CHANGE -> IDLE");
        do_reset;
        go_collecting;
        balance = 8'd15; price = 8'd10;
        select_btn = 1; tick;
        select_btn = 0; tick;
        expect_out(4'b0100, "S3 DISPENSING (co tien thua)");
        tick;
        expect_out(4'b0010, "S4 RETURN_CHANGE: return_change_en = 1");
        tick;
        expect_out(4'b0000, "Ve IDLE sau khi tra tien thua");

        $display("[TC5] Timeout o COLLECTING: -> TIMEOUT_REFUND -> IDLE");
        do_reset;
        go_collecting;
        timeout = 1; tick;
        timeout = 0;
        expect_out(4'b0001, "S5 TIMEOUT_REFUND: refund_en = 1");
        tick;
        expect_out(4'b0000, "Ve IDLE sau khi hoan tien");

        $display("[TC6] Thieu tien o SELECT: giu nguyen S2, khong dispensing");
        do_reset;
        go_collecting;
        balance = 8'd5; price = 8'd10;
        select_btn = 1; tick;
        select_btn = 0;
        repeat (10) tick;
        expect_out(4'b0000, "Thieu tien: van o S2, output = 0");

        $display("[TC7] Bo them tien o SELECT: du tien thi DISPENSING");
        balance = 8'd10; tick;
        expect_out(4'b0100, "Du tien: vao DISPENSING");
        tick; tick;

        $display("[TC8] Thieu tien + timeout o SELECT: hoan tien (da sua loi ket S2)");
        do_reset;
        go_collecting;
        balance = 8'd5; price = 8'd10;
        select_btn = 1; tick;
        select_btn = 0;
        repeat (3) tick;
        timeout = 1; tick;
        timeout = 0;
        expect_out(4'b0001, "S2 + timeout: vao TIMEOUT_REFUND");
        tick;
        expect_out(4'b0000, "Ve IDLE sau khi hoan tien");

        $display("[TC9] Reset bat dong bo giua chung: ve IDLE ngay");
        do_reset;
        go_collecting;
        #3 rst_n = 0;
        #1;
        expect_out(4'b0000, "Reset khi dang COLLECTING: output = 0");
        rst_n = 1;

        $display("==========================================");
        $display(" KET QUA (binary): %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("==========================================");
        #50;
        $finish;
    end

    initial begin
        $dumpfile("fsm_vending_binary_tb.vcd");
        $dumpvars(0, fsm_vending_binary_tb);
    end

endmodule

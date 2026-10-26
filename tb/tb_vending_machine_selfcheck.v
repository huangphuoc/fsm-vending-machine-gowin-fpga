`timescale 1ns / 1ps

// Testbench tu kiem tra cho top_vending_machine (Moore + Binary)
// Gia tri tien: 10k = 1, 20k = 2, 50k = 5 | Gia: A = 1 (10k), B = 2 (20k), C = 3 (30k)
// Moi nut/dong xu chi nhan 1 xung clock (ban nay khong co debounce/edge detect,
// giu nhieu chu ky se bi cong tien lien tuc).
module tb_vending_machine_selfcheck;
    reg clk = 0;
    reg reset_n;
    reg coin_10k_n, coin_20k_n, coin_50k_n;
    reg btn_A_n, btn_B_n, btn_C_n;
    wire buzzer, ds, stcp, shcp;
    wire led_product_A, led_product_B, led_product_C;

    integer pass_cnt = 0;
    integer fail_cnt = 0;
    reg     buzz_seen;

    top_vending_machine uut (
        .clk(clk), .reset_n(reset_n),
        .coin_10k_n(coin_10k_n), .coin_20k_n(coin_20k_n), .coin_50k_n(coin_50k_n),
        .btn_A_n(btn_A_n), .btn_B_n(btn_B_n), .btn_C_n(btn_C_n),
        .buzzer(buzzer), .ds(ds), .stcp(stcp), .shcp(shcp),
        .led_product_A(led_product_A), .led_product_B(led_product_B), .led_product_C(led_product_C)
    );

    always #10 clk = ~clk;

    // Ghi nhan buzzer co keu it nhat 1 lan
    always @(posedge buzzer) buzz_seen = 1;

    // ---------- Tasks ----------
    task check;
        input [767:0] name;
        input         cond;
        begin
            if (cond) begin
                pass_cnt = pass_cnt + 1;
                $display("[PASS] %0s", name);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[FAIL] %0s | money=%0d led(A,B,C)=%b%b%b state=%0d",
                         name, uut.money, led_product_A, led_product_B, led_product_C, uut.current_state);
            end
        end
    endtask

    task do_reset;
        begin
            @(negedge clk) reset_n = 1;
            @(negedge clk) reset_n = 1;
            @(negedge clk) reset_n = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    task coin10; begin @(negedge clk) coin_10k_n = 0; @(negedge clk) coin_10k_n = 1; repeat (2) @(negedge clk); end endtask
    task coin20; begin @(negedge clk) coin_20k_n = 0; @(negedge clk) coin_20k_n = 1; repeat (2) @(negedge clk); end endtask
    task coin50; begin @(negedge clk) coin_50k_n = 0; @(negedge clk) coin_50k_n = 1; repeat (2) @(negedge clk); end endtask

    // Bam nut roi doi buzzer ket thuc (toi da 5000 chu ky)
    task press_A; begin @(negedge clk) btn_A_n = 1; @(negedge clk) btn_A_n = 0; wait_buzz; end endtask
    task press_B; begin @(negedge clk) btn_B_n = 1; @(negedge clk) btn_B_n = 0; wait_buzz; end endtask
    task press_C; begin @(negedge clk) btn_C_n = 1; @(negedge clk) btn_C_n = 0; wait_buzz; end endtask

    task wait_buzz;
        integer i;
        begin
            repeat (3) @(negedge clk);
            i = 0;
            while (uut.buzz_active && i < 5000) begin
                @(negedge clk);
                i = i + 1;
            end
            repeat (5) @(negedge clk);
        end
    endtask

    // ---------- Kich ban kiem tra ----------
    initial begin
        $dumpfile("tb_vending_machine_selfcheck.vcd");
        $dumpvars(0, tb_vending_machine_selfcheck);

        reset_n = 0;
        coin_10k_n = 1; coin_20k_n = 1; coin_50k_n = 1;
        btn_A_n = 0; btn_B_n = 0; btn_C_n = 0;
        buzz_seen = 0;
        repeat (3) @(negedge clk);

        // TEST 1: RESET
        do_reset;
        check("T1  Reset: money = 0",          uut.money == 0);
        check("T1  Reset: LED A/B/C tat",      {led_product_A, led_product_B, led_product_C} == 3'b000);
        check("T1  Reset: state = IDLE",       uut.current_state == 3'b000);

        // TEST 2-4: NAP TIEN
        coin10;
        check("T2  Nap 10k: money = 1",        uut.money == 1);
        coin20;
        check("T3  Nap 20k: money = 3",        uut.money == 3);
        coin50;
        check("T4  Nap 50k: money = 8",        uut.money == 8);

        // TEST 5: MUA A (10k)
        buzz_seen = 0;
        press_A;
        check("T5  Mua A: money = 7",          uut.money == 7);
        check("T5  Mua A: LED A sang",         {led_product_A, led_product_B, led_product_C} == 3'b100);
        check("T5  Mua A: buzzer co keu",      buzz_seen == 1);
        check("T5  Mua A: buzzer ket thuc",    uut.buzz_active == 0);

        // TEST 6: MUA B (20k)
        buzz_seen = 0;
        press_B;
        check("T6  Mua B: money = 5",          uut.money == 5);
        check("T6  Mua B: LED B sang",         {led_product_A, led_product_B, led_product_C} == 3'b010);
        check("T6  Mua B: buzzer co keu",      buzz_seen == 1);

        // TEST 7: MUA C (30k)
        buzz_seen = 0;
        press_C;
        check("T7  Mua C: money = 2",          uut.money == 2);
        check("T7  Mua C: LED C sang",         {led_product_A, led_product_B, led_product_C} == 3'b001);
        check("T7  Mua C: buzzer co keu",      buzz_seen == 1);

        // TEST 8: KHONG DU TIEN (con 2 = 20k, mua C can 3)
        buzz_seen = 0;
        press_C;
        check("T8  Khong du tien mua C: money giu nguyen = 2", uut.money == 2);
        check("T8  Khong du tien mua C: buzzer khong keu",     buzz_seen == 0);

        // TEST 9: RESET XOA TIEN
        do_reset;
        check("T9  Reset: money = 0",          uut.money == 0);
        check("T9  Reset: LED tat",            {led_product_A, led_product_B, led_product_C} == 3'b000);

        // TEST 10: DU TIEN CHINH XAC (10k mua A -> money = 0)
        coin10;
        press_A;
        check("T10 Mua A bang dung 10k: money = 0", uut.money == 0);
        check("T10 Mua A bang dung 10k: LED A sang", led_product_A == 1);

        // TEST 11: KHONG CO TIEN MA BAM MUA
        do_reset;
        buzz_seen = 0;
        press_A;
        check("T11 Khong co tien, bam A: money = 0", uut.money == 0);
        check("T11 Khong co tien, bam A: LED tat",   {led_product_A, led_product_B, led_product_C} == 3'b000);
        check("T11 Khong co tien, bam A: buzzer khong keu", buzz_seen == 0);

        // KET QUA
        $display("==========================================");
        $display(" KET QUA: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("==========================================");
        $finish;
    end

    // Chong treo
    initial begin
        #5_000_000;
        $display("[TIMEOUT] Mo phong chay qua lau");
        $finish;
    end
endmodule

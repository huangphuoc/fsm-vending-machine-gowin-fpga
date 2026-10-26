`timescale 1ns / 1ps

module Display_595_Driver_2digit (
    input  wire clk,
    input  wire [3:0] bcd0,
    input  wire [3:0] bcd1,
    output wire ds,
    output wire stcp,
    output wire shcp
);
    wire [6:0] seg0, seg1;
    BCD_to_7seg dec0 (.bcd(bcd0), .seg(seg0));
    BCD_to_7seg dec1 (.bcd(bcd1), .seg(seg1));

    reg [16:0] mux_cnt;
    always @(posedge clk) mux_cnt <= mux_cnt + 1;
    wire mux_sel = mux_cnt[16];

    wire [7:0] seg_byte = {1'b1, (mux_sel ? seg1 : seg0)};
    wire [7:0] sel_byte = mux_sel ? 8'b0000_0010 : 8'b0000_0001;
    wire [15:0] r_data = {seg_byte, sel_byte};

    reg sck_r;
    always @(posedge clk) sck_r <= ~sck_r;
    wire sck_plus = (sck_r == 1'b1);

    reg [5:0] SHCP_EDGE_CNT;
    always @(posedge clk) begin
        if (sck_plus) begin
            if (SHCP_EDGE_CNT == 6'd32)
                SHCP_EDGE_CNT <= 0;
            else
                SHCP_EDGE_CNT <= SHCP_EDGE_CNT + 1;
        end
    end

    reg ds_r, sh_cp_r, st_cp_r;
    always @(posedge clk) begin
        case (SHCP_EDGE_CNT)
            0:  begin sh_cp_r<=0; st_cp_r<=0; ds_r<=r_data[15]; end
            1: begin sh_cp_r<=1; end
            2: begin sh_cp_r<=0; ds_r<=r_data[14]; end
            3: begin sh_cp_r<=1; end
            4: begin sh_cp_r<=0; ds_r<=r_data[13]; end
            5: begin sh_cp_r<=1; end
            6: begin sh_cp_r<=0; ds_r<=r_data[12]; end
            7: begin sh_cp_r<=1; end
            8: begin sh_cp_r<=0; ds_r<=r_data[11]; end
            9: begin sh_cp_r<=1; end
            10: begin sh_cp_r<=0; ds_r<=r_data[10]; end
            11: begin sh_cp_r<=1; end
            12: begin sh_cp_r<=0; ds_r<=r_data[9]; end
            13: begin sh_cp_r<=1; end
            14: begin sh_cp_r<=0; ds_r<=r_data[8]; end
            15: begin sh_cp_r<=1; end
            16: begin sh_cp_r<=0; ds_r<=r_data[7]; end
            17: begin sh_cp_r<=1; end
            18: begin sh_cp_r<=0; ds_r<=r_data[6]; end
            19: begin sh_cp_r<=1; end
            20: begin sh_cp_r<=0; ds_r<=r_data[5]; end
            21: begin sh_cp_r<=1; end
            22: begin sh_cp_r<=0; ds_r<=r_data[4]; end
            23: begin sh_cp_r<=1; end
            24: begin sh_cp_r<=0; ds_r<=r_data[3]; end
            25: begin sh_cp_r<=1; end
            26: begin sh_cp_r<=0; ds_r<=r_data[2]; end
            27: begin sh_cp_r<=1; end
            28: begin sh_cp_r<=0; ds_r<=r_data[1]; end
            29: begin sh_cp_r<=1; end
            30: begin sh_cp_r<=0; ds_r<=r_data[0]; end
            31: begin sh_cp_r<=1; end
            32: begin st_cp_r<=1; end
            default: begin st_cp_r<=0; ds_r<=0; sh_cp_r<=0; end
        endcase
    end

    assign ds   = ds_r;
    assign stcp = st_cp_r;
    assign shcp = sh_cp_r;
endmodule

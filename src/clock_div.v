`timescale 1ns / 1ps

module Chiaxung_N #(parameter DIV = 5)(
    input  wire clk,
    output reg  tick = 1'b0
);
    reg [3:0] count = 0;
    always @(posedge clk) begin
        if (count == DIV - 1) begin
            count <= 0;
            tick <= 1'b1;
        end else begin
            count <= count + 1'b1;
            tick <= 1'b0;
        end
    end
endmodule

module Chiaxung_1hz #(parameter CLK_FREQ = 5)(
    input  wire clk,
    output reg  tick_1hz = 1'b0
);
    reg [3:0] count = 4'd0;
    always @(posedge clk) begin
        if (count == CLK_FREQ - 1) begin
            count    <= 4'd0;
            tick_1hz <= 1'b1;
        end else begin
            count    <= count + 1'b1;
            tick_1hz <= 1'b0;
        end
    end
endmodule

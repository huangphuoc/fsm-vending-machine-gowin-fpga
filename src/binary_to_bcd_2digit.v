`timescale 1ns / 1ps

module binary_to_bcd_2digit (
    input  wire [6:0] bin,
    output wire [3:0] bcd0,
    output wire [3:0] bcd1
);
    assign bcd0 = bin % 10;
    assign bcd1 = bin / 10;
endmodule

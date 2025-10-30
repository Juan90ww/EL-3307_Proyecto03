module top_adder (
    input  logic clk,
    input  logic rst_n,
    input  logic [3:0] a2, a1, a0,
    input  logic [3:0] b2, b1, b0,
    input  logic       load,
    input  logic       start_conv,
    output logic [3:0] out_d3, out_d2, out_d1, out_d0,
    output logic       ready
);
    logic [10:0] aval, bval, sum;
    logic conv_done;

    // Conversión de BCD a binario
    modulo_1 convA(
        .clk(clk), .en(load),
        .d2(a2), .d1(a1), .d0(a0),
        .value(aval)
    );

    modulo_1 convB(
        .clk(clk), .en(load),
        .d2(b2), .d1(b1), .d0(b0),
        .value(bval)
    );

    // Suma binaria
    modulo_2 adder(
        .a(aval), .b(bval),
        .sum(sum)
    );

    // Conversión de binario a BCD
    modulo_3 #(.IN_WIDTH(11), .DIGITS(4)) b2b (
        .clk(clk), .rst_n(rst_n), .start(start_conv),
        .bin_in(sum),
        .bcd3(out_d3), .bcd2(out_d2), .bcd1(out_d1), .bcd0(out_d0),
        .done(conv_done)
    );

    assign ready = conv_done;
endmodule

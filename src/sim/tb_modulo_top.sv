module tb;
    timeunit 1ns; timeprecision 1ps;

    logic clk;
    logic rst_n;
    logic [3:0] a2,a1,a0,b2,b1,b0;
    logic load, start_conv, ready;
    logic [3:0] d3,d2,d1,d0;

    // Clock 10ns (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    top_adder dut(
        .clk(clk), .rst_n(rst_n),
        .a2(a2), .a1(a1), .a0(a0),
        .b2(b2), .b1(b1), .b0(b0),
        .load(load), .start_conv(start_conv),
        .out_d3(d3), .out_d2(d2), .out_d1(d1), .out_d0(d0),
        .ready(ready)
    );

    task do_test(input [3:0] A2,A1,A0,B2,B1,B0);
    begin
        a2=A2; a1=A1; a0=A0;
        b2=B2; b1=B1; b0=B0;
        load = 1; @(posedge clk);
        load = 0;
        start_conv = 1; @(posedge clk);
        start_conv = 0;
        wait (ready);
        $display("BCD out = %0d %0d %0d %0d", d3, d2, d1, d0);
        @(posedge clk);
    end
    endtask

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb);

        rst_n = 0;
        load = 0; start_conv = 0;
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("Test 1: 123 + 456 = 579");
        do_test(1,2,3, 4,5,6);

        $display("Test 2: 999 + 999 = 1998");
        do_test(9,9,9, 9,9,9);

        $display("Test 3: 007 + 015 = 0022");
        do_test(0,0,7, 0,1,5);

        $finish;
    end
endmodule

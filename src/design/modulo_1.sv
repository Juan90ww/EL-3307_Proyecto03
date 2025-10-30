module modulo_1 (
    input  logic        clk,
    input  logic        en,
    input  logic [3:0]  d2, d1, d0,
    output logic [10:0] value
);
    always_ff @(posedge clk) begin
    if (en) begin
        logic [10:0] v2, v1;
        v2 = ({7'd0, d2} << 6) + ({7'd0, d2} << 5) + ({7'd0, d2} << 2); // d2*100
        v1 = ({7'd0, d1} << 3) + ({7'd0, d1} << 1);                      // d1*10
        value <= v2 + v1 + {7'd0, d0};
    end
end
endmodule

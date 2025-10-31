module divisor (
    input   logic [3:0] dividendo,
    input   logic [3:0] divisor,
    output  logic [3:0] cociente,
    output  logic [3:0] resto
);
    //localparam N_BITS = $bits(dividendo) - 1;
    logic [3:0] resto4, resto3, resto2, resto1, resto0;
    assign resto4 = 4'b0;
    divisor_resta d3 (
        .dividendo   (dividendo [3]),
        .divisor     (divisor),
        .resto_prima (resto4),
        .cociente    (cociente[3]),
        .resto_ant   (resto3)
    );
    divisor_resta d2 (
        .dividendo   (dividendo [2]),
        .divisor     (divisor),
        .resto_prima (resto3),
        .cociente    (cociente[2]),
        .resto_ant   (resto2)
    );
    divisor_resta d1 (
        .dividendo   (dividendo [1]),
        .divisor     (divisor),
        .resto_prima (resto2),
        .cociente    (cociente[1]),
        .resto_ant   (resto1)
    );
    divisor_resta d0 (
        .dividendo   (dividendo [0]),
        .divisor     (divisor),
        .resto_prima (resto1),
        .cociente    (cociente[0]),
        .resto_ant   (resto0)
    );
    assign resto = resto0;
endmodule
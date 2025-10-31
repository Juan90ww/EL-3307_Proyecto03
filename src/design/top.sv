module top(
    input   logic [3:0] dividendo,
    input   logic [3:0] divisor,
    output  logic [3:0] cociente,
    output  logic [3:0] resto
);
    divisor prueba (
        .dividendo (dividendo),
        .divisor (divisor),
        .cociente (cociente),
        .resto (resto)
    );
endmodule

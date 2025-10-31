module top_teclado(
    input logic clk,         // Reloj de 27 MHz
    input logic rst,         // Reset activo en bajo
    output logic [3:0] anodo,   // Ánodos del display (asumiendo 4 dígitos para el resultado)
    output logic [6:0] seven,  // Segmentos del display
    output logic [3:0] col, // Columnas del teclado
    input logic [3:0] fil    // Filas del teclado
);
    // teclado
    logic [3:0] boton;
    teclado keyboard(
        .clk(clk),
        .rst(rst),
        .filas(fil),
        .columnas(col),
        .boton(boton),
    );
    // Instancia del Display Multiplexado
    display_7seg display (
        .clk(clk),
        .rst(rst),
        .digito({boton, boton, boton, boton}), // Pasa el dato seleccionado al display
        .anodo(anodo),         // Controla qué dígito se enciende
        .seven(seven)            // Controla qué segmentos se encienden
    );

endmodule
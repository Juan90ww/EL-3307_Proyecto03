`timescale 1ns/1ps

module tb_teclado;

    // Entradas del DUT
    logic clk = 0;
    logic [3:0] filas;
    logic [3:0] columnas;

    // Salidas del DUT
    logic [4:0] boton;

    // Instanciación del DUT
    teclado prueba (
        .clk(clk),
        .filas(filas),
        .columnas(columnas),
        .boton(boton)
    );

    initial begin
        // Inicialización
        $display("Tiempo\tfilas\tcolumnas\tboton");

        // Caso 1: boton 7
        filas    = 4'b1101; 
        columnas = 4'b0111;
        #10;
        $display("%0t\t%b\t%b\t%b", $time, filas, columnas, boton);
        
        // Caso 2: boton 8
        filas    = 4'b1101; 
        columnas = 4'b1011;
        #10;
        $display("%0t\t%b\t%b\t%b", $time, filas, columnas, boton);

        // Caso 3: boton 9
        filas    = 4'b1101; 
        columnas = 4'b1101;
        #10;
        $display("%0t\t%b\t%b\t%b", $time, filas, columnas, boton);

        // Caso 4: boton C
        filas    = 4'b1101; 
        columnas = 4'b1110;
        #10;
        $display("%0t\t%b\t%b\t%b", $time, filas, columnas, boton);
        // Finalizar simulación
        $finish;
    end
        initial begin
        $dumpfile("tb_teclado.vcd"); // archivo para GTKWave
        $dumpvars(0, tb_teclado);   // guarda todas las señales del testbench
    end
endmodule

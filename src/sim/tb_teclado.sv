`timescale 1ns/1ps

module tb_teclado;

    // Señales del testbench
    logic       clk;
    logic [3:0] filas;
    logic [3:0] columnas;
    logic [3:0] boton;

    // Instancia del DUT
    teclado dut (
        .clk     (clk),
        .filas   (filas),
        .columnas(columnas),
        .boton   (boton)
    );

    // Reloj: 10 ns de periodo
    initial clk = 0;
    always #5 clk = ~clk;

    // Tarea: presionar una tecla durante varios ciclos y comprobar el valor
    task automatic presionar_tecla(
        input logic [3:0] fila_activar,   // patrón de filas (una en 0)
        input logic [3:0] valor_esperado, // valor esperado en 'boton'
        input string      nombre          // nombre de la tecla para mensajes
    );
        int i;
        bit ok;

        begin
            ok = 0;

            // Simular que la tecla está presionada
            filas = fila_activar;

            // Dejamos pasar varios ciclos para que el escáner recorra columnas
            for (i = 0; i < 16; i++) begin
                @(posedge clk);
                #1; // pequeña espera para estabilizar

                if (boton === valor_esperado) begin
                    ok = 1;
                    $display("OK tecla %s: boton=%b (columnas=%b, filas=%b, t=%0t)",
                             nombre, boton, columnas, filas, $time);
                    break;
                end
            end

            if (!ok) begin
                $error("ERROR tecla %s: esperado=%b, nunca se obtuvo ese valor. Último boton=%b (columnas=%b, filas=%b, t=%0t)",
                       nombre, valor_esperado, boton, columnas, filas, $time);
            end

            // Soltar la tecla
            filas = 4'b1111;
            // Esperar unos ciclos sin tecla
            repeat (4) @(posedge clk);
        end
    endtask

    // Estímulos
    initial begin
        // Inicialización
        filas = 4'b1111;     // ninguna tecla presionada

        // Para evitar 'X' en simulación, inicializamos contador (solo simulación)
        dut.contador = 0;

        // Esperar a que el DUT empiece a escanear
        repeat (8) @(posedge clk);

        // *** FILA 0: filas = 0111 -> 1,2,3,A ***
        presionar_tecla(4'b0111, 4'b0001, "1"); // col=0111
        presionar_tecla(4'b0111, 4'b0010, "2"); // col=1011
        presionar_tecla(4'b0111, 4'b0011, "3"); // col=1101
        presionar_tecla(4'b0111, 4'b0110, "A"); // col=1110 (según tu código, A=0110)

        // *** FILA 1: filas = 1011 -> 4,5,6,B ***
        presionar_tecla(4'b1011, 4'b0100, "4"); // col=0111
        presionar_tecla(4'b1011, 4'b0101, "5"); // col=1011
        presionar_tecla(4'b1011, 4'b0110, "6"); // col=1101
        presionar_tecla(4'b1011, 4'b1011, "B"); // col=1110

        // *** FILA 2: filas = 1101 -> 7,8,9,C ***
        presionar_tecla(4'b1101, 4'b0111, "7"); // col=0111
        presionar_tecla(4'b1101, 4'b1000, "8"); // col=1011
        presionar_tecla(4'b1101, 4'b1001, "9"); // col=1101
        presionar_tecla(4'b1101, 4'b1100, "C"); // col=1110

        // *** FILA 3: filas = 1110 -> *,0,#,D ***
        // Ojo: en tu diseño, *, 0 y # comparten el mismo valor 0000
        presionar_tecla(4'b1110, 4'b0000, "*"); // col=0111
        presionar_tecla(4'b1110, 4'b0000, "0"); // col=1011
        presionar_tecla(4'b1110, 4'b0000, "#"); // col=1101
        presionar_tecla(4'b1110, 4'b1101, "D"); // col=1110

        $display("Fin de la simulación: todas las teclas probadas.");
        $finish;
    end

    // Volcado de señales
    initial begin
        $dumpfile("tb_teclado.vcd");
        $dumpvars(0, tb_teclado);
    end

endmodule

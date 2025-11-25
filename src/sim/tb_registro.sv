`timescale 1ns/1ps

module tb_registro;

    // Parámetros para la simulación
    localparam int N_DEB = 18;                        // debe coincidir con debounce
    localparam int STABLE_CYCLES = (1 << N_DEB) + 50; // algo mayor que 2^N

    // Señales
    logic       clk;
    logic       rst;        // activo en bajo
    logic [3:0] filas;
    logic [3:0] columnas;
    logic [3:0] boton;

    // Instancia del DUT
    registro dut (
        .clk     (clk),
        .rst     (rst),
        .filas   (filas),
        .columnas(columnas),
        .boton   (boton)
    );

    // Generador de reloj: periodo 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Tarea para esperar N ciclos de reloj
    task automatic wait_cycles(input int n);
        int i;
        begin
            for (i = 0; i < n; i++) begin
                @(posedge clk);
            end
        end
    endtask

    initial begin
        // Volcado de señales
        $dumpfile("tb_registro.vcd");
        $dumpvars(0, tb_registro);

        // Inicialización
        rst   = 0;
        filas = 4'b1111; // sin tecla presionada (todas las filas en 1)

        wait_cycles(4);
        rst = 1;
        $display("[%0t] Reset liberado", $time);

        // Esperar a que todo se estabilice un poco
        wait_cycles(20);

        // ==========================
        // TEST 1: reposo inicial
        // ==========================
        if (boton !== 4'b1111) begin
            $error("[%0t] TEST 1 FALLÓ: se esperaba boton=1111 (sin tecla), se obtuvo %b",
                   $time, boton);
        end else begin
            $display("[%0t] TEST 1 OK: boton=%b en reposo", $time, boton);
        end

        // ==========================
        // TEST 2: tecla "5"
        // ==========================
        // Según tu módulo teclado:
        //  - filas=1011 (fila 1 activa en bajo)
        //  - en alguna columna → boton = 0101 (tecla 5)
        $display("[%0t] TEST 2: presionando tecla 5", $time);
        filas = 4'b1011;  // tecla asociada a fila 1

        // Esperar suficiente para:
        //  - debounce (2^N ciclos)
        //  - escaneo del teclado (unas cuantas vueltas)
        wait_cycles(STABLE_CYCLES);

        if (boton !== 4'b0101) begin
            $error("[%0t] TEST 2 FALLÓ: se esperaba boton=0101 (tecla 5), se obtuvo %b",
                   $time, boton);
        end else begin
            $display("[%0t] TEST 2 OK: tecla 5 detectada, boton=%b", $time, boton);
        end

        // ==========================
        // TEST 3: soltar la tecla
        // ==========================
        $display("[%0t] TEST 3: soltando tecla 5", $time);
        filas = 4'b1111;  // sin tecla presionada

        wait_cycles(STABLE_CYCLES);

        if (boton !== 4'b1111) begin
            $error("[%0t] TEST 3 FALLÓ: al soltar se esperaba boton=1111, se obtuvo %b",
                   $time, boton);
        end else begin
            $display("[%0t] TEST 3 OK: botón volvió a 1111 al soltar", $time, boton);
        end

        // ==========================
        // TEST 4: otra tecla (ej. "1")
        // ==========================
        // En tu mapa:
        //  - filas=0111 (fila 0 activa en bajo)
        //  - para una columna → boton=0001 (tecla 1)
        $display("[%0t] TEST 4: presionando tecla 1", $time);
        filas = 4'b0111;

        wait_cycles(STABLE_CYCLES);

        if (boton !== 4'b0001) begin
            $error("[%0t] TEST 4 FALLÓ: se esperaba boton=0001 (tecla 1), se obtuvo %b",
                   $time, boton);
        end else begin
            $display("[%0t] TEST 4 OK: tecla 1 detectada, boton=%b", $time, boton);
        end

        // Soltar
        filas = 4'b1111;
        wait_cycles(STABLE_CYCLES);

        if (boton !== 4'b1111) begin
            $error("[%0t] TEST 4B FALLÓ: al soltar tecla 1 se esperaba boton=1111, se obtuvo %b",
                   $time, boton);
        end else begin
            $display("[%0t] TEST 4B OK: botón volvió a 1111 después de tecla 1", $time, boton);
        end

        $display("[%0t] Fin de la simulación", $time);
        $finish;
    end

endmodule
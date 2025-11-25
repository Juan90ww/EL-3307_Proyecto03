`timescale 1ns/1ps

module tb_debounce;

    // Parámetro para esta simulación
    localparam int N_TB = 16;
    localparam int STABLE_CYCLES = (1 << N_TB) + 2; // algo más que 2^N

    // Señales
    logic clk;
    logic rst;          // reset activo en bajo
    logic key;          // entrada (fila del teclado)
    logic key_pressed;  // salida del debounce

    // Instancia del DUT
    debounce #(
        .N(N_TB)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .key        (key),
        .key_pressed(key_pressed)
    );

    // Generador de reloj: periodo 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Tarea para esperar N flancos de reloj
    task automatic wait_cycles(input int n);
        int i;
        begin
            for (i = 0; i < n; i++) begin
                @(posedge clk);
            end
        end
    endtask

    // Tarea: generar rebotes rápidos alrededor de un valor objetivo
    task automatic bounce_key(
        input logic final_value,
        input int   num_bounces,
        input int   cycles_between_bounces
    );
        int i;
        begin
            for (i = 0; i < num_bounces; i++) begin
                key = ~final_value;
                wait_cycles(cycles_between_bounces);
                key = final_value;
                wait_cycles(cycles_between_bounces);
            end
        end
    endtask

    initial begin
        // Inicialización
        rst = 0;
        key = 1;  // sin tecla presionada (activa en bajo)

        // Volcado de señales
        $dumpfile("tb_debounce.vcd");
        $dumpvars(0, tb_debounce);

        // Mantener reset un rato
        wait_cycles(4);
        rst = 1;
        $display("[%0t] Reset liberado", $time);

        // ============================
        // TEST 1: reposo estable en 1
        // ============================
        wait_cycles(STABLE_CYCLES);

        if (key_pressed !== 1'b1) begin
            $error("[%0t] TEST 1 FALLÓ: key=1 estable, se esperaba key_pressed=1, se obtuvo %b",
                   $time, key_pressed);
        end else begin
            $display("[%0t] TEST 1 OK: reposo estable, key_pressed=%b", $time, key_pressed);
        end

        // ==================================
        // TEST 2: rebotes al presionar (1→0)
        // ==================================
        $display("[%0t] TEST 2: rebotes al presionar", $time);
        bounce_key(1'b0, /*num_bounces*/ 3, /*cycles_between_bounces*/ 1);

        // Tras rebotes, aún no hemos dejado estable mucho tiempo
        if (key_pressed !== 1'b1) begin
            $error("[%0t] TEST 2 FALLÓ: tras rebotes, se esperaba key_pressed=1, se obtuvo %b",
                   $time, key_pressed);
        end else begin
            $display("[%0t] TEST 2 OK: rebotes no cambian salida, key_pressed=%b",
                     $time, key_pressed);
        end

        // ======================================
        // TEST 3: pulsación estable (key = 0)
        // ======================================
        $display("[%0t] TEST 3: pulsación estable", $time);
        key = 0;  // tecla presionada (activa en bajo)

        wait_cycles(STABLE_CYCLES);

        if (key_pressed !== 1'b0) begin
            $error("[%0t] TEST 3 FALLÓ: key=0 estable, se esperaba key_pressed=0, se obtuvo %b",
                   $time, key_pressed);
        end else begin
            $display("[%0t] TEST 3 OK: tecla presionada estable, key_pressed=%b",
                     $time, key_pressed);
        end

        // =====================================
        // TEST 4: rebotes al soltar (0→1)
        // =====================================
        $display("[%0t] TEST 4: rebotes al soltar", $time);

        // Rebotes alrededor de 1 (soltar la tecla con ruido)
        bounce_key(1'b1, /*num_bounces*/ 3, /*cycles_between_bounces*/ 1);

        // Todavía puede estar debouncing, ahora dejamos key=1 estable
        key = 1;
        wait_cycles(STABLE_CYCLES);

        if (key_pressed !== 1'b1) begin
            $error("[%0t] TEST 4 FALLÓ: key=1 estable, se esperaba key_pressed=1, se obtuvo %b",
                   $time, key_pressed);
        end else begin
            $display("[%0t] TEST 4 OK: tecla soltada estable, key_pressed=%b",
                     $time, key_pressed);
        end

        $display("[%0t] Fin de la simulación", $time);
        $finish;
    end

endmodule

`timescale 1ns/1ps

module tb_operacion;

    // Señales del DUT
    logic        clk;
    logic        rst_n;      // reset global activo en bajo
    logic        start;      // pulso para iniciar la división
    logic [7:0]  a_bcd;      // {decenas, unidades}
    logic [7:0]  b_bcd;      // {decenas, unidades}
    logic [3:0]  cociente;   // salida del DUT
    logic [3:0]  resto;      // salida del DUT

    // Instancia del módulo bajo prueba
    operacion dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .a_bcd    (a_bcd),
        .b_bcd    (b_bcd),
        .cociente (cociente),
        .resto    (resto)
    );

    //==================================================
    // Generación de reloj
    //==================================================
    initial clk = 0;
    always #10 clk = ~clk;   // periodo = 20 ns (50 MHz en simulación)

    //==================================================
    // Tarea para correr un caso de prueba
    // a_dec, a_uni, b_dec, b_uni son nibbles BCD
    //==================================================
    task automatic run_case(
        input string   name,
        input logic[3:0] a_dec, a_uni,
        input logic[3:0] b_dec, b_uni
    );
        logic [7:0]  local_a_bcd, local_b_bcd;
        logic [3:0]  A_bin, B_bin;
        logic [3:0]  exp_q, exp_r;
    begin
        // Armar valores BCD
        local_a_bcd = {a_dec, a_uni};
        local_b_bcd = {b_dec, b_uni};

        // Aplicar a entradas
        a_bcd = local_a_bcd;
        b_bcd = local_b_bcd;

        // Calcular A_bin y B_bin EXACTAMENTE igual que en el DUT
        A_bin = ((a_dec == 4'b0001) ? 4'b1010 : 4'b0000) +
                ((a_uni != 4'b1111) ? a_uni    : 4'b0000);

        B_bin = ((b_dec == 4'b0001) ? 4'b1010 : 4'b0000) +
                ((b_uni != 4'b1111) ? b_uni    : 4'b0000);

        if (B_bin == 0) begin
            // si divisor = 0, el comportamiento del DUT no está definido,
            // así que aquí evitamos esos casos
            $display("[%0t] WARNING %s: B_bin=0, se omite este caso", $time, name);
            disable run_case;
        end

        // Resultado esperado
        exp_q = A_bin / B_bin;
        exp_r = A_bin % B_bin;

        // Generar pulso de start (1 ciclo de reloj)
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // El algoritmo necesita 4 ciclos (un bit por ciclo).
        // Sumamos margen y esperamos 6 flancos
        repeat (6) @(posedge clk);

        // Comprobaciones
        if (cociente !== exp_q || resto !== exp_r) begin
            $display("[%0t] TEST %s: FAIL", $time, name);
            $display("       A_bcd=%h (A_bin=%0d), B_bcd=%h (B_bin=%0d)",
                     local_a_bcd, A_bin, local_b_bcd, B_bin);
            $display("       Esperado: Q=%0d, R=%0d", exp_q, exp_r);
            $display("       Obtenido: Q=%0d, R=%0d", cociente, resto);
            $fatal(1);
        end else begin
            $display("[%0t] TEST %s: OK  A_bin=%0d / B_bin=%0d => Q=%0d, R=%0d",
                     $time, name, A_bin, B_bin, cociente, resto);
        end
    end
    endtask

    //==================================================
    // Estímulos
    //==================================================
    initial begin
        // Para ver señales en GTKWave o similar
        $dumpfile("tb_operacion.vcd");
        $dumpvars(0, tb_operacion);

        // Valores iniciales
        rst_n = 1'b0;
        start = 1'b0;
        a_bcd = 8'h00;
        b_bcd = 8'h00;

        // Sacamos del reset
        @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // ------------------------
        // Casos de prueba
        // ------------------------
        // Recuerda: A_bin = (decena==1 ? 10 : 0) + unidades

        // Caso 1:  A = 0x04 => A_bin = 4
        //          B = 0x02 => B_bin = 2
        //          4/2 = 2, r=0
        run_case("A=04, B=02", 4'd0, 4'd4, 4'd0, 4'd2);

        // Caso 2:  A = 0x09 => 9, B = 0x03 => 3 => 9/3 = 3, r=0
        run_case("A=09, B=03", 4'd0, 4'd9, 4'd0, 4'd3);

        // Caso 3:  A = 0x12 => A_bin = 10+2 = 12
        //          B = 0x04 => B_bin = 4 => 12/4 = 3, r=0
        run_case("A=12, B=04", 4'd1, 4'd2, 4'd0, 4'd4);

        // Caso 4:  A = 0x15 => 10+5=15
        //          B = 0x06 => 6 => 15/6 = 2, r=3
        run_case("A=15, B=06", 4'd1, 4'd5, 4'd0, 4'd6);

        $display("[%0t] Todos los tests PASARON", $time);
        $finish;
    end

endmodule

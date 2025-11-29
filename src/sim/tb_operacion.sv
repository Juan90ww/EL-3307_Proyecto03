`timescale 1ns/1ps

module tb_operacion;

    // Usamos un SCAN_DIV pequeño para simular más rápido
    localparam int SCAN_DIV = 4;

    logic       clk;
    logic       rst;
    logic [3:0] dividendo;
    logic [3:0] divisor;
    logic [3:0] cociente;
    logic [3:0] resto;

    // DUT (Device Under Test)
    operacion #(
        .SCAN_DIV(SCAN_DIV)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .dividendo (dividendo),
        .divisor   (divisor),
        .cociente  (cociente),
        .resto     (resto)
    );

    // Generación de reloj: periodo 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Tarea para correr un caso de prueba
    task automatic run_div(
        input [3:0] A,
        input [3:0] B,
        input [3:0] Q_exp,
        input [3:0] R_exp,
        input string nombre_test
    );
    begin
        // Aplicar entradas
        dividendo = A;
        divisor   = B;

        // Reset activo en bajo para cargar A y B en los registros
        rst = 0;
        @(negedge clk); // aseguramos un flanco con rst en 0
        @(posedge clk);
        rst = 1;        // liberamos reset

        // Esperar a que termine la división:
        // 4 bits * SCAN_DIV ciclos + un pequeño margen
        repeat (SCAN_DIV * 4 + 2) @(posedge clk);

        $display("[%0t] %s: A=%0d B=%0d -> Q=%0d R=%0d",
                 $time, nombre_test, A, B, cociente, resto);

        if (cociente !== Q_exp || resto !== R_exp) begin
            $error("TEST FALLÓ (%s): esperado Q=%0d R=%0d, obtenido Q=%0d R=%0d",
                   nombre_test, Q_exp, R_exp, cociente, resto);
        end else begin
            $display("TEST OK (%s)", nombre_test);
        end
    end
    endtask

    // Bloque inicial de pruebas
    initial begin
        // Valores iniciales
        rst       = 0;
        dividendo = 0;
        divisor   = 0;

        repeat (2) @(posedge clk);

        // Casos de prueba
        run_div(4'd9,  4'd3, 4'd3, 4'd0, "9 / 3");
        run_div(4'd7,  4'd2, 4'd3, 4'd1, "7 / 2");
        run_div(4'd15, 4'd4, 4'd3, 4'd3, "15 / 4");
        run_div(4'd8,  4'd5, 4'd1, 4'd3, "8 / 5");

        $display("Todos los tests terminaron");
        $finish;
    end

endmodule

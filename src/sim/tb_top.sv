`timescale 1ns/1ps

module tb_top;

    // Entradas y salidas
    logic [3:0] dividendo;
    logic [3:0] divisor;
    logic [3:0] cociente;
    logic [3:0] resto;

    // Instancia del módulo top
    top DUT (
        .dividendo(dividendo),
        .divisor(divisor),
        .cociente(cociente),
        .resto(resto)
    );

    // Tarea para mostrar resultados bonitos
    task automatic test_div(input [3:0] a, input [3:0] b);
        begin
            dividendo = a;
            divisor   = b;
            #1; // Espera 1 ns (combinacional)
            if (b == 0) begin
                $display("Divisor = 0 -> Division no definida (a=%0d, b=%0d)", a, b);
            end else begin
                $display("a=%0d / b=%0d -> cociente=%0d, resto=%0d", a, b, cociente, resto);
                // Verificación automática
                if ((cociente * b + resto) !== a)
                    $display("ERROR: %0d * %0d + %0d != %0d", cociente, b, resto, a);
                else
                    $display("OK: %0d = %0d * %0d + %0d", a, cociente, b, resto);
            end
            #5;
        end
    endtask

    // Secuencia de pruebas
    initial begin
        $display("====================================");
        $display("  TEST DE DIVISION ENTERA (4 bits)  ");
        $display("====================================");

        // Pruebas básicas
        test_div(8, 2);
        test_div(9, 3);
        test_div(7, 2);
        test_div(15, 4);
        test_div(12, 5);
        test_div(10, 10);
        test_div(0, 3);
        test_div(5, 0); // caso divisor = 0

        $display("====================================");
        $display("  FIN DE LA SIMULACION");
        $display("====================================");
        $finish;
    end

endmodule

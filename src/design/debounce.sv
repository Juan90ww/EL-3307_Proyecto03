module debounce (
    input  logic clk,
    input  logic rst,           // reset activo en bajo
    input  logic key,           // señal de entrada (fila del teclado, activa en bajo)
    output logic key_pressed    // salida debounced (0 = tecla estable en 0, 1 = caso contrario)
);

    // Parámetro para ajustar el tiempo de debounce.
    // El tiempo de estabilización ≈ 2^N ciclos de reloj.
    parameter int N = 12;

    logic [N-1:0] reg_sat, reg_next;
    logic SAMPLE1, SAMPLE2;
    logic reg_reset;
    logic reg_add;

    // Señal estable (debounced) de la tecla
    logic key_stable;

    // Detecta cambio en la señal sincronizada
    assign reg_reset = (SAMPLE1 ^ SAMPLE2);
    // Sigue contando mientras no se haya saturado el MSB
    assign reg_add   = ~reg_sat[N-1];

    // Lógica del contador de estabilidad
    always_comb begin
        case ({reg_reset, reg_add})
            2'b00: reg_next = reg_sat;          // sin cambio y ya saturado → mantener
            2'b01: reg_next = reg_sat + 1'b1;   // sin cambio y no saturado → contar
            default: reg_next = {N{1'b0}};      // hubo cambio → resetear contador
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            SAMPLE1     <= 1'b1;
            SAMPLE2     <= 1'b1;
            reg_sat     <= '0;
            key_stable  <= 1'b1;  // sin tecla presionada al inicio
            key_pressed <= 1'b1;  // salida en 1 por defecto
        end else begin
            // Doble muestreo para sincronizar la señal al reloj
            SAMPLE1 <= key;
            SAMPLE2 <= SAMPLE1;

            // Actualizar contador
            reg_sat <= reg_next;

            // Cuando el contador se satura, aceptamos el nuevo valor estable
            if (reg_sat[N-1]) begin
                key_stable <= SAMPLE2;
            end

            // Salida activa en bajo:
            //  - 0 cuando la tecla se ha estabilizado en 0 (presionada)
            //  - 1 en cualquier otro caso
            key_pressed <= key_stable ? 1'b1 : 1'b0;
        end
    end
endmodule
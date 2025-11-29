module display_7seg  (
    input  logic        clk,
    input  logic        rst,       // activo en bajo
    input  logic [15:0] digito,    // 4 dígitos: [15:12] [11:8] [7:4] [3:0]
    output logic [3:0]  anodo,     // display de ánodo común (0 = encendido)
    output logic [6:0]  seven
);

    logic [15:0] contador;
    logic [1:0]  anodo_selec;
    logic        phase;        // 0 = apagado, 1 = mostrar
    logic [3:0]  data;
    logic [6:0]  seven_next;

    //============================================================
    //  Divisor de frecuencia + control de fase y dígito
    //============================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            contador    <= 0;
            anodo_selec <= 0;
            phase       <= 1'b0;
        end else begin
            if (contador == 16'd3000) begin
                contador <= 0;
                phase    <= ~phase;          // alternar entre OFF y ON

                if (phase == 1'b0) begin
                    // cuando pasamos de OFF -> ON, avanzamos al siguiente dígito
                    anodo_selec <= anodo_selec + 1'b1;
                end
            end else begin
                contador <= contador + 1'b1;
            end
        end
    end

    //============================================================
    //  Selección del nibble (data) según el dígito
    //============================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            data <= 4'd0;
        end else begin
            case (anodo_selec)
                2'b00: data <= digito[3:0];
                2'b01: data <= digito[7:4];
                2'b10: data <= digito[11:8];
                2'b11: data <= digito[15:12];
            endcase
        end
    end

    //============================================================
    //  Conversor HEX -> 7 segmentos (combinacional)
    //============================================================
    display_bin_hex u_display_bin_hex (
        .switch(data),
        .seven (seven_next)   // salida combinacional
    );

    //============================================================
    //  Registro de segmentos (para evitar glitches)
    //============================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            seven <= 7'b111_1111; // todos apagados (para ánodo común)
        end else begin
            seven <= seven_next;
        end
    end

    //============================================================
    //  Control de ánodos con fase de apagado
    //============================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            anodo <= 4'b1111;          // todos apagados
        end else begin
            if (phase == 1'b0) begin
                // Fase de APAGADO: todos los dígitos OFF
                anodo <= 4'b1111;
            end else begin
                // Fase de MOSTRAR: solo un dígito ON
                case (anodo_selec)
                    2'b00: anodo <= 4'b1110; // dígito 0
                    2'b01: anodo <= 4'b1101; // dígito 1
                    2'b10: anodo <= 4'b1011; // dígito 2
                    2'b11: anodo <= 4'b0111; // dígito 3
                endcase
            end
        end
    end

endmodule

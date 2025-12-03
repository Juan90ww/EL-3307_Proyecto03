module test_display (
    input  logic clk,       // 27 MHz
    input  logic rst,
    output logic [3:0] anodo,
    output logic [6:0] seven
);

    //-----------------------------------------------------------
    // 1) Divisor de reloj: generar un pulso EN cada ~1 segundo
    //-----------------------------------------------------------
    localparam integer FREQ  = 27_000_000;  // reloj de entrada
    localparam integer TICKS = FREQ - 1;    // cuenta hasta 26,999,999
    
    logic [31:0] div_cnt = 0;
    logic en_1hz = 0;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            div_cnt <= 0;
            en_1hz  <= 0;
        end else begin
            if (div_cnt == TICKS) begin
                div_cnt <= 0;
                en_1hz <= 1;     // pulso de 1 ciclo
            end else begin
                div_cnt <= div_cnt + 1;
                en_1hz <= 0;
            end
        end
    end

    //-----------------------------------------------------------
    // 2) Contador BCD de 4 dígitos (0000–9999)
    //-----------------------------------------------------------
    logic [3:0] u, d, c, m;
    logic [15:0] digito;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            u <= 0;
            d <= 0;
            c <= 0;
            m <= 0;
        end else if (en_1hz) begin
            if (u < 9) begin
                u <= u + 1;
            end else begin
                u <= 0;
                if (d < 9) begin
                    d <= d + 1;
                end else begin
                    d <= 0;
                    if (c < 9) begin
                        c <= c + 1;
                    end else begin
                        c <= 0;
                        if (m < 9) begin
                            m <= m + 1;
                        end else begin
                            m <= 0; // rollover
                        end
                    end
                end
            end
        end
    end

    // Empaquetado en 16 bits
    always_comb digito = {m, c, d, u};

    //-----------------------------------------------------------
    // 3) Llamada a tu módulo existente
    //-----------------------------------------------------------
    display_7seg display_inst (
        .clk(clk),
        .rst(rst),
        .digito(digito),
        .anodo(anodo),
        .seven(seven)
    );

endmodule

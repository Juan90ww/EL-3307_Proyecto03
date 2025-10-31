module lector_teclado (
    input  logic clk,
    input  logic rst_n,
    output logic [3:0] filas,       // Filas (salida a teclado)
    input  logic [3:0] columnas,    // Columnas (entrada desde teclado)
    output logic [3:0] key_value,   // Valor de tecla (0–F)
    output logic       key_valid    // Pulso 1 clk cuando hay nueva tecla
);

    parameter integer DEBOUNCE_TIME = 1_000_000; // ~37 ms a 27 MHz

    logic [1:0] fila_index;
    logic [3:0] col_read;
    logic [19:0] debounce_cnt;
    logic pressed, pressed_sync;

    logic [3:0] key_code;
    logic key_stable, key_prev;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fila_index <= 0;
        else if (debounce_cnt == 0)
            fila_index <= fila_index + 1;
    end

    assign filas = 4'b1111 ^ (4'b0001 << fila_index);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            col_read <= 4'hF;
        else
            col_read <= columnas;
    end

    always_comb begin
        key_code = 4'hF; // Ninguna tecla
        unique case ({fila_index, col_read})
            8'b00_1110: key_code = 4'h1;
            8'b00_1101: key_code = 4'h2;
            8'b00_1011: key_code = 4'h3;
            8'b00_0111: key_code = 4'hA;

            8'b01_1110: key_code = 4'h4;
            8'b01_1101: key_code = 4'h5;
            8'b01_1011: key_code = 4'h6;
            8'b01_0111: key_code = 4'hB;

            8'b10_1110: key_code = 4'h7;
            8'b10_1101: key_code = 4'h8;
            8'b10_1011: key_code = 4'h9;
            8'b10_0111: key_code = 4'hC;

            8'b11_1110: key_code = 4'hE;
            8'b11_1101: key_code = 4'h0;
            8'b11_1011: key_code = 4'hF;
            8'b11_0111: key_code = 4'hD;
            default:    key_code = 4'd0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt <= 0;
            pressed <= 0;
        end else if (key_code != 4'hF) begin
            if (debounce_cnt < DEBOUNCE_TIME)
                debounce_cnt <= debounce_cnt + 1;
            else
                pressed <= 1;
        end else begin
            debounce_cnt <= 0;
            pressed <= 0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_value <= 4'hF;
            key_valid <= 0;
            key_prev  <= 0;
        end else begin
            key_prev  <= pressed;
            key_valid <= pressed & ~key_prev; // pulso 1 clk
            if (key_valid)
                key_value <= key_code;
        end
    end
endmodule

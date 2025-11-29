module operacion (
    input  logic       clk,
    input  logic       rst_n,    // reset global activo en bajo
    input  logic       start,    // pulso 1 ciclo para iniciar la división
    input  logic [7:0] a_bcd,    // Dividendo en BCD: {decenas, unidades}
    input  logic [7:0] b_bcd,    // Divisor   en BCD: {decenas, unidades}
    output logic [3:0] cociente, // Q[3:0]
    output logic [3:0] resto     // R[3:0]
);

    // --------------------------------------------------
    // 1) Conversión BCD -> binario
    // --------------------------------------------------
    logic [3:0] a_dec, a_uni;
    logic [3:0] b_dec, b_uni;
    logic [3:0] a_bin;   // dividendo
    logic [3:0] b_bin;   // divisor

    always_comb begin
        // si la decena es 1 => 10, si no => 0
        a_dec = (a_bcd[7:4] == 4'b0001) ? 4'b1010    : 4'b0000;
        a_uni = (a_bcd[3:0] != 4'b1111) ? a_bcd[3:0] : 4'b0000;
        b_dec = (b_bcd[7:4] == 4'b0001) ? 4'b1010    : 4'b0000;
        b_uni = (b_bcd[3:0] != 4'b1111) ? b_bcd[3:0] : 4'b0000;

        a_bin = a_uni + a_dec;
        b_bin = b_uni + b_dec;
    end

    // --------------------------------------------------
    // 2) Registros del algoritmo (resto, cociente, índice, running)
    // --------------------------------------------------
    logic [3:0] resto_reg;
    logic [3:0] coc_reg;
    logic [1:0] idx;
    logic       running;

    logic [3:0] R_shift;
    logic signed [4:0] D;

    always_comb begin
        R_shift = {resto_reg[2:0], a_bin[idx]};                  // R = {R'<<1, A_i}
        D       = $signed({1'b0, R_shift}) - $signed({1'b0, b_bin}); // D = R - B
    end

    // --------------------------------------------------
    // 3) Secuencial con start (sin latches)
    // --------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resto_reg <= 4'b0000;
            coc_reg   <= 4'b0000;
            idx       <= 2'd0;
            running   <= 1'b0;
        end else begin
            if (start) begin
                // iniciar nueva división
                resto_reg <= 4'b0000;
                coc_reg   <= 4'b0000;
                idx       <= 2'd3;
                running   <= 1'b1;
            end else if (running) begin
                if (D < 0) begin
                    coc_reg[idx] <= 1'b0;
                    resto_reg    <= R_shift;
                end else begin
                    coc_reg[idx] <= 1'b1;
                    resto_reg    <= D[3:0];
                end

                if (idx == 2'd0)
                    running <= 1'b0;     // terminamos
                else
                    idx <= idx - 2'd1;
            end
        end
    end

    assign cociente = coc_reg;
    assign resto    = resto_reg;

endmodule

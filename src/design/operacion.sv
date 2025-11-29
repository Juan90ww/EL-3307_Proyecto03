module operacion #(
    parameter int SCAN_DIV = 500
)(
    input   logic       clk,
    input   logic       rst,
    input   logic [3:0] dividendo,
    input   logic [3:0] divisor,
    output  logic [3:0] cociente,
    output  logic [3:0] resto
);

    logic [$clog2(SCAN_DIV)-1:0] scan_div = 0;
    logic [1:0] contador = 0;
    logic [3:0] a_reg; // Dividendo
    logic [3:0] b_reg; // Divisor
    logic [3:0] r_reg; // Resto
    logic [3:0] q_reg; // cociente

    // Creo variables para operar
    logic        [3:0] r_next;
    logic signed [4:0] d_next; // Resta (r - b)

    always_comb begin
        a_reg  = dividendo;
        b_reg  = divisor;
        // Logica de division
        r_next = {r_reg[2:0], a_reg[3 - contador]};               // R = { R' << 1, A_i }
        d_next = $signed({1'b0, r_next}) - $signed({1'b0, b_reg}); // D = R - B        
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            scan_div  <= 0;
            contador  <= 0;
            r_reg     <= 4'b0000;
            q_reg     <= 4'b0000;
        end else begin

            if (scan_div == SCAN_DIV-1) begin

            if (d_next < 0) begin
                q_reg[3 - contador] <= 1'b0;
                r_reg               <= r_next;
            end else begin
                q_reg[3 - contador] <= 1'b1;
                r_reg               <= d_next[3:0];
            end

            // divisor para cambio de indice
            scan_div <= 0;
            contador <= (contador == 3) ? 0: contador + 1;
            end else begin
                scan_div <= scan_div + 1;
            end
        end
    end
    
    // Salidal del modulo
    assign cociente = q_reg;
    assign resto    = r_reg;
endmodule
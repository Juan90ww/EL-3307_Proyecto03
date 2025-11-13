module display_7seg  (
    input   clk,
    input   rst,
    input  logic[15:0] digito,
    output logic [3:0] anodo,
    output logic [6:0] seven
);
    logic [1:0] anodo_selec = 0;
    logic [3:0] data;
    logic [15:0] contador = 0;
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            contador <= 0;
            anodo_selec <= 0;
        end else begin
            contador <= contador + 1;
            if (contador == 1350) begin
                contador <= 0;
                anodo_selec <= anodo_selec + 1;
            end
        end 
    end

    always_comb begin
        case (anodo_selec)
            2'b00: begin anodo <= 4'b1110; data <= digito [3:0]; end
            2'b01: begin anodo <= 4'b1101; data <= digito [7:4]; end
            2'b10: begin anodo <= 4'b1011; data <= digito [11:8]; end
            2'b11: begin anodo <= 4'b0111; data <= digito [15:12]; end
        endcase
    end
    display_bin_hex display(.switch(data), .seven(seven));
endmodule

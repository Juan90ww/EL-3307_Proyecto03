module display_bin_hex (
    input  logic [3:0] switch,
    output logic [6:0] seven // a b c d e f g (ACTIVO-BAJO)
);
    // decodificador bin -> HEX -> 7 segmentos (ACTIVO-BAJO)
    always_comb begin
        // por defecto: todo apagado
        seven = 7'b1111111;
        case (switch)
            4'b0000: seven = 7'b0000001; // 0
            4'b0001: seven = 7'b1001111; // 1
            4'b0010: seven = 7'b0010010; // 2
            4'b0011: seven = 7'b0000110; // 3
            4'b0100: seven = 7'b1001100; // 4
            4'b0101: seven = 7'b0100100; // 5 
            4'b0110: seven = 7'b0100000; // 6 
            4'b0111: seven = 7'b0001111; // 7
            4'b1000: seven = 7'b0000000; // 8
            4'b1001: seven = 7'b0000100; // 9
            4'b1010: seven = 7'b0001000; // A
            4'b1011: seven = 7'b1100000; // b
            4'b1100: seven = 7'b0110001; // c
            4'b1101: seven = 7'b1000010; // d
          //4'b1110: seven = 7'b0110000; // E
          //4'b1111: seven = 7'b0111000; // F
            4'b1111: seven = 7'b1111111;
            default: seven = 7'b1111111; // apagado
        endcase
    end
endmodule

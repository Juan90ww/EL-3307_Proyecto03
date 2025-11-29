module bcd_binario (
    input  logic [7:0] bcd, // BCD: {Decenas, Unidades}
    output logic [3:0] bin  // Bin: numero binario de 4 bits
);
    logic [4:0] decenas; 
    always_comb begin

        unique case (bcd [7:4])
                4'b0001 : decenas = 4'b1010;
                default : decenas = 4'b0000;
            endcase
        bin = bcd [3:0] + decenas;
    end
endmodule
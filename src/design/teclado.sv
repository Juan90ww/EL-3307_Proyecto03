module teclado #(
    parameter int SCAN_DIV = 13_500  // ~0.5 ms por columna @27MHz
)(
    // Entradas
    input  logic clk,
    input  logic [3:0] filas,
    // Salidas
    output logic [3:0] columnas,
    output logic [3:0] boton
);
    // Variables
    logic [1:0] contador = 0;
    logic [$clog2(SCAN_DIV)-1:0] scan_col = 0;
    //initial boton = 4'b1111;
    
    always_ff @(posedge clk) begin
        // divisor para cambio de columna
        if (scan_col == SCAN_DIV-1) begin
            scan_col <= 0;
            contador <= (contador == 3) ? 0: contador + 1;
        end else begin
            scan_col <= scan_col + 1;
        end        
        
        // Asigno valores de columnas One - Hot
        case(contador)
            0: columnas <= 4'b0111;
            1: columnas <= 4'b1011;
            2: columnas <= 4'b1101;
            3: columnas <= 4'b1110;
        endcase
        case(columnas)
            4'b0111:begin
                if(filas == 4'b0111) boton <= 4'b0001; //1
                if(filas == 4'b1011) boton <= 4'b0100; //4
                if(filas == 4'b1101) boton <= 4'b0111; //7
                if(filas == 4'b1110) boton <= 4'b0000; //*
            end

            4'b1011:begin
                if(filas == 4'b0111) boton <= 4'b0010; //2
                if(filas == 4'b1011) boton <= 4'b0101; //5
                if(filas == 4'b1101) boton <= 4'b1000; //8
                if(filas == 4'b1110) boton <= 4'b0000; //0
            end

            4'b1101:begin
                if(filas == 4'b0111) boton <= 4'b0011; //3
                if(filas == 4'b1011) boton <= 4'b0110; //6
                if(filas == 4'b1101) boton <= 4'b1001; //9
                if(filas == 4'b1110) boton <= 4'b1110; //#
            end

            4'b1110:begin
                if(filas == 4'b0111) boton <= 4'b1010; //A
                if(filas == 4'b1011) boton <= 4'b1011; //B
                if(filas == 4'b1101) boton <= 4'b1100; //C
                if(filas == 4'b1110) boton <= 4'b1101; //D
            end
            default: boton <= 4'b1111;
        endcase
    end
endmodule
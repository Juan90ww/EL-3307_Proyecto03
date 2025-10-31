module teclado
(
    // Entradas
    input   logic clk,
    input   logic rst,
    input   logic [3:0] filas,
    // Salidas
    output logic [3:0] columnas,
    output logic [3:0] boton,
    output logic        ctrl
);
    // pseudo maquinaa de estados
    localparam SCAN_COL = 2'b00;
    localparam ESPERAR  = 2'b01;
    localparam SCAN_FIL = 2'b10;
    parameter  DELAY    = 1350; // 27MHz / 2kHz
    // Variables
    logic [1:0]     estado = SCAN_COL;
    logic [1:0]     cont_col = 2'b00;
    logic [3:0]     filas_fil;
    logic [15:0]    cont_delay;

    // Instancias del modulo debounce

    debounce f0 (.clk(clk), .rst(rst), .key(filas[0]), .key_pressed(filas_fil[0]));
    debounce f1 (.clk(clk), .rst(rst), .key(filas[1]), .key_pressed(filas_fil[1]));
    debounce f2 (.clk(clk), .rst(rst), .key(filas[2]), .key_pressed(filas_fil[2]));
    debounce f3 (.clk(clk), .rst(rst), .key(filas[3]), .key_pressed(filas_fil[3]));
    

    always @(posedge clk) begin
        ctrl <= 1'b0;
        case (estado)
            SCAN_COL : begin
                unique case(cont_col)
                0: columnas <= 4'b0111;
                1: columnas <= 4'b1011;
                2: columnas <= 4'b1101;
                3: columnas <= 4'b1110;
                endcase
                cont_col <= cont_col + 1;
                cont_delay <= 0;
                estado  <= ESPERAR;
            end

            ESPERAR : begin 
                if (cont_delay == DELAY) begin
                    estado <= SCAN_FIL;
                    cont_delay <= 0;
                end else begin
                    cont_delay <= cont_delay + 1;
                end
            end

            SCAN_FIL : begin 
                if (filas_fil != 4'b1111) begin 
                    unique case({columnas,filas_fil})
                        // Columna C0
                        8'b0111_0111: boton <= 4'b0001; //1
                        8'b0111_1011: boton <= 4'b0100; //4
                        8'b0111_1101: boton <= 4'b0111; //7
                        8'b0111_1110: boton <= 4'b1101; //*

                        // Columna C1
                        8'b1011_0111: boton <= 4'b0010; //2
                        8'b1011_1011: boton <= 4'b0101; //5
                        8'b1011_1101: boton <= 4'b1000; //8
                        8'b1011_1110: boton <= 4'b0000; //0

                        // Columna C2
                        8'b1101_0111: boton <= 4'b0011; //3
                        8'b1101_1011: boton <= 4'b0110; //6
                        8'b1101_1101: boton <= 4'b1001; //9
                        8'b1101_1110: boton <= 4'b1110; //#

                        // Columna C3
                        8'b1110_0111: boton <= 4'b0110; //A
                        8'b1110_1011: boton <= 4'b1011; //B
                        8'b1110_1101: boton <= 4'b1100; //C
                        8'b1110_1110: boton <= 4'b1101; //D
                        default:      boton <= 4'b1111;
                    endcase
                    ctrl <= 1'b1;
                end
                estado <= SCAN_COL;
            end
        endcase
    end
endmodule
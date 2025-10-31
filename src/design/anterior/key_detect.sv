module key_detect 
#(
    parameter int SCAN_HZ = 2000, // Frecuecia de digito fila
)
(
    input  logic clk, // reloj

    // Entradas del teclado
    input   logic [3:0] col,
    output  logic [3:0] fil,

    output logic [3:0] dato,
    output logic dato_ctrl = 0
);
    // Estados del teclado One Hot
    localparam LEER = 2'b00;
    localparam ESPERAR = 2'b01;
    localparam DETECTAR = 2'b10;

    // Parametros de control:
    logic [1:0] estado = LEER;
    logic [15:0] count = 0;
    logic [3:0] col_anterior;
    logic [3:0] col_estable;
    logic [3:0] col_activa;
    logic [1:0] barrido_fil = 0
    ;
    // Llamamos al debounce para saber cual tecla fue presionada (filtrada)
    debounce col0
    (
        .clk(clk),
        .rst_n(1'b1),
        .tecla(~col[0]),
        .tecla_activa(col_estable[0])
    );

    debounce col1
    (
        .clk(clk),
        .rst_n(1'b1),
        .tecla(~col[1]),
        .tecla_activa(col_estable[1])
    );

    debounce col2
    (
        .clk(clk),
        .rst_n(1'b1),
        .tecla(~col[2]),
        .tecla_activa(col_estable[2])
    );

    debounce col3
    (
        .clk(clk),
        .rst_n(1'b1),
        .tecla(~col[3]),
        .tecla_activa(col_estable[3])
    );

    // Haciendo un barrido de filas en espera de una casilla de columna
    always @(posedge clk) begin
        dato_ctrl <= 0;
        case (estado)
            LEER: begin
                barrido_fil <= barrido_fil + 1;
                case (barrido_fil)
                    2'b00: fil <= 4'b0111;
                    2'b01: fil <= 4'b1011;
                    2'b10: fil <= 4'b1101;
                    2'b11: fil <= 4'b1110;
                endcase
                count <= 0;
                estado <= ESPERAR;
            end

            ESPERAR: begin
                if (count == SCAN_HZ) begin
                    estado <= DETECTAR;
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
            end

            DETECTAR: begin
                if (col_estable != 4'b1111) begin
                    case ({barrido_fil, col_estable})
                        6'b00_1110: dato <= 4'b0001;
                        6'b00_1101: dato <= 4'b0100;
                        6'b00_1011: dato <= 4'b0111;

                        6'b11_1110: dato <= 4'b0010;
                        6'b11_1101: dato <= 4'b0101;
                        6'b11_1011: dato <= 4'b1000;
                        6'b11_0111: dato <= 4'b0000;

                        6'b10_1110: dato <= 4'b0011;
                        6'b10_1101: dato <= 4'b0110;
                        6'b10_1011: dato <= 4'b1001;
                        6'b10_0111: dato <= 4'b1111;

                        6'b01_1110: dato <= 4'b1010;
                        6'b01_1101: dato <= 4'b1011;
                        6'b01_1011: dato <= 4'b1100;
                        6'b01_0111: dato <= 4'b1101;
                    endcase
                    
                    dato_ctrl <= 1;
                end
                estado <= LEER;
            end
        endcase
    end
endmodule

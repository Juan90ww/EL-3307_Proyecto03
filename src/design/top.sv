module top #(
    // Espera por defecto de ~650 ms @27 MHz
    parameter int WAIT_CYCLES = 17_550_000
)(
    input   logic       clk,         // Reloj de 27 MHz
    input   logic       rst,         // Reset activo en bajo
    output  logic [3:0] anodo,       // Ánodos del display
    output  logic [6:0] seven,       // Segmentos del display
    output  logic [3:0] col,         // Columnas del teclado
    input   logic [3:0] fil          // Filas del teclado (crudas)
);
    //========================================================
    // 1) Debounce de filas
    //========================================================
    logic [3:0] filas_debounce;
    logic [3:0] boton_press;

    debounce f0 (.clk(clk), .rst(rst), .key(fil[0]), .key_pressed(filas_debounce[0]));
    debounce f1 (.clk(clk), .rst(rst), .key(fil[1]), .key_pressed(filas_debounce[1]));
    debounce f2 (.clk(clk), .rst(rst), .key(fil[2]), .key_pressed(filas_debounce[2]));
    debounce f3 (.clk(clk), .rst(rst), .key(fil[3]), .key_pressed(filas_debounce[3]));

    //========================================================
    // 2) Teclado (scanner): solo usamos 'boton'
    //========================================================
    teclado teclado_inst(
        .clk      (clk),
        .filas    (filas_debounce),
        .columnas (col),
        .boton    (boton_press)
    );

    //========================================================
    // 3) Detector de flanco DE PRESIÓN:
    //    key_down = 1 cuando pasamos de 1111 -> código
    //    (con dos muestras previas en 1111 para estar más seguros)
    //========================================================
    logic [3:0] key_prev1;
    logic [3:0] key_prev2;
    logic       key_down;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            key_prev1 <= 4'b1111;
            key_prev2 <= 4'b1111;
            key_down  <= 1'b0;
        end else begin
            key_down  <= (key_prev2 == 4'b1111) &&
                         (key_prev1 == 4'b1111) &&
                         (boton_press != 4'b1111);
            key_prev2 <= key_prev1;
            key_prev1 <= boton_press;
        end
    end

    //========================================================
    // 4) Máquina de estados + registros A/B + estado WAIT
    //========================================================
    typedef enum logic [1:0] {
        STATE_INPUT_A,   // 2'b00
        STATE_INPUT_B,   // 2'b01
        STATE_WAIT       // 2'b10
    } operation_state_t;

    operation_state_t current_state, next_state;
    operation_state_t prev_state;   // guarda si veníamos de A o de B

    logic [3:0] A0, A1; // unidades y decenas de A
    logic [3:0] B0, B1; // unidades y decenas de B

    // Contador para el estado WAIT
    localparam int WAIT_CNT_WIDTH = $clog2(WAIT_CYCLES);
    logic [WAIT_CNT_WIDTH-1:0] wait_cnt;
    logic                      wait_done;

    assign wait_done = (wait_cnt == WAIT_CYCLES-1);

    // Secuencial: estado + registros + contador WAIT
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= STATE_INPUT_A;
            prev_state    <= STATE_INPUT_A;

            A0 <= 4'b1111; A1 <= 4'b1111;
            B0 <= 4'b1111; B1 <= 4'b1111;

            wait_cnt <= '0;
        end else begin
            current_state <= next_state;

            // Manejo del contador de espera
            case (current_state)
                STATE_WAIT: begin
                    if (!wait_done)
                        wait_cnt <= wait_cnt + 1;
                    else
                        wait_cnt <= '0;    // listo para la próxima vez
                end
                default: begin
                    wait_cnt <= '0;        // fuera de WAIT, contador en 0
                end
            endcase

            // Manejo de A/B y prev_state solo cuando hay key_down
            if (key_down) begin
                unique case (current_state)
                    // Solo aceptamos teclas si estamos en INPUT_A o INPUT_B
                    STATE_INPUT_A,
                    STATE_INPUT_B: begin
                        unique case (boton_press)
                            // '*' = 1101: reset registros y volvemos luego a A
                            4'b1101: begin
                                A0 <= 4'b1111; A1 <= 4'b1111;
                                B0 <= 4'b1111; B1 <= 4'b1111;
                                prev_state <= STATE_INPUT_A;  // después de WAIT volvemos a A
                            end

                            // '#' = 1110: NO guarda, solo cambia de A <-> B
                            4'b1110: begin
                                if (current_state == STATE_INPUT_A)
                                    prev_state <= STATE_INPUT_B; // luego de WAIT estaremos en B
                                else
                                    prev_state <= STATE_INPUT_A; // luego de WAIT estaremos en A
                            end

                            // Cualquier otro valor: guardar en A o B
                            default: begin
                                if (current_state == STATE_INPUT_A) begin
                                    A1 <= A0;
                                    A0 <= boton_press;
                                    prev_state <= STATE_INPUT_A;  // después de WAIT seguimos en A
                                end else begin
                                    B1 <= B0;
                                    B0 <= boton_press;
                                    prev_state <= STATE_INPUT_B;  // después de WAIT seguimos en B
                                end
                            end
                        endcase
                    end

                    // Si por alguna razón llega key_down en WAIT, lo ignoramos
                    default: begin
                        // no escribir nada
                    end
                endcase
            end
        end
    end

    // Combinacional: siguiente estado
    always_comb begin
        next_state = current_state;

        case (current_state)
            //------------------------------------------------
            // Estados de entrada A y B
            //------------------------------------------------
            STATE_INPUT_A,
            STATE_INPUT_B: begin
                if (key_down) begin
                    // Cada tecla válida siempre nos lleva a WAIT
                    next_state = STATE_WAIT;
                end
            end

            //------------------------------------------------
            // Estado de espera
            //------------------------------------------------
            STATE_WAIT: begin
                if (wait_done) begin
                    // Cuando pasa el tiempo, regresamos al estado previo
                    next_state = prev_state;
                end
            end

            default: begin
                next_state = STATE_INPUT_A;
            end
        endcase
    end

    //========================================================
    // 5) Display
    //  En WAIT seguimos mostrando el número (A o B) según prev_state
    //========================================================
    logic [15:0] display_data;
    operation_state_t display_state;

    always_comb begin
        // Qué queremos mostrar: si estamos en WAIT, usamos prev_state
        if (current_state == STATE_WAIT)
            display_state = prev_state;
        else
            display_state = current_state;

        display_data = 16'hFFFF;

        unique case (display_state)
            // [izq -> der]: A, _, A1, A0
            STATE_INPUT_A: display_data = {4'b1010, 4'b1111, A1, A0};
            // [izq -> der]: b, _, B1, B0
            STATE_INPUT_B: display_data = {4'b1011, 4'b1111, B1, B0};
            default:       display_data = 16'hFFFF;
        endcase
    end

    display_7seg display (
        .clk   (clk),
        .rst   (rst),
        .digito(display_data),
        .anodo (anodo),
        .seven (seven)
    );

endmodule

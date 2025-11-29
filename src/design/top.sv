module top #(
    // Espera por defecto de ~650 ms @27 MHz
    parameter int WAIT_CYCLES     = 17_550_000,
    // Espera antes de lanzar start de la operación (ej. ~20ms @27MHz → 540000)
    parameter int OP_WAIT_CYCLES  = 540_000
)(
    input  logic       clk,   // Reloj de 27 MHz
    input  logic       rst,   // Reset activo en bajo
    output logic [3:0] anodo, // Ánodos del display
    output logic [6:0] seven, // Segmentos del display
    output logic [3:0] col,   // Columnas del teclado
    input  logic [3:0] fil    // Filas del teclado (crudas)
);

    //========================================================
    // 1) Debounce de filas
    //========================================================
    logic [3:0] filas_debounce;
    logic [3:0] boton_press;

    debounce f0 (
        .clk         (clk),
        .rst         (rst),
        .key         (fil[0]),
        .key_pressed (filas_debounce[0])
    );

    debounce f1 (
        .clk         (clk),
        .rst         (rst),
        .key         (fil[1]),
        .key_pressed (filas_debounce[1])
    );

    debounce f2 (
        .clk         (clk),
        .rst         (rst),
        .key         (fil[2]),
        .key_pressed (filas_debounce[2])
    );

    debounce f3 (
        .clk         (clk),
        .rst         (rst),
        .key         (fil[3]),
        .key_pressed (filas_debounce[3])
    );

    //========================================================
    // 2) Teclado (scanner)
    //========================================================
    teclado teclado_inst (
        .clk      (clk),
        .filas    (filas_debounce),
        .columnas (col),
        .boton    (boton_press)
    );

    //========================================================
    // 3) Detector de flanco DE PRESIÓN
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
    // 4) Máquina de estados + registros A/B + WAIT + OPERACION
    //========================================================
    typedef enum logic [1:0] {
        STATE_INPUT_A,   // 2'b00
        STATE_INPUT_B,   // 2'b01
        STATE_WAIT,      // 2'b10
        STATE_OPERACION  // 2'b11
    } operation_state_t;

    operation_state_t current_state, next_state;
    operation_state_t prev_state;   // guarda si veníamos de A, B u OPERACION

    logic [3:0] A0, A1; // unidades y decenas de A
    logic [3:0] B0, B1; // unidades y decenas de B

    // Contador para el estado WAIT
    localparam int WAIT_CNT_WIDTH = $clog2(WAIT_CYCLES);
    logic [WAIT_CNT_WIDTH-1:0] wait_cnt;
    logic                      wait_done;

    assign wait_done = (wait_cnt == WAIT_CYCLES-1);

    //========================================================
    // 5) Operación: A y B en BCD -> Q y R
    //========================================================
    logic [7:0] a_bcd, b_bcd;
    logic [3:0] q_bcd, r_bcd;

    assign a_bcd = {A1, A0}; // {decenas, unidades}
    assign b_bcd = {B1, B0};

    //--------------------------------------------------------
    // 5.a Generación de start diferido para operacion
    //     - detectamos entrada a STATE_OPERACION
    //     - contamos OP_WAIT_CYCLES
    //     - generamos un pulso de 1 ciclo en op_start
    //--------------------------------------------------------
    logic op_state_prev;
    logic op_start;
    localparam int OP_WAIT_WIDTH = $clog2(OP_WAIT_CYCLES);
    logic [OP_WAIT_WIDTH-1:0] op_wait_cnt;
    logic                     op_wait_active;

    // detectar entrada a STATE_OPERACION
    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            op_state_prev <= 1'b0;
        else
            op_state_prev <= (current_state == STATE_OPERACION);
    end

    // contador de espera para start
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            op_wait_active <= 1'b0;
            op_wait_cnt    <= '0;
        end else begin
            // si acabamos de entrar a STATE_OPERACION
            if ((current_state == STATE_OPERACION) && !op_state_prev) begin
                op_wait_active <= 1'b1;
                op_wait_cnt    <= '0;
            end else if (op_wait_active) begin
                if (op_wait_cnt == OP_WAIT_CYCLES-1) begin
                    op_wait_active <= 1'b0;   // termina la ventana de espera
                end else begin
                    op_wait_cnt <= op_wait_cnt + 1;
                end
            end
        end
    end

    // pulso de 1 ciclo cuando termina la cuenta
    assign op_start = op_wait_active && (op_wait_cnt == OP_WAIT_CYCLES-1);

    operacion divisor_inst (
        .clk      (clk),
        .rst_n    (rst),
        .start    (op_start),
        .a_bcd    (a_bcd),
        .b_bcd    (b_bcd),
        .cociente (q_bcd),
        .resto    (r_bcd)
    );

    //========================================================
    // 6) Secuencial: estado + registros + contador WAIT
    //========================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= STATE_INPUT_A;
            prev_state    <= STATE_INPUT_A;

            A0 <= 4'b1111; A1 <= 4'b1111;
            B0 <= 4'b1111; B1 <= 4'b1111;

            wait_cnt <= '0;
        end else begin
            current_state <= next_state;

            // Manejo del contador de espera de teclas
            case (current_state)
                STATE_WAIT: begin
                    if (!wait_done)
                        wait_cnt <= wait_cnt + 1;
                    else
                        wait_cnt <= '0;
                end
                default: begin
                    wait_cnt <= '0;
                end
            endcase

            // Manejo de A/B y prev_state solo cuando hay key_down
            if (key_down) begin
                unique case (current_state)
                    STATE_INPUT_A,
                    STATE_INPUT_B: begin
                        unique case (boton_press)
                            // '*' = 1101: reset registros y volvemos luego a A
                            4'b1101: begin
                                A0 <= 4'b1111; A1 <= 4'b1111;
                                B0 <= 4'b1111; B1 <= 4'b1111;
                                prev_state <= STATE_INPUT_A;
                            end

                            // '#' = 1110:
                            //  - desde A: ir a INPUT_B
                            //  - desde B: ir a OPERACION
                            4'b1110: begin
                                if (current_state == STATE_INPUT_A)
                                    prev_state <= STATE_INPUT_B;     // A -> WAIT -> B
                                else
                                    prev_state <= STATE_OPERACION;   // B -> WAIT -> OPERACION
                            end

                            // Cualquier otro valor: guardar en A o B
                            default: begin
                                if (current_state == STATE_INPUT_A) begin
                                    A1 <= A0;
                                    A0 <= boton_press;
                                    prev_state <= STATE_INPUT_A;
                                end else begin
                                    B1 <= B0;
                                    B0 <= boton_press;
                                    prev_state <= STATE_INPUT_B;
                                end
                            end
                        endcase
                    end

                    // En OPERACION, por ejemplo: '*' para reiniciar y volver a A
                    STATE_OPERACION: begin
                        if (boton_press == 4'b1101) begin // '*'
                            A0 <= 4'b1111; A1 <= 4'b1111;
                            B0 <= 4'b1111; B1 <= 4'b1111;
                            prev_state <= STATE_INPUT_A;
                        end
                    end

                    default: begin
                        // En WAIT no usamos key_down
                    end
                endcase
            end
        end
    end

    //========================================================
    // 7) Combinacional: siguiente estado
    //========================================================
    always_comb begin
        next_state = current_state;

        case (current_state)
            STATE_INPUT_A,
            STATE_INPUT_B: begin
                if (key_down)
                    next_state = STATE_WAIT;
            end

            STATE_WAIT: begin
                if (wait_done)
                    next_state = prev_state;
            end

            STATE_OPERACION: begin
                if (key_down && (boton_press == 4'b1101))
                    next_state = STATE_WAIT;
            end

            default: begin
                next_state = STATE_INPUT_A;
            end
        endcase
    end

    //========================================================
    // 8) Display
    //========================================================
    logic [15:0]      display_data;
    operation_state_t display_state;

    always_comb begin
        if (current_state == STATE_WAIT)
            display_state = prev_state;
        else
            display_state = current_state;

        display_data = 16'hFFFF;

        unique case (display_state)
            // [izq -> der]: A, _, A1, A0
            STATE_INPUT_A:
                display_data = {4'b1010, 4'b1111, A1, A0};

            // [izq -> der]: b, _, B1, B0
            STATE_INPUT_B:
                display_data = {4'b1011, 4'b1111, B1, B0};

            // [izq -> der]: _, Q, _, R
            STATE_OPERACION:
                display_data = {A0, q_bcd, B0, r_bcd};

            default:
                display_data = 16'hFFFF;
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

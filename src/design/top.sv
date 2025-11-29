module top #(
    // Espera por defecto de ~650 ms @27 MHz
    parameter int WAIT_CYCLES = 17_550_000,
    //Ciclos que esperamos en OPERACION antes de “congelar” Q y R
    parameter int OP_CYCLES   = 13_500_000
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

    debounce f0 (.clk(clk), .rst(rst), .key(fil[0]), .key_pressed(filas_debounce[0]));
    debounce f1 (.clk(clk), .rst(rst), .key(fil[1]), .key_pressed(filas_debounce[1]));
    debounce f2 (.clk(clk), .rst(rst), .key(fil[2]), .key_pressed(filas_debounce[2]));
    debounce f3 (.clk(clk), .rst(rst), .key(fil[3]), .key_pressed(filas_debounce[3]));
    
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
    logic [3:0] a_bin, b_bin;
    logic [3:0] q_bcd, r_bcd;          // salidas “vivas” del divisor

    bcd_binario dividendo (.bcd ({A1, A0}), .bin (a_bin));
    bcd_binario divisor   (.bcd ({B1, B0}), .bin (b_bin));
    
    operacion #(.SCAN_DIV(4)) divisor_inst (
        .clk       (clk),
        .rst       (rst),
        .dividendo (a_bin),
        .divisor   (b_bin),
        .cociente  (q_bcd),
        .resto     (r_bcd)
    );

    // Registros donde “congelamos” Q y R una sola vez
    logic [3:0] Q_LATCH, R_LATCH;
    logic       op_latched;   // indica que ya guardamos Q/R al menos una vez

    // Contador para esperar en OPERACION
    localparam int OP_CNT_WIDTH = $clog2(OP_CYCLES);
    logic [OP_CNT_WIDTH-1:0] op_cnt;
    logic                    op_done;

    assign op_done = (op_cnt == OP_CYCLES-1);

    //========================================================
    // 6) Secuencial: estado + registros + contador WAIT + latch Q/R
    //========================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= STATE_INPUT_A;
            prev_state    <= STATE_INPUT_A;

            A0 <= 4'b1111; A1 <= 4'b1111;
            B0 <= 4'b1111; B1 <= 4'b1111;

            wait_cnt   <= '0;

            // Se limpia latch Q/R
            op_cnt     <= '0;
            op_latched <= 1'b0;
            Q_LATCH    <= 4'b1111;
            R_LATCH    <= 4'b1111;
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

            // Manejo del contador de OPERACION y latch de Q/R
            if (current_state == STATE_OPERACION) begin
                if (!op_done) begin
                    op_cnt <= op_cnt + 1;
                end else begin
                    op_cnt <= op_cnt;
                    if (!op_latched) begin
                        Q_LATCH    <= q_bcd;
                        R_LATCH    <= r_bcd;
                        op_latched <= 1'b1;
                    end
                end
            end else begin
                op_cnt     <= '0;
                op_latched <= 1'b0;
            end

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

                                // *** NUEVO *** reset también resultado latcheado
                                op_latched <= 1'b0;
                                Q_LATCH    <= 4'b1111;
                                R_LATCH    <= 4'b1111;
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

                            // *** NUEVO ***
                            op_latched <= 1'b0;
                            Q_LATCH    <= 4'b1111;
                            R_LATCH    <= 4'b1111;
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

            // [izq -> der]: B, _, B1, B0
            STATE_INPUT_B:
                display_data = {4'b1011, 4'b1111, B1, B0};

            // [izq -> der]: _, Q, _, R  (usamos los latcheados)
            STATE_OPERACION:
                display_data = {a_bin, Q_LATCH, b_bin, R_LATCH};

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

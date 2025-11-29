module funcional(
    input   logic       clk,     // 27 MHz
    input   logic       rst,     // activo en 0
    input   logic [3:0] fil,     // filas del teclado
    output  logic [3:0] col,     // columnas del teclado
    output  logic [3:0] anodo,
    output  logic [6:0] seven
);

    //========================================================
    // 1) Estados FSM
    //========================================================
    typedef enum logic [1:0] {
        SCAN    = 2'b00,  // esperando tecla
        LOAD    = 2'b01,  // registrar tecla una vez
        RELEASE = 2'b10   // esperando soltar
    } state_t;

    state_t estado, next;

    //========================================================
    // 2) Señales teclado
    //========================================================
    logic [3:0] filas_debounce;
    logic [3:0] boton_press;   // código tecla (0-F o 1111 reposo)
    logic       tecla_activa;  // alguna tecla presionada?
    logic       key;

    assign tecla_activa = (filas_debounce != 4'b1111);

    //========================================================
    // 3) Debounce de filas (usa fil, no filas)
    //========================================================
    debounce f0 (.clk(clk), .rst(rst), .key(fil[0]), .key_pressed(filas_debounce[0]));
    debounce f1 (.clk(clk), .rst(rst), .key(fil[1]), .key_pressed(filas_debounce[1]));
    debounce f2 (.clk(clk), .rst(rst), .key(fil[2]), .key_pressed(filas_debounce[2]));
    debounce f3 (.clk(clk), .rst(rst), .key(fil[3]), .key_pressed(filas_debounce[3]));

    //========================================================
    // 4) Escáner del teclado
    //========================================================
    teclado teclado_inst(
        .clk      (clk),
        .filas    (filas_debounce),
        .columnas (col),
        .boton    (boton_press),
        .ctrl     (key)
    );

    //========================================================
    // 5) Registro para display
    //========================================================
    logic [15:0] display_data;

    //========================================================
    // 6) Lógica NEXT de FSM
    //========================================================
    always_comb begin
        next = estado;
        case (estado)
            SCAN: begin
                // detecta tecla válida
                if (tecla_activa && boton_press != 4'b1111)
                    next = LOAD;
            end

            LOAD: begin
                // solo 1 ciclo para cargar
                next = RELEASE;
            end

            RELEASE: begin
                // espera a soltar
                if (!tecla_activa)
                    next = SCAN;
            end

            default: next = SCAN;
        endcase
    end

    //========================================================
    // 7) Registro de estado + acción de guardado
    //========================================================
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            estado       <= SCAN;
            display_data <= 16'hFFFF; // apagado inicial
        end else begin
            estado <= next;

            case (estado)
                LOAD: begin
                    // desplaza y mete nueva tecla en unidades
                    display_data <= {3'b000, key, 4'b1111, boton_press, boton_press};//{display_data[11:0], boton_press};
                end
                default: begin
                    display_data <= {3'b000, key, display_data[11:0]};
                end
            endcase
        end
    end

    //========================================================
    // 8) Tu multiplexor de 7 segmentos
    //========================================================
    display_7seg display_inst(
        .clk    (clk),
        .rst    (rst),
        .digito (display_data),
        .anodo  (anodo),
        .seven  (seven)
    );

endmodule

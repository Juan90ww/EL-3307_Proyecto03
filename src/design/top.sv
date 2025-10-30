module top(
    input   logic       clk,         // Reloj de 27 MHz
    input   logic       rst,         // Reset activo en bajo
    output  logic [3:0] anodo,   // Ánodos del display (asumiendo 4 dígitos para el resultado)
    output  logic [6:0] seven,  // Segmentos del display
    output  logic [3:0] col, // Columnas del teclado
    input   logic [3:0] fil    // Filas del teclado
);
    // Señales del teclado
    logic [3:0] boton;
    logic       key;
    logic       key_prev; // Para detectar flancos de subida de key_pressed
    logic       key_new;

    // Instancia del escáner del teclado
    teclado teclado(
        .clk        (clk),
        .rst        (rst),
        .columnas   (col),
        .filas      (fil),
        .boton      (boton),          // Código de la tecla presionada
        .ctrl       (key) // Indicador de tecla presionada (puede durar varios ciclos)
    );

    // Detector de Flanco para Tecla Presionada    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            key_prev <= 1'b0;
            key_new <= 1'b0;
        end else begin
            key_prev <= key;
            key_new <= key && !key_prev;
        end
    end

    // Maquina de estados
    typedef enum logic [1:0] {
        STATE_INPUT_A,      // Ingresando número A
        STATE_INPUT_B,      // Ingresando número B
    } operation_state_t;

    operation_state_t current_state, next_state;

    // Registro de numeros BCD (apaaagaado: 4'b1111)
    logic [3:0] A0, A1, A2; // U C D (A)
    logic [3:0] B0, B1, B2; // U C D (B)

    // Lógica de Estado y Registro de Números
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= STATE_INPUT_A; // Estado inicial: ingresar A
            A0 <= 4'b1111; A1 <= 4'b1111; A2 <= 4'b1111;
            B0 <= 4'b1111; B1 <= 4'b1111; B2 <= 4'b1111;
        end else begin
            current_state <= next_state; 
            if (key_new) begin
                case (boton)
                    // Tecla '*' (4'b1101): Reiniciar todo
                    4'b1101: begin
                        A0 <= 4'b1111; A1 <= 4'b1111; A2 <= 4'b1111;
                        B0 <= 4'b1111; B1 <= 4'b1111; B2 <= 4'b1111;
                        // El estado se reiniciará en la lógica de siguiente estado
                    end

                    // Tecla '#' (4'hF): Cambiar de estado o calcular
                    4'b1110: begin
                        // La transición de estado se maneja en la lógica de siguiente estado
                    end
                    // Teclas numéricas (0-9)
                    default: begin
                        if (current_state == STATE_INPUT_A) begin
                            // Ingreso para A: desplazamiento izquierda
                            A2 <= A1;
                            A1 <= A0;
                            A0 <= boton; // Asumiendo que 'boton' contiene el valor BCD 0-9
                        end else if (current_state == STATE_INPUT_B) begin
                            // Ingreso para B: desplazamiento izquierda
                            B2 <= B1;
                            B1 <= B0;
                            B0 <= boton; // Asumiendo que 'key' contiene el valor BCD 0-9
                        end
                        // No hacer nada si estamos en STATE_SHOW_SUM
                    end
                endcase
            end
        end
    end

    // Lógica de Siguiente Estado (Combinacional)
    always_comb begin
        next_state = current_state; // Por defecto, mantener el estado actual
        if (!rst) begin // Manejo explícito del reset asíncrono en la lógica combinacional
           next_state = STATE_INPUT_A;
        end else if (key_new) begin // Transición solo en flanco de tecla
            case (boton)
                4'b1101: next_state = STATE_INPUT_A; // '*' Reiniciar
                4'b1110: begin 
                    case (current_state)
                        STATE_INPUT_A : next_state = STATE_INPUT_B;
                        STATE_INPUT_B : next_state = STATE_INPUT_A;
                    endcase
                end
            endcase
        end
    end

    // Lógica de Selección para el Display (Combinacional)
    logic [15:0] display_data;
    always_comb begin
        display_data = 16'hFFFF;
        unique case (current_state)
            STATE_INPUT_A:  display_data = {4'b1010, A2, A1, A0};
            STATE_INPUT_B:  display_data = {4'b1011, B2, B1, B0};
        endcase
    end
    // Instancia del Display Multiplexado
    display_7seg display (
        .clk(clk),
        .rst(rst),
        .digito(display_data), // Pasa el dato seleccionado al display
        .anodo(anodo),         // Controla qué dígito se enciende
        .seven(seven)            // Controla qué segmentos se encienden
    );
endmodule

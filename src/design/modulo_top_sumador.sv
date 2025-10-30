module modulo_top_sumador (
    input  logic clk,              // Reloj 27 MHz
    input  logic rst_n,            // Reset activo en bajo

    // Teclado matricial 4x4
    output logic [3:0] filas,      
    input  logic [3:0] columnas,

    // Display 7 segmentos (ánodo común)
    output logic [6:0] seven,      
    output logic [3:0] anodo,

    // (Opcional)
    input  logic [3:0] dip_switch
);

    logic [3:0] key_value;
    logic key_valid;

    typedef enum logic [1:0] {IDLE, LOAD_A, LOAD_B, SHOW_RESULT} state_t;
    state_t state, next_state;

    logic [3:0] a2, a1, a0;
    logic [3:0] b2, b1, b0;
    logic [3:0] d3, d2, d1, d0;

    logic load, start_conv, ready;
    logic [1:0] digit_count;


    lector_teclado keypad_inst (
        .clk(clk),
        .rst_n(rst_n),
        .filas(filas),
        .columnas(columnas),
        .key_value(key_value),
        .key_valid(key_valid)
    );

    top_adder adder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a2(a2), .a1(a1), .a0(a0),
        .b2(b2), .b1(b1), .b0(b0),
        .load(load),
        .start_conv(start_conv),
        .out_d3(d3), .out_d2(d2), .out_d1(d1), .out_d0(d0),
        .ready(ready)
    );


    display_mux disp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .d3(d3), .d2(d2), .d1(d1), .d0(d0),
        .seven(seven),
        .anodo(anodo)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            digit_count <= 0;
            a2 <= 0; a1 <= 0; a0 <= 0;
            b2 <= 0; b1 <= 0; b0 <= 0;
        end else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        load = 0;
        start_conv = 0;

        case (state)
            
            IDLE: begin
                if (key_valid)
                    next_state = LOAD_A;
            end

            LOAD_A: begin
                if (key_valid) begin
                    case (digit_count)
                        2'd0: a2 = key_value;
                        2'd1: a1 = key_value;
                        2'd2: begin
                            a0 = key_value;
                            next_state = LOAD_B;
                            digit_count = 0;
                        end
                    endcase
                    digit_count = digit_count + 1;
                end
            end

            // Captura número B (3 dígitos)
            LOAD_B: begin
                if (key_valid) begin
                    case (digit_count)
                        2'd0: b2 = key_value;
                        2'd1: b1 = key_value;
                        2'd2: begin
                            b0 = key_value;
                            next_state = SHOW_RESULT;
                            load = 1;
                            start_conv = 1;
                            digit_count = 0;
                        end
                    endcase
                    digit_count = digit_count + 1;
                end
            end

            // Espera la suma y muestra el resultado
            SHOW_RESULT: begin
                if (ready)
                    next_state = IDLE;
            end
        endcase
    end

endmodule

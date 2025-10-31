module debounce (
    input  logic clk,
    input  logic rst,           // reset activo en bajo
    input  logic key,             // señal de entrada (con rebotes)
    output logic key_pressed      // salida debounced (1 mientras tecla estable)
);

    parameter N = 6;
    parameter integer COUNT = 15_000_000; // Ajusta para el tiempo deseado, 1s a 27MHz %%

    logic [N-1:0] reg_sat, reg_next;
    logic SAMPLE1, SAMPLE2;
    logic reg_reset = (SAMPLE1 ^ SAMPLE2);
    logic reg_add   = ~reg_sat[N-1];

    logic [31:0] counter;
    logic active;

    always_comb begin
        case ({reg_reset, reg_add})
            2'b00: reg_next = reg_sat;
            2'b01: reg_next = reg_sat + 1;
            default: reg_next = {N{1'b0}};
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            SAMPLE1        <= 0;
            SAMPLE2        <= 0;
            reg_sat       <= 0;
            key_pressed <= 0;
            active      <= 0;
            counter     <= 0;
        end else begin
            SAMPLE1  <= key;
            SAMPLE2  <= SAMPLE1;
            reg_sat <= reg_next;

            if (reg_sat[N-1] && SAMPLE2 && !active) begin
                key_pressed <= 1;
                active      <= 1;
                counter     <= 0;
            end else if (active) begin
                if (counter < COUNT) begin
                    counter <= counter + 1;
                end else begin
                    key_pressed <= 0;
                    active      <= 0;
                end
            end
        end
    end

endmodule
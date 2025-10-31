module divisor_resta (
    input   logic       dividendo,
    input   logic [3:0] divisor,
    input   logic [3:0] resto_prima,
    output  logic       cociente,
    output  logic [3:0] resto_ant
);
    logic [3:0] resto;  
    logic signed [4:0] resta; 

    always_comb begin
        resto = {resto_prima[2:0],dividendo}; 
        resta = $signed({1'b0, resto}) - $signed({1'b0, divisor});
        if (resta < 0) begin
            cociente = 1'b0; 
            resto_ant = resto;
        end else begin
            cociente = 1'b1; 
            resto_ant = resta [3:0];
        end
    end
endmodule
`timescale 1ns / 1ps

module Smoke_Test(
    input clk,
    output reg[2:0] led
);

integer counter = 0;

always @(posedge clk) begin
    if (counter >= 40) //Contador adaptado para el Testbench
        counter <= 0;
    else
        counter <= counter + 1;    
end

always @(posedge clk) begin
    if (counter == 0)
        led <= 3'b001; // Rojo
    else if (counter == 10)
        led <= 3'b011; // Amarillo
    else if (counter == 20)
        led <= 3'b010; // Verde
    else if (counter == 30)
        led <= 3'b011; // Amarillo
end

endmodule
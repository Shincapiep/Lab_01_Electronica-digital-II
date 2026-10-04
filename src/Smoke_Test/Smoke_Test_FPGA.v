`timescale 1ns / 1ps
module Smoke_Test_FPGA(
    input clk,
    output reg[2:0] led
    );
    
integer counter=0;

always @(posedge  clk) 

    begin
    if (counter>=320000000) //Contador adaptado para la FPGA
        counter <= 0;
    else
        counter <= counter + 1;   
    end

always @(posedge  clk)
    
    begin
    if (counter == 0)
        led <= 3'b001;//Rojo
    else if (counter == 80000000)
        led <= 3'b011;//Amarillo
    else if (counter == 160000000)
        led <= 3'b010;//Verde
    else if (counter == 240000000)
        led <= 3'b011;//Amarillo
    end
    
endmodule

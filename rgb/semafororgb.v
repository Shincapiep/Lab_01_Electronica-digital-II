`timescale 1ns / 1ps
// ============================================================
// Smoke Test - Semaforo en LED RGB #6 (LD6) de la Zybo Z7
// Reloj: 125 MHz (pin K17)  ->  T_clk = 8 ns
// Secuencia: Rojo -> Amarillo -> Verde -> Amarillo -> (repite)
// Cada estado dura N_ESTADO ciclos (80e6 * 8 ns = 0.64 s en hardware)
//
// Mapeo segun el .xdc:  led[0] = R (V16)
//                       led[1] = B (M17)
//                       led[2] = G (F17)
//  => led = {G, B, R}
//
// N_ESTADO es un parametro para poder simular con valores pequenos.
// En sintesis se usa el valor por defecto (80e6).
// ============================================================
module Semaforo #(
    parameter integer N_ESTADO = 80000000
)(
    input            clk,
    output reg [2:0] led
    );

    localparam integer N_TOTAL = 4 * N_ESTADO;   // 320e6 en hardware

    // Colores codificados como {G, B, R}
    localparam [2:0] ROJO     = 3'b001;
    localparam [2:0] AMARILLO = 3'b101;          // R + G
    localparam [2:0] VERDE    = 3'b100;

    integer counter = 0;

    // Contador de ciclos: 0 ... N_TOTAL
    always @(posedge clk) begin
        if (counter >= N_TOTAL)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // Cambio de color en cada cuarto del periodo
    always @(posedge clk) begin
        if (counter == 0)
            led <= ROJO;
        else if (counter == N_ESTADO)
            led <= AMARILLO;
        else if (counter == 2*N_ESTADO)
            led <= VERDE;
        else if (counter == 3*N_ESTADO)
            led <= AMARILLO;
    end

endmodule

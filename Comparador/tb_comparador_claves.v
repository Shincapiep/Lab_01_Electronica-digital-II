`timescale 1ns / 1ps

module tb_comparador_claves;

    // Declaración de entradas (reg) y salidas (wire)
    reg  [3:0] sw;
    reg  [5:0] btn;

    wire [3:0] led;
    wire [2:0] led_rgb;

    // Instanciación del módulo a probar (UUT)
    comparador_claves uut (
        .sw(sw),
        .btn(btn),
        .led(led),
        .led_rgb(led_rgb)
    );

    initial begin
        // Configuración para generación del archivo .vcd para GTKWave
        $dumpfile("tb_comparador_claves.vcd");
        $dumpvars(0, tb_comparador_claves);

        // Estado Inicial
        sw  = 4'b0000;
        btn = 6'b000000;
        #10;

        // Caso 1: Resta simple sin máscara (10 - 3 = 7 -> 0111 en LEDs)
        sw  = 4'b1010;
        btn = 6'b000011;
        #20;

        // Caso 2: Resta con máscara activa (10 - 12 = -2 -> 1110 en LEDs)
        btn = 6'b010011;
        #20;

        // Caso 3: Suma sin máscara (5 + 3 = 8 -> 1000 en LEDs)
        sw  = 4'b0101;
        btn = 6'b100011;
        #20;

        // Caso 4: Verificación LED RGB (Entradas idénticas)
        sw  = 4'b1100;
        btn = 6'b001100;
        #20;

        // Caso 5: Verificación LED RGB (Entradas complementarias)
        sw  = 4'b1010;
        btn = 6'b000101;
        #20;

        $display("Simulación completada.");
        $finish;
    end

endmodule
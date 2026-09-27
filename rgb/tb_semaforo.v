`timescale 1ns / 1ps
// ============================================================
// Testbench autoverificable del Semaforo
//  - Reloj de 125 MHz (8 ns), igual al de la Zybo Z7
//  - N_ESTADO reducido a 10 ciclos para que la simulacion sea corta
//  - Verifica: orden de colores y duracion de cada estado
// ============================================================
module tb_semaforo;

    localparam integer N_ESTADO = 10;
    localparam real    T_CLK    = 8.0;           // ns
    localparam integer N_CICLOS = 3;             // ciclos completos a verificar

    localparam [2:0] ROJO     = 3'b001;
    localparam [2:0] AMARILLO = 3'b101;
    localparam [2:0] VERDE    = 3'b100;

    reg        clk = 1'b0;
    wire [2:0] led;

    // Dispositivo bajo prueba
    Semaforo #(.N_ESTADO(N_ESTADO)) dut (
        .clk (clk),
        .led (led)
    );

    // Reloj de 125 MHz
    always #(T_CLK/2) clk = ~clk;

    // Secuencia esperada
    reg [2:0] esperado [0:3];
    initial begin
        esperado[0] = ROJO;
        esperado[1] = AMARILLO;
        esperado[2] = VERDE;
        esperado[3] = AMARILLO;
    end

    // Nombre del color para los mensajes
    function [63:0] nombre;
        input [2:0] c;
        case (c)
            ROJO:     nombre = "ROJO    ";
            AMARILLO: nombre = "AMARILLO";
            VERDE:    nombre = "VERDE   ";
            3'b010:   nombre = "AZUL    ";
            default:  nombre = "OTRO    ";
        endcase
    endfunction

    // Verificador: se ejecuta en cada cambio de led
    integer idx     = 0;
    integer errores = 0;
    real    t_ant   = 0.0;
    real    dur, dur_esp;

    always @(led) begin
        if (led !== 3'bxxx) begin
            // 1) Color
            if (led !== esperado[idx % 4]) begin
                $display("[%0.1f ns] ERROR: color %s, se esperaba %s",
                         $realtime, nombre(led), nombre(esperado[idx % 4]));
                errores = errores + 1;
            end else
                $display("[%0.1f ns] OK: %s", $realtime, nombre(led));

            // 2) Duracion del estado anterior
            if (idx > 0) begin
                dur = $realtime - t_ant;
                // El ultimo estado (2do amarillo) dura 1 ciclo mas porque
                // el contador cuenta de 0 a N_TOTAL inclusive
                dur_esp = (idx % 4 == 0) ? (N_ESTADO + 1) * T_CLK
                                         :  N_ESTADO      * T_CLK;
                if (dur != dur_esp) begin
                    $display("           ERROR: duracion %0.1f ns, se esperaba %0.1f ns",
                             dur, dur_esp);
                    errores = errores + 1;
                end else
                    $display("           duracion estado anterior = %0.1f ns", dur);
            end

            t_ant = $realtime;
            idx   = idx + 1;
        end
    end

    // Control de la simulacion
    initial begin
        $dumpfile("tb_semaforo.vcd");
        $dumpvars(0, tb_semaforo);

        wait (idx == 4*N_CICLOS + 1);   // N_CICLOS completos + regreso a rojo
        #(T_CLK);

        $display("--------------------------------------------");
        if (errores == 0)
            $display("SMOKE TEST (simulacion): PASO - %0d transiciones verificadas", idx);
        else
            $display("SMOKE TEST (simulacion): FALLO - %0d errores", errores);
        $display("--------------------------------------------");
        $finish;
    end

    // Tiempo maximo por si el DUT no cambia nunca
    initial begin
        #(T_CLK * (4*N_ESTADO + 1) * (N_CICLOS + 2));
        $display("TIMEOUT: el LED no completo la secuencia (%0d transiciones)", idx);
        $finish;
    end

endmodule

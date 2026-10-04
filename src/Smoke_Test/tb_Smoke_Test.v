`timescale 1ns / 1ps

module tb_Smoke_Test;

    reg clk;
    wire [2:0] led;

    Smoke_Test uut (
        .clk(clk),
        .led(led)
    );

    // Reloj con periodo de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_Smoke_Test.vcd");
        $dumpvars(0, tb_Smoke_Test);

        // 600 ns es suficiente para ver varios ciclos del contador reducido
        #600;

        $finish;
    end

endmodule
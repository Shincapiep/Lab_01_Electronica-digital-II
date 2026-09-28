`timescale 1ns / 1ps

module comparador_claves (
    input  wire [3:0] sw,        // SW[3:0]: Clave Principal (Operando A)
    input  wire [5:0] btn,       // BTN[3:0]: Clave Ingresada (Operando B)
                                 // BTN[4]: Máscara XOR de Seguridad (invierte B)
                                 // BTN[5]: Modo Aritmético (0 = Resta, 1 = Suma)
    output wire [3:0] led,       // LED[3:0]: Resultado Aritmético de 4 bits
    output wire [2:0] led_rgb    // LED_RGB: [0]=Rojo (AND), [1]=Verde (OR), [2]=Azul (XOR)
);

    // 1. Operando A tomado de los Switches
    wire [3:0] operando_a = sw[3:0];
    
    // 2. Operando B con Máscara XOR controlada por BTN[4]
    wire [3:0] operando_b = btn[4] ? (btn[3:0] ^ 4'b1111) : btn[3:0];

    // 3. Operación Aritmética de 4 bits (Suma / Resta) seleccionada por BTN[5]
    wire [3:0] res_aritmetico = btn[5] ? (operando_a + operando_b) : (operando_a - operando_b);

    // 4. Operaciones Lógicas
    wire [3:0] res_and = operando_a & operando_b;
    wire [3:0] res_or  = operando_a | operando_b;
    wire [3:0] res_xor = operando_a ^ operando_b;

    // 5. Asignación de Salidas
    assign led[3:0] = res_aritmetico;

    // Reducción OR para activar los canales del LED RGB si hay al menos un bit en '1'
    assign led_rgb[0] = |res_and; // Canal Rojo: Coincidencia de bits '1' (AND)
    assign led_rgb[1] = |res_or;  // Canal Verde: Presencia de bits '1' (OR)
    assign led_rgb[2] = |res_xor; // Canal Azul: Disparidad entre bits (XOR)

endmodule
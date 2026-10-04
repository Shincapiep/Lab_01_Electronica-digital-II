
# Laboratorio 01: FPGA (Zybo Z7), Vivado/Vitis y Validación de Hardware

* **Asignatura:** Electrónica Digital II
* **Semestre:** 2026-2

## Integrantes del equipo

* **Samuel Hincapie Perilla**
* **Eduardo Felipe Camacho Lara**
* **Gabriel Alberto Rodríguez Rincón**

---

## Contenido

1. [Instalación y configuración del proyecto](#1-instalación-y-configuración-del-proyecto)
2. [Smoke Test: semáforo en LED RGB](#2-smoke-test-semáforo-en-led-rgb)
3. [Test funcional personalizado: comparador de claves](#3-test-funcional-personalizado-comparador-de-claves)
4. [Conclusiones](#4-conclusiones)

---

## 1\. Instalación y configuración del proyecto

Se instalaron Vivado y Vitis 2025.2 mediante el *AMD Unified Installer* y se activó la licencia **Vivado Basic Tier (Node-Locked)**.

El proyecto se creó como **RTL Project** con los siguientes parámetros:

|Parámetro|Valor|
|-|-|
|Parte|`xc7z010clg400-1`|
|Fuentes|`semaforo.v` / `comparador\_claves.v`|
|Constraints|`Zybo-Z7.xdc` (Digilent)|

---

## 2\. Smoke Test: Semáforo en LED RGB

### 2.1 Objetivo Del Ejercicio

* Validar la correcta instalación y funcionamiento del entorno de desarrollo: Visual Studio Code, Icarus Verilog (`iverilog`) y GTKWave.
* Compilar y simular el módulo de control secuencial en Verilog (`Smoke_Test.v`) para confirmar la generación del archivo `.vcd`.
* Inspeccionar y verificar la transición temporal de las salidas de los LEDs (`led[2:0]`) e interpretar la secuencia del semáforo en el visor GTKWave.
* Verificar el flujo completo **HDL → Síntesis → Implementación → Bitstream → Programación por JTAG**, junto con el reloj de la tarjeta y el mapeo de pines del `.xdc`, usando el diseño entregado en la guía del laboratorio.

---
### 2.2 Descarga del Módulo Secuencial y Creación del Testbench:

Se descargó el archivo `Smoke_Test.v` y posteriormente se creó el archivo `tb_Smoke_Test.v` en Visual Studio Code. La función de cada uno es la siguiente:

* `Smoke_Test.v`: Módulo secuencial que conmuta la salida `led[2:0]`.
* `tb_Smoke_Test.v`: Banco de pruebas (*Testbench*) encargado de instanciar el módulo principal, generar el reloj (`clk`) y exportar los datos al archivo `.vcd`.

Un detalle importante que es necesario destacar, es que durante el desarrollo del testbench se identificó una diferencia fundamental entre el comportamiento en hardware real y la simulación virtual:

* **Hardware Real (FPGA):** Funciona a una frecuencia de reloj elevada (por ejemplo, 100 MHz que equivalen a un periodo de $10\text{ ns}$). Por lo que si se busca que los cambios de color del semáforo sean visibles al ojo humano, se requieren contadores de escala enormes (como $80\,000\,000$ de ciclos para alcanzar $0.8\text{ segundos}$).
* **Entorno de Simulación (Testbench / GTKWave):** Intentar simular $320\,000\,000$ de ciclos en un entorno virtual generaría archivos `.vcd` de varios gigabytes y exigiría tiempos de procesamiento extremadamente largos. Por esta razón, para el testbench se redujeron los límites del contador a escala de decenas de ciclos ($10, 20, 30, 40$). Esto permite validar la máquina de estados y las transiciones del semáforo en tan solo $600\text{ ns}$ de tiempo simulado sin saturar los recursos del sistema.

Teniendo en cuenta lo anterior, se crearon dos archivos `.v` para esta parte, uno denominado `Smoke_Test.v` que fue implementado para la creación y visualización del testbench y otro denominado `Smoke_Test_FPGA.v` que se usó para compilar y programar la FPGA. 

Luego se utilizó la terminal de Visual Studio Code para ejecutar la compilación del código mediante el ejecutable de Icarus Verilog (iverilog) especificando el nombre del archivo de salida compilado:
```bash
iverilog -o tb_Smoke_Test.vvp tb_Smoke_Test.v Smoke_Test.v
```
A continuación, se ejecutó el motor de simulación vvp para procesar el binario y generar el archivo `.vcd` correspondiente:
```bash
vvp tb_Smoke_Test.vvp
```
Se abrió la herramienta GTKWave y se cargó el archivo de simulación .vcd generado.
```bash
gtkwave tb_Smoke_Test.vcd
```

---

### 2.3 Simulación Virtual en GTKwave

En la siguiente imágen se observa el resultado de la simulación en gtkwave:

<img width="1632" height="133" alt="image" src="https://github.com/user-attachments/assets/780c762d-366b-45e0-b48c-50d96c860661" />

Como se puede ver en la imagen anterior, el comportamiento de la prueba fue el esperado, ya que la secuencia de salidas en el registro `led[2:0]` concuerda exactamente con los estados temporales programados para el semáforo.

* **Comportamiento Estado Rojo (`led = 3'b001`):** Su valor está activo desde los 5 ns hasta los 105 ns, manteniéndose durante los primeros 10 ciclos del reloj.
* **Comportamiento Estado Amarillo (`led = 3'b011`):** Su valor conmuta a los 105 ns y permanece activo hasta los 205 ns.
* **Comportamiento Estado Verde (`led = 3'b010`):** Su valor se activa en el intervalo de 205 ns a 305 ns.
* **Comportamiento Retorno a Amarillo (`led = 3'b011`):** Conmuta nuevamente a los 305 ns y se mantiene hasta los 405 ns.
* **Reinicio de ciclo:** A los 405 ns el contador vuelve a cero reiniciando la secuencia en Estado Rojo (`3'b001`), para posteriormente conmutar de nuevo a Amarillo a los 505 ns.

---

### 2.4 Funcionamiento y Análisis del Código

El módulo `Smoke_Test_FPGA` implementa el control secuencial de un LED RGB mediante una señal de reloj `clk`. El módulo recibe como entrada la señal de reloj de la FPGA y genera una salida de 3 bits `led[2:0]` conectada a los canales del LED RGB LD6 de la tarjeta Zybo Z7. El funcionamiento del diseño se basa en una arquitectura secuencial implementada mediante dos bloques `always @(posedge clk)`, los cuales se ejecutan en cada flanco ascendente de la señal de reloj:

1. **Contador Principal:** El primer bloque corresponde al contador principal, cuya función es manejar los tiempos para determinar el momento en que debe cambiar el color del LED. La variable `counter` se inicializa en cero y se incrementa en una unidad en cada ciclo de reloj. Cuando el contador alcanza el valor de 320\,000\,000$, se reinicia a cero, permitiendo que la secuencia de colores se repita continuamente. Esto ocurre en el fragmento:
```verilog
if (counter>=320000000) //Contador adaptado para la FPGA
        counter <= 0;
    else
        counter <= counter + 1;   
    end
```

2. **Máquina de Estados de Selección de Color:** El segundo bloque implementa la selección de los colores del LED RGB. En este bloque se evalúa continuamente el valor del contador `counter` y, de acuerdo con los intervalos previamente establecidos, se actualiza el registro `led[2:0]`. Al utilizar asignaciones no bloqueantes (`<=`), la salida conserva el valor asignado durante el intervalo correspondiente, hasta que el contador alcance el siguiente límite y se produzca una nueva actualización. Esto ocurre en la siguiente parte del código:
```verilog
if (counter == 0)
        led <= 3'b001;//Rojo
    else if (counter == 80000000)
        led <= 3'b011;//Amarillo
    else if (counter == 160000000)
        led <= 3'b010;//Verde
    else if (counter == 240000000)
        led <= 3'b011;//Amarillo
    end
```

---

3. **Tabla de Transición de Estados y Mapeo de Colores:** El comportamiento del LED puede dividirse en cuatro intervalos principales. Inicialmente, el contador se encuentra en cero y se activa el color rojo. Después de 80\,000\,000 ciclos de reloj, la salida cambia a amarillo. Posteriormente, al alcanzar 160\,000\,000 ciclos, el LED cambia a verde. Finalmente, al llegar a 240\,000\,000 ciclos, vuelve a amarillo. Una vez completado este último intervalo, cuando el contador alcance los 320\,000\,000 ciclos, la secuencia se reinicia y comienza nuevamente desde el color rojo. El comportamiento del código se resume en la próxima tabla:

| Valor de `counter` | Intervalo de Ciclos | Estado Lógico | Salida `led[2:0]` | Canales Activos | Color Resultante |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 0 | 0 < `counter` < 80 x 10^6 | Estado 1 | `3'b001` | Canal Rojo (`led[0]`) | 🔴 Rojo |
| 80\,000\,000 | 80 x 10^6 < `counter` < 160 x 10^6 | Estado 2 | `3'b011` | Rojo + Verde (`led[0]`, `led[1]`) | 🟡 Amarillo |
| 160\,000\,000 | 160 x 10^6 < `counter` < 240 x 10^6 | Estado 3 | `3'b010` | Canal Verde (`led[1]`) | 🟢 Verde |
| 240\,000\,000 | 240 x 10^6 < `counter` < 320 x 10^6 | Estado 4 | `3'b011` | Rojo + Verde (`led[0]`, `led[1]`) | 🟡 Amarillo |

**Nota de Comparación:** Mientras que en `Smoke_Test_FPGA.v` cada color dura 80\,000\,000 ciclos de reloj, para ser perfectamente apreciable en la FPGA, en la versión de simulación `Smoke_Test.v` cada estado dura únicamente 10 ciclos de reloj para verificar la transición correcta de estados en GTKWave sin sobrecargar el tiempo de cómputo.

### 2.5 Mapeo de pines (`.xdc`)

Para la implementación en la tarjeta Zybo Z7, se utilizó el archivo `Pines_Smoke_Test.xdc`, habilitando únicamente las señales del reloj del sistema y los tres canales del LED RGB LD6.

```tcl
## Reloj del Sistema (125 MHz)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; # sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

#LEDs (Comentados para no hacer conflicto)
#set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L23P_T3_35 Sch=led[0]
#set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L23N_T3_35 Sch=led[1]
#set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; #IO_0_35 Sch=led[2]
#set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]

##RGB LED 5 (Zybo Z7-20 only) 
#set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { led5_r }]; #IO_L18N_T2_13 Sch=led5_r
#set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { led5_g }]; #IO_L19P_T3_13 Sch=led5_g
#set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33 } [get_ports { led5_b }]; #IO_L20P_T3_13 Sch=led5_b

##RGB LED 6 (Descomentado y renombrado para Smoke_Test.v)
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; # Canal Rojo  (Rojo)
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; # Canal Verde (Verde)
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; # Canal Azul  (Azul)

```

| Señal HDL | Pin FPGA | Canal |
| :---: | :---: | :---: | 
| `clk` | K17 | Reloj del sistema (125 MHz) | 
| `led[0]` | V16 | Canal Rojo (R) del LED RGB LD6 |
| `led[1]` | F17 | Canal Verde (G) del LED RGB LD6 | 
| `led[2]` | M17 | Canal Azul (B) del LED RGB LD6 | 


**Modificación y Renombrado de Pines:** Se descomentó la línea del pin `K17` correspondiente al reloj de 125 MHz de la FPGA y también los pines correspondientes a los tres colores del LED LD6 (`V16`, `F17`, `M17`) y se renombraron sus puertos en la instrucción `get_ports` de `led6_r`, `led6_g` y `led6_b` a `led[0]`, `led[1]` y `led[2]` respectivamente, logrando el enlace directo con el vector de salida `led[2:0]` del módulo `Smoke_Test_FPGA.v`.

**Prevención de Conflictos de Puerto:** Se tuvo que dejar comentadas las entradas de los Leds monocromáticos de la tarjeta (`led[0]` a `led[3]`). Si se hubieran dejado activas, Vivado habría generado un error fatal de conflicto de nombres de puerto duplicados (Port Name Collision) durante la fase de síntesis. 

**Restricción Temporal:** Se utilizó `create\_clock` para informar a la herramienta que el reloj tiene un periodo de 8 ns, que es el valor que usa el análisis de tiempos durante la implementación.

### 2.6 Evidencia en hardware

Para poder implementar el smoke test en la FPGA y demostrar el correcto funcionamiento de todos los procesos y archivos mostrados hasta el momento, fue necesario seguir los siguientes pasos:
1. **Síntesis e Implementación:** Se importaron los archivos `Smoke_Test_FPGA.v` y `Pines_Smoke_Test.xdc` en Xilinx Vivado. Se ejecutaron los procesos de síntesis e implementación sin errores de temporización ni conflictos de asignación de I/O.
2. **Generación del Bitstream:** Se generó exitosamente el archivo ejecutable de hardware (`.bit`).
3. **Programación JTAG:** Se conectó la tarjeta Zybo Z7-20 a la estación de trabajo mediante el puerto Micro-USB. Luego se abrió el Hardware Manager de Vivado, se detectó la FPGA y se programó el dispositivo mediante la interfaz JTAG.

A continuación, se muestra el video del correcto funcionamiento del Smoke Test:

https://github.com/user-attachments/assets/3a1d6b7b-a830-423f-acc0-ff0b0b93ff32

Una vez cargado el bitstream en la FPGA, el LED RGB comenzó la secuencia cíclica de manera inmediata, validando físicamente la lógica del contador y las asignaciones de color:

* **Estado 1 (Rojo):** Se enciende el canal rojo (`led[0] = 1`).
* **Estado 2 (Amarillo):** Se activan simultáneamente el canal rojo y verde (`led[0] = 1`, `led[1] = 1`), generando la mezcla de color amarillo.
* **Estado 3 (Verde):** Se activa el canal verde (`led[1] = 1`).
* **Estado 4 (Amarillo):** Retorna a la combinación rojo + verde para generar el color amarillo.
* **Reinicio de ciclo:** Transcurridos todos los estados, la secuencia reinicia de forma continua en Estado Rojo.

### 2.7 Conclusiones

* El sistema demostró un comportamiento estable en todos los estados, respondiendo correctamente dentro de los parámetros esperados para la prueba inicial.
* Los Leds rojo, amarillo y verde se encendieron debido a que en el código se asignó explícitamente patrones de bits específicos para prender dichos colores en cada umbral del contador. Como se puede ver de esos patrones (`3'b001`, `3'b011`, `3'b010`), el bit más significativo es el led azul, el segundo bit más significativo es el verde y el bit menos significativo es el rojo.
* El Led azul permaneció apagado porque ninguna de las condiciones o asignaciones activa el bit correspondiente al azul, es decir `3'b100`

\---

## 3\. Test funcional personalizado: Comparador de claves

### 3.1 Objetivo del Ejercicio

* Diseñar e implementar un módulo combinacional en Verilog (`comparador_claves.v`) que procese la interacción entre una clave principal (operando A) y una clave ingresada (operando B).
* Implementar una máscara de seguridad XOR de 4 bits para invertir el operando B mediante un pulsador de control (`btn[4]`).
* Integrar un bloque aritmético de 4 bits capaz de realizar operaciones de suma y resta seleccionables mediante un bit de control (`btn[5]`), visualizando el resultado binario en los Leds individuales y monocromáticos (`led[3:0]`).
* Aplicar operaciones lógicas combinacionales (AND, OR y XOR) sobre los operandos y utilizar operadores de OR para conmutar los canales del LED RGB (`led_rgb[2:0]`) como indicadores de estado.
* Validar el comportamiento combinacional y las transiciones de señales mediante simulación en GTKWave (`tb_comparador_claves.v`) y verificar la implementación en hardware real según los switches (`sw[3:0]`), pulsadores de la FPGA (`btn[3:0]`), y botones externos conectado al puerto Pmod (`btn[4:5]`) y LEDs de la tarjeta Zybo Z7.

### 3.2 Lógica del Ejercicio

El módulo `comparador_claves` constituye un circuito puramente combinacional, por lo que no tiene una Máquina de Estados Finitos (FSM). Esto se justifica por las siguientes razones:
* **Ausencia de señal de reloj (`clk`):** Las FSMs son sistemas secuenciales síncronos que requieren una señal de reloj para marcar la transición entre estados. El módulo opera sin señal de reloj.
* **Ausencia de elementos de memoria (Flip-Flops):** No existen registros destinados a almacenar un estado actual o un estado futuro, ya que su arquitectura se compone únicamente de asignaciones continuas e interconexiones.
* **Respuesta instantánea de salidas:** Las salidas `led[3:0]` y `led_rgb[2:0]` se recalculan en tiempo real en función de los valores presentes en las entradas `sw[3:0]` y `btn[5:0]`, estando limitadas únicamente por el retardo de propagación de las compuertas lógicas de la FPGA.

Por otro lado, para realizar la ASM de este ejercicio hay que tener en cuenta que, generalmente, la ASM se utiliza para describir el comportamiento de una FSM secuencial, por lo que en este tipo de ejercicios se emplea el modelo de ASM de estado único para formalizar el flujo algorítmico de los datos. Este se presenta en la siguiente imagen:

<img width="377" height="637" alt="image" src="https://github.com/user-attachments/assets/e351df18-2e8f-4621-8ef5-be1c5632a48f" />

Como se puede ver, la ASM del consta de un único bloque de estado (S0), del cual parten los caminos condicionales determinados por las entradas de control, su funcionamiento sería el siguiente:

1. **Captura de Entrada:** La variable `operando_a` toma directamente el valor del bus `sw[3:0]`.
2. **Evaluación de Máscara XOR (`btn[4]`):** 
   * Si `btn[4] = 1`, la señal `btn[3:0]` pasa por una compuerta XOR con `4'b1111` (inversión de bits).
   * Si `btn[4] = 0`, la señal `btn[3:0]` se asigna directamente a `operando_b`.
3. **Selección Aritmética (`btn[5]`):**
   * Si `btn[5] = 1`, el sistema ejecuta una suma de la forma `operando_a + operando_b`.
   * Si `btn[5] = 0`, el sistema ejecuta una resta de la forma `operando_a - operando_b`.
4. **Cálculo Lógico y Salidas:** Se ejecutan en paralelo las operaciones AND, OR y XOR sobre los operandos a y b. Los resultados de 4 bits se definen mediante compuertas OR para determinar la conmutación de los canales Rojo, Verde y Azul del Led RGB (`led_rgb[2:0]`), mientras que `res_aritmetico` establece la salida `led[3:0]`.

### 3.3 Funcionamiento y Análisis del Código:

El módulo `comparador_claves` implementa una ALU de 4 bits puramente combinacional. Su propósito es procesar dos operandos de entrada (`operando_a` y `operando_b`), aplicar transformaciones opcionales y calcular tanto operaciones aritméticas como indicadores lógicos de coincidencia. El procesamiento de datos en el módulo se puede dividir en 5 bloques funcionales consecutivos:

1. **Captura del Operando A:**
   Toma directamente los 4 switches de la tarjeta (`sw[3:0]`) como el valor de la clave principal (`operando_a`).
   ```verilog
   wire [3:0] operando_a = sw[3:0];
   ```
   
2. **Acondicionamiento y Máscara XOR para el Operando B:**
   Aquí se utiliza un multiplexor condicional controlado por el pulsador `btn[4]` para definir si se invierte el valor de los bits del `operando_b` o si se mantienen en su valor original. Estos procesos se definen si:
   * `btn[4] = 0` (Pass): `operando_b` = `btn[3:0]`.
   * `btn[4] = 1` (Máscara Activa): Invierte bit a bit la clave ingresada ($btn[3:0] \oplus 1111_2$), lo que equivale a calcular su complemento a 1.
   ```verilog
   wire [3:0] operando_b = btn[4] ? (btn[3:0] ^ 4'b1111) : btn[3:0];
   ```
   
3. **Suma y Resta de 4 bits:**
   El bit del `btn[5]` actúa como selector del modo aritmético de la ALU:
   * `btn[5] = 0` (Resta): `res_aritmetico` = `operando_a - operando_b`.
   * `btn[5] = 1` (Suma): `res_aritmetico` = `operando_a + operando_b`.
   ```verilog
   wire [3:0] res_aritmetico = btn[5] ? (operando_a + operando_b) : (operando_a - operando_b);
   ```
   Hay que tener en cuenta que al definir una salida de 4 bits (`led[3:0]`), si el resultado de una resta da negativo, el valor se representa en Complemento a 2
   
4.  **Evaluación de Vectores Lógicos:**
   Calcula en paralelo las tres operaciones lógicas fundamentales bit a bit entre los vectores de 4 bits del `operando_a`. y el `operando_b`.
   ```verilog
   wire [3:0] res_and = operando_a & operando_b;
   wire [3:0] res_or  = operando_a | operando_b;
   wire [3:0] res_xor = operando_a ^ operando_b;
   ```
   
5.  **Control de los Leds:**
   Aplica el operador de reducción OR (`|`) sobre los resultados vectoriales de 4 bits. Este operador evalúa todos los bits del vector y devuelve un único bit (1 o 0):
   * **Representación Valor Final:** Los leds `led[3:0]` representan el resultado de la operación aritmética realiza entre los operando A y B. Siendo el bit más significativo el `led[3]` y el menos significaativo el `led[0]`.
   * **Canal Rojo (`led_rgb[0]`):** Se enciende si `|res_and = 1`, indicando que ambos operandos coinciden en el valor '1' en al menos una posición.
   * **Canal Verde (`led_rgb[1]`):** Se enciende si `|res_or = 1`, indicando que existe al menos un bit en '1' entre ambos operandos
   * **Canal Azul (`led_rgb[2]`):** Se enciende si `|res_xor = 1`, indicando disparidad o diferencia en al menos una posición de bit entre los operandos.
   ```verilog
   assign led[3:0] = res_aritmetico;

   assign led_rgb[0] = |res_and; // Canal Rojo (AND)
   assign led_rgb[1] = |res_or;  // Canal Verde (OR)
   assign led_rgb[2] = |res_xor; // Canal Azul (XOR)
   ```
El funcionamiento de algunos casos se muestran en la siguiente tabla:

| **Entrada `sw[3:0]` (A)** | **Entrada `btn[3:0]` (B)** | **Máscara XOR`btn[4]`** | **Operando B Final** | **Modo `btn[5]`** | **Operación Aritmética** | **Salida `led[3:0]`** | **res_and** | **res_or** | **res_xor** | **Salida RGB led_rgb {B,G,R}** | **Color Resultante** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `1010` (10) | `0011` (3) | `0` (Off) | `0011` (3) | `0` (Resta) | `10 - 3 = 7` | `0111` (7) | `0010` | `1011` | `1001` | `3'b111` | ⚪ Blanco (R+G+B) |
| `1010` (10) | `0011` (3) | `1` (On) | `1100` (12) | `0` (Resta) | `10 - 12 = -2` | `1110` (14 / -2) | `1000` | `1110` | `0110` | `3'b111` | ⚪ Blanco (R+G+B) |
| `0101` (5) | `0011` (3) | `0` (Off) | `0011` (3) | `1` (Suma) | `5 + 3 = 8` | `1000` (8) | `0001` | `0111` | `0110` | `3'b111` | ⚪ Blanco (R+G+B) |
| `1100` (12) | `1100` (12) | `0` (Off) | `1100` (12) | `0` (Resta) | `12 - 12 = 0` | `0000` (0) | `1100` | `1100` | `0000` | `3'b011` | 🟡 Amarillo (R+G) |
| `1010` (10) | `0101` (5) | `0` (Off) | `0101` (5) | `0` (Resta) | `10 - 5 = 5` | `0101` (5) | `0000` | `1111` | `1111` | `3'b110` | 🔵 Cyan (G+B) |

### 3.4 Mapeo de Pines (`.xdc`):

Para la implementación en la tarjeta Zybo Z7, se elaboró el archivo `Pines_Comparador_Claves`, mapeando las 10 entradas que salen entre switches y botones y las salidas de leds y led_rgb con los periféricos físicos integrados y una extensión externa en puerto Pmod.

```tcl
## Switches integrados (SW[3:0])
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## Pulsadores de la FPGA (BTN[3:0])
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];

## Pulsadores externos en Proto (Pmod JC con Pull-Down externo)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { btn[4] }]; # Pmod JC Pin 1
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { btn[5] }]; # Pmod JC Pin 2

## LEDs Verdes integrados (LED[3:0])
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## RGB LED 6 integrados (LED_RGB[2:0])
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { led_rgb[0] }]; # Canal Rojo
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { led_rgb[1] }]; # Canal Verde
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { led_rgb[2] }]; # Canal Azul

```
La tabla que se presenta a continuación resume el mapeo de pines realizado en `Pines_Comparador_Claves`:

| Señal HDL | Pin FPGA | Periférico Físico | Función Lógica en el Circuito |
|---|---|---|---|
| `sw[0]` | **G15** | Sw0 | Operando A - Bit 0 (LSB) |
| `sw[1]` | **P15** | Sw1 | Operando A - Bit 1 |
| `sw[2]` | **W13**| Sw2 | Operando A - Bit 2 |
| `sw[3]` | **T16** | Sw3 | Operando A - Bit 3 (MSB) |
| `btn[0]` | **K18** | Btn0 | Operando B - Bit 0 (LSB) |
| `btn[1]` | **P16** | Btn1 | Operando B - Bit 1 |
| `btn[2]` | **K19** | Btn2 | Operando B - Bit 2 |
| `btn[3]` | **Y16** | Btn3 | Operando B - Bit 3 (MSB) |
| `btn[4]` | **V15** | Puerto Pmod JC Pin 1 | Máscara XOR |
| `btn[5]` | **W15** | Puerto Pmod JC Pin 2 | Selector de Suma |
| `led[0]` | **M14** | Led0 | Resultado Aritmético - Bit 0 |
| `led[1]` | **M15** | Led1 | Resultado Aritmético - Bit 1 |
| `led[2]` | **G14** | Led2 | Resultado Aritmético - Bit 2 |
| `led[3]` | **D18** | Led3 | Resultado Aritmético - Bit 3 |
| `led_rgb[0]` | **V16** | Led RGB LD6 - Canal Rojo | Indicador Lógico AND (`res_and`) |
| `led_rgb[1]` | **F17** | Led RGB LD6 - Canal Verde | Indicador Lógico OR (`res_or`) |
| `led_rgb[2]` | **M17** | Led RGB LD6 - Canal Azul | Indicador Lógico XOR (`res_xor`) |

**Extensión de Entradas vía Puerto Pmod JC:** Dado que la tarjeta Zybo Z7 cuenta físicamente únicamente con 4 pulsadores integrados (`btn[3:0]`), se requirió ampliar el valor botones a 6 bits para añadir las señales de control de máscara y modo. Se asignaron los pines V15 y W15 del conector Pmod JC para conectar dos pulsadores externos en protoboard.

**Ausencia de Restricción de Reloj:** A diferencia del diseño secuencial del semáforo, en este ejercicio no se habilita el pin del reloj principal K17, ni la instrucción `create_clock`. Al tratarse de un circuito puramente combinacional, Vivado no requiere realizar el análisis estático de tiempos basado en periodo de reloj, optimizando la etapa de síntesis e implementación.

**Coincidencia Exacta con la Interfaz del Módulo:** Las etiquetas utilizadas dentro de `get_ports` coinciden con los nombres declarados en el módulo `comparador_claves.v` (`sw[3:0]`, `btn[5:0]`, `led[3:0]` y `led_rgb[2:0]`), asegurando el enlace correcto de la red combinacional de la FPGA.

### 3.5 Justificación Hardware: Uso de Pulsadores Externos en Puerto Pmod JC

Para el funcionamiento del comparador de claves se requerían 6 señales de entrada definidas mediante pulsadores (`btn[5:0]`), cuatro bits para la clave ingresada (`btn[3:0]`), un bit para la máscara XOR (`btn[4]`) y un bit para el selector de modo de la ALU (`btn[5]`).

A pesar de que la tarjeta Zybo Z7 dispone físicamente de seis pulsadores integrados, fue indispensable añadir dos pulsadores externos mediante el puerto Pmod JC, debido a la arquitectura interna del chip Zynq-7000.

#### 3.5.1 Arquitectura del SoC Zynq-7000: PS vs. PL

El SoC Zynq-7000 de Xilinx/AMD integra dos bloques conceptuales y físicos independientes dentro del mismo encapsulado:

| Sistema | Descripción / Componentes | Entorno de Programación | Conexión de Pines I/O |
| :--- | :--- | :--- | :--- |
| PS (*Processing System*) | Procesador ARM Cortex-A9 y sus periféricos integrados (UART, USB, Ethernet, controladores de memoria y GPIOs de sistema). | Software (C/C++) en el entorno Vitis. | Pines MIO (Sin acceso directo desde lógica HDL)|
| PL (*Programmable Logic*) | Matriz de Lógica Programable equivalente a una FPGA Artix-7. | Lenguajes HDL (Verilog/VHDL) y archivos `.xdc` en Vivado. | Pines de la PL (Totalmente mapeables mediante la directiva `PACKAGE_PIN`) |

#### 3.5.2 Limitación Física de los Pulsadores BTN4 y BTN5

Los pulsadores de la tarjeta Zybo Z7 no comparten la misma infraestructura de conexión eléctrica:

| Botón / Periférico | Pin del SoC | Tipo de Pin | Compatibilidad con Verilog (PL) |
| :---: | :---: | :---: | :---: | :---: |
| **Btn0 – Btn3** | `K18`, `P16`, `K19`, `Y16` | I/O de la PL | Banco PL ($3.3\text{ V}$) | **Compatible** (Mapeados en `.xdc`) |
| **Btn4** | `B13` | **MIO 50 (PS)** | **Incompatible** (Exclusivo del procesador ARM) |
| **Btn5** | `B9` | **MIO 51 (PS)** | **Incompatible** (Exclusivo del procesador ARM) |

* **Causa Técnica del Inconveniente:** Los pines MIO pertenecen exclusivamente al dominio del PS, no poseen trazas de silicio que los conecten directamente con la matriz de conmutación de la FPGA (PL). Por ende, si en el archivo `.xdc` se intentara forzar la asignación de un puerto HDL a la ubicación física de Btn4 (`PACKAGE_PIN B13`), la herramienta Vivado abortaría la fase de implementación emitiendo un error crítico, indicando que dicho pin no es accesible por la lógica programable.

* **Otros Periféricos MIO:** Esta misma restricción aplica al conector Pmod JF y al LED LD4, los cuales también están cableados a pines MIO del procesador ARM y son inaccesibles directamente por el código Verilog.

---

#### 3.5.3 Solución Adoptada: Pulsadores Externos en Pmod JC

Para obtener las señales de control de 4 bits adicionales sin recurrir al PS, se utilizaron los pines `V15` y `W15` del conector Pmod JC, los cuales sí pertenecen al dominio de E/S de la Lógica Programable (PL). Para ello, se montó un circuito de acondicionamiento en protoboard para cada pulsador utilizando resistencias de Pull-Down de $10\text{ k}\Omega$**:

<img width="752" height="581" alt="image" src="https://github.com/user-attachments/assets/53696894-d5f5-434a-9e87-752c1afef729" />

### 3.6 Testbench:

Para verificar la corrección lógica y funcional del módulo combinacional `comparador_claves` antes de su sintesis e implementación en hardware, se desarrolló su respectivo Testbench en el archivo `tb_comparador_claves.v`.

#### 3.6.1 Estructura del Banco de Pruebas (`tb_comparador_claves.v`)

Los elementos principales del testbench son:

1. **Declaración de Señales de Estímulo y Monitoreo:**
   * **Entradas (`reg`):** Se declaran `sw[3:0]` y `btn[5:0]` como tipos `reg` para asignar distintos valores en bloques `initial`.
   * **Salidas (`wire`):** Se declaran `led[3:0]` y `led_rgb[2:0]` como tipos `wire` para capturar en tiempo real las respuestas que tendrá el circuito.

2. **Instanciación de la Unidad Bajo Prueba (UUT):**
   * Se conecta la UUT (`comparador_claves`) mapeando por nombre cada puerto con las señales locales del testbench (`.sw(sw)`, `.btn(btn)`, etc.).

3. **Generación de Archivo VCD para GTKWave:**
   * Se incluyen las tareas del sistema `$dumpfile("tb_comparador_claves.vcd")` y `$dumpvars(0, tb_comparador_claves)` para mostrar todos los cambios de estado de las señales en un archivo `.vcd`.

#### 3.6.2 Desglose Secuencial de los Casos de Prueba

El bloque `initial` evalúa 5 casos combinacionales:

* **Estado Inicial (t = 0 ns):**
  * `sw = 4'b0000`, `btn = 6'b000000`. Se establece el punto de partida en cero durante 10 ns.

* **Caso 1: Resta Simple sin Máscara (t = 10 ns):**
  * **Entrada:** `sw = 4'b1010` (10), `btn = 6'b000011` (`btn[5]=0` Resta, `btn[4]=0` Pass, `btn[3:0]=3`).
  * **Comportamiento Esperado:** Operando A = 10, Operando B = 3.
  * **Salida Esperada:** 10 - 3 = 7 $\rightarrow$ `led = 4'b0111`. RGB en Blanco (`3'b111`).

* **Caso 2: Resta con Máscara XOR Activa (t = 30 ns):**
  * **Entrada:** `sw = 4'b1010` (10), `btn = 6'b010011` (`btn[5]=0` Resta, `btn[4]=1` Máscara XOR, `btn[3:0]=3`).
  * **Comportamiento Esperado:** Operando A = 10, Operando B = `0011 \oplus 1111 = 1100_2` (12).
  * **Salida Esperada:** 10 - 12 = -2 $\rightarrow$ `led = 4'b1110` (14 en complemento a 2). RGB en Blanco (`3'b111`).

* **Caso 3: Suma sin Máscara (t = 50 ns):**
  * **Entrada:** `sw = 4'b0101` (5), `btn = 6'b100011` (`btn[5]=1` Suma, `btn[4]=0` Pass, `btn[3:0]=3`).
  * **Comportamiento Esperado:** Operando A = 5, Operando B = 3.
  * **Salida Esperada:** 5 + 3 = 8 $\rightarrow$ `led = 4'b1000`. RGB en Blanco (`3'b111`).

* **Caso 4: Verificación RGB con Entradas Idénticas (t = 70 ns):**
  * **Entrada:** `sw = 4'b1100` (12), `btn = 6'b001100` (`btn[5]=0` Resta, `btn[4]=0` Pass, `btn[3:0]=12`).
  * **Comportamiento Esperado:** Operando A = 12, Operando B = 12.
  * **Salida Esperada:** 12 - 12 = 0 $\rightarrow$ `led = 4'b0000`.
  * **Respuesta Lógica:** `res_and = 1100` y `res_or = 1100`, mientras que `res_xor = 0000`. RGB = `3'b011` (Rojo + Verde = Amarillo).

* **Caso 5: Verificación RGB con Entradas Complementarias (t = 90 ns):**
  * **Entrada:** `sw = 4'b1010` (10), `btn = 6'b000101` (`btn[5]=0` Resta, `btn[4]=0` Pass, `btn[3:0]=5`).
  * **Comportamiento Esperado:** Operando A = `1010₂` (10), Operando B = `0101₂` (5).
  * **Salida Esperada:** 10 - 5 = 5 $\rightarrow$ `led = 4'b0101`.
  * **Respuesta Lógica:** `res_and = 0000` (Rojo Off), `res_or = 1111` (Verde On), `res_xor = 1111` (Azul On). RGB = `3'b110` (Verde + Azul = Cyan).

---

#### 3.6.3 Comandos para Compilación y Ejecución

Se utilizó la terminal de Visual Studio Code para ejecutar la compilación del código mediante el ejecutable de Icarus Verilog (iverilog) especificando el nombre del archivo de salida compilado:
```bash
iverilog -o tb_comparador_claves.vvp comparador_claves.v tb_comparador_claves.v
```
A continuación, se ejecutó el motor de simulación vvp para procesar el binario y generar el archivo `.vcd` correspondiente:
```bash
vvp tb_comparador_claves.vvp
```
Se abrió la herramienta GTKWave y se cargó el archivo de simulación .vcd generado.
```bash
gtkwave tb_comparador_claves.vcd
```

#### 3.6.4 Simulación en GTKwave:

En la siguiente imágen se observa el resultado de la simulación en gtkwave:

<img width="987" height="218" alt="image" src="https://github.com/user-attachments/assets/ed7b281f-75eb-4452-a257-42c4751dd7b3" />






### 3.7 Evidencia en hardware

Debido al peso de los videos, se subieron a Drive:

|Prueba|Video|
|-|-|
|Suma|[Ver video](https://drive.google.com/file/d/1t9L1MJck8z5sETM7WIkysCyToE96TEmu/view?usp=drive_link)|
|Resta|[Ver video](https://drive.google.com/file/d/10wHqPUYK5qbUX6gKikMrIQrhTMwL7ZEu/view?usp=drive_link)|
|Inversión (XOR)|[Ver video](https://drive.google.com/file/d/1NcaNUGEpHWUaIFor67Q67xMHiMcH-EaO/view?usp=drive_link)|
|Comparación (claves iguales)|[Ver video](https://drive.google.com/file/d/1cw_783hJGDOCyfy101v3lDOaaBDURRYa/view?usp=drive_link)|

\---

## 4\. Conclusiones



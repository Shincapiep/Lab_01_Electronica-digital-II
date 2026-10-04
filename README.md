
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
```bash
if (counter>=320000000) //Contador adaptado para la FPGA
        counter <= 0;
    else
        counter <= counter + 1;   
    end
```

2. **Máquina de Estados de Selección de Color:** El segundo bloque implementa la selección de los colores del LED RGB. En este bloque se evalúa continuamente el valor del contador `counter` y, de acuerdo con los intervalos previamente establecidos, se actualiza el registro `led[2:0]`. Al utilizar asignaciones no bloqueantes (`<=`), la salida conserva el valor asignado durante el intervalo correspondiente, hasta que el contador alcance el siguiente límite y se produzca una nueva actualización. Esto ocurre en la siguiente parte del código:
```bash
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
* Validar el comportamiento combinacional y las transiciones de señales mediante simulación en GTKWave (`tb_comparador_claves.v`) y verificar la implementación en hardware real mapeando switches (`sw[3:0]`), pulsadores integrados (`btn[3:0]`), botones externos en puerto Pmod (`btn[4:5]`) y LEDs de la tarjeta Zybo Z7.

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
   * `btn[4] = 1` (Máscara Activa): Invierte bit a bit la clave ingresada (`btn[3:0]` \oplus 1111_2), lo que equivale a calcular su complemento a 1.
   ```verilog
   wire [3:0] operando_b = btn[4] ? (btn[3:0] ^ 4'b1111) : btn[3:0];
   ```






### 3.2 Entradas y construcción de operandos

|Entrada|Origen|Pin(es)|Función|
|-|-|-|-|
|`sw\[3:0]`|Switches SW3–SW0 de la tarjeta|T16, W13, P15, G15|Operando **A** (clave principal)|
|`btn\[3:0]`|Botones BTN3–BTN0 de la tarjeta|Y16, K19, P16, K18|Operando **B** (clave ingresada)|
|`btn\[4]`|Pulsador externo, Pmod JC|V15|Máscara XOR: invierte B (`B ^ 4'b1111`)|
|`btn\[5]`|Pulsador externo, Pmod JC|W14|Modo aritmético: 0 = resta (por defecto), 1 = suma|

```verilog
wire \[3:0] operando\_a = sw\[3:0];
wire \[3:0] operando\_b = btn\[4] ? (btn\[3:0] ^ 4'b1111) : btn\[3:0];
```

Así, A proviene únicamente de los switches y B de los botones (con o sin inversión), y las 10 entradas afectan el resultado.

### 3.3 ¿Por qué no se usaron BTN4 y BTN5 de la tarjeta?

La Zybo Z7 tiene seis pulsadores, pero **solo BTN0–BTN3 están conectados a la lógica programable (PL)**. BTN4 y BTN5 están conectados a pines **MIO** del procesador, por lo que un diseño en Verilog no puede leerlos directamente.

#### 3.3.1 Arquitectura del Zynq-7000: PS y PL

El Zynq-7000 integra dos partes en un mismo chip:

|Parte|Qué es|Cómo se programa|
|-|-|-|
|**PS** (*Processing System*)|Procesador ARM Cortex-A9 con sus periféricos (UART, USB, Ethernet, GPIO, controlador de memoria)|Software (C/C++ en Vitis)|
|**PL** (*Programmable Logic*)|Lógica programable equivalente a una FPGA Artix-7|HDL + `.xdc` en Vivado (lo que se hace en este laboratorio)|

Cada parte tiene sus **propios pines**:

* Los pines de la **PL** son de propósito general: cualquier puerto del módulo `top` se puede asignar a ellos con `PACKAGE\_PIN` en el `.xdc`. Es el caso de los switches, BTN0–BTN3, los LEDs y los Pmod JA–JE.
* Los pines **MIO** (*Multiplexed I/O*) pertenecen al **PS**. Están cableados internamente al multiplexor de periféricos del procesador y **no tienen conexión con la lógica programable**.

#### 3.3.2 Conexión de BTN4 y BTN5

|Botón|Pin MIO|Pin del encapsulado|Banco / voltaje|Lo lee|
|-|-|-|-|-|
|BTN0–BTN3|—|K18, P16, K19, Y16|Banco de la PL, 3.3 V|PL (HDL)|
|**BTN4**|**MIO 50**|B13|Banco 501 (PS), 1.8 V|Solo el PS|
|**BTN5**|**MIO 51**|B9|Banco 501 (PS), 1.8 V|Solo el PS|

Por eso, en el archivo `Zybo-Z7.xdc` de Digilent **no existen líneas para BTN4 y BTN5**: no son pines que Vivado pueda asignar a un puerto HDL. Si se intentara forzar `PACKAGE\_PIN B13` para un puerto del `top`, la implementación fallaría porque ese pin no es una E/S de la PL.

Lo mismo ocurre con el **Pmod JF** y con el **LED LD4**: también están conectados a pines MIO, y por eso los botones externos se conectaron al Pmod **JC**, que sí pertenece a la PL.


#### 3.3.4 Solución adoptada: pulsadores externos en el Pmod JC

Se conectaron dos pulsadores externos al Pmod JC, cada uno con una resistencia de **pull-down de 10 kΩ**. Es la misma configuración que usa la tarjeta para BTN4 y BTN5, pero alimentada a 3.3 V para coincidir con el estándar `LVCMOS33` de los pines de la PL.

```
 VCC3V3 (Pmod JC)
    │
   ─┴─  pulsador
    │
    ├──────────►  JC pin 1 (Señal)
    │
   ┌┴┐
   │ │ 10 kΩ  (pull-down)
   └┬┘
    │
   GND (Pmod JC)
```

* **Sin pulsar:** la resistencia lleva el pin a 0 V → `btn = 0`.
* **Pulsado:** el pin queda conectado a 3.3 V → `btn = 1`.

Así los botones externos son activos en alto, igual que BTN0–BTN3, y el HDL los trata de la misma forma.

Líneas agregadas al `.xdc`:

```tcl
## Pulsadores externos en Pmod JC
set\_property -dict { PACKAGE\_PIN V15 IOSTANDARD LVCMOS33 } \[get\_ports { btn\[4] }]; # JC pin 1
set\_property -dict { PACKAGE\_PIN W14 IOSTANDARD LVCMOS33 } \[get\_ports { btn\[5] }]; # JC pin 7
```

### 3.4 Operaciones implementadas

```verilog
// Aritmética de 4 bits: btn\[5] = 1 -> suma, btn\[5] = 0 -> resta
wire \[3:0] res\_aritmetico = btn\[5] ? (operando\_a + operando\_b) : (operando\_a - operando\_b);

// Lógicas
wire \[3:0] res\_and = operando\_a \& operando\_b;
wire \[3:0] res\_or  = operando\_a | operando\_b;
wire \[3:0] res\_xor = operando\_a ^ operando\_b;
```

|Operación|Dónde se usa|
|-|-|
|**Suma / resta** de 4 bits|`LED\[3:0]`|
|**AND**|Canal rojo del RGB|
|**OR**|Canal verde del RGB|
|**XOR**|Canal azul del RGB e inversión de B|

El resultado aritmético es de 4 bits **sin acarreo ni préstamo**: se muestra módulo 16. Por ejemplo, `10 - 12 = -2` se ve como `1110` (complemento a 2) y `12 + 5 = 17` se ve como `0001`.

**Comparación de claves:** dos números son iguales si y solo si su XOR es cero. Por eso, cuando A = B, el canal azul (`|res\_xor`) se apaga y la igualdad se detecta automáticamente, sin importar el modo aritmético seleccionado.

### 3.5 Salidas

|Salida|Pin|Significado|
|-|-|-|
|`led\[3:0]`|LD3–LD0|Resultado de A − B o A + B|
|`led\_rgb\[0]` (R)|V16|`\|(A \& B)`: A y B tienen al menos un bit en 1 en común|
|`led\_rgb\[1]` (G)|F17|`\|(A \| B)`: al menos uno de los operandos es distinto de cero|
|`led\_rgb\[2]` (B)|M17|`\|(A ^ B)`: A y B son distintos|

Como los tres canales dependen de A y B, **solo pueden aparecer cuatro colores**. Por ejemplo, si el AND tiene algún bit en 1, el OR también lo tiene, así que el rojo nunca aparece solo:

|Condición|AND|OR|XOR|Color|Combinaciones (de 256)|
|-|-|-|-|-|-|
|A = B = 0|0|0|0|Apagado|1|
|**A = B ≠ 0 (claves iguales)**|1|1|0|**Amarillo** (R + G)|15|
|A ≠ B, sin bits en común (p. ej. complementarias)|0|1|1|Cian (G + B)|80|
|A ≠ B, con algún bit en común|1|1|1|Blanco (R + G + B)|160|

El **amarillo** indica que las claves coinciden. El caso A = B = 0 también es una igualdad, pero se ve apagado porque AND y OR son cero.

### 3.6 Simulación


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



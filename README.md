## Laboratorio 01: FPGA (Zybo Z7), Vivado/Vitis y Validación de Hardware
- **Asignatura:** Electrónica Digital II  
- **Semestre:** 2026-2  

---

##  Integrantes del Equipo
- **Samuel Hincapie Perilla**
- **Eduardo Felipe Camacho Lara**
- **Gabriel Alberto Rodríguez Rincón**

---
## Contenido
- **Instalación y configuración del proyecto**
- **Smoke Test: semáforo en LED RGB**
- **Test Funcional Personalizado**
- **Conclusiones**

---
1. Instalación y configuración del proyecto
Se instalaron Vivado y Vitis 2025.2 mediante el AMD Unified Installer y se activó la licencia Vivado Basic Tier.
El proyecto se creó como RTL Project con los siguientes parámetros:
Parámetro	Valor
Parte	`xc7z010clg400-1L`
Fuentes	`semaforo.v` / `test\_funcional.v`
Constraints	`Zybo-Z7.xdc` (Digilent)
---
- *2. Smoke Test: semáforo en LED RGB*
- *2.1 Objetivo*
Verificar el flujo completo HDL → síntesis → implementación → bitstream → programación por JTAG, junto con el reloj de la tarjeta y el mapeo de pines del `.xdc`, usando el diseño subido en la guia del labratorio.
- *2.2 Funcionamiento del código*
El módulo `Semaforo` tiene una entrada de reloj `clk` y una salida `led\[2:0]` que controla los tres canales del LED RGB. Está compuesto por dos bloques síncronos:
Contador: incrementa `counter` en cada flanco de subida de `clk` y lo reinicia al llegar a 320 000 000.
Selector de color: cuando `counter` alcanza 0, 80e6, 160e6 y 240e6, cambia el valor de `led`. Entre esos instantes el registro conserva su valor, por lo que el color se mantiene.
Temporización (reloj de 125 MHz en el pin K17):
```
T\_clk    = 1 / f\_clk        = 1 / 125e6 Hz        = 8 ns
t\_estado = N\_estado \* T\_clk = 80e6 \* 8 ns          = 0.64 s
T\_ciclo  = N\_total  \* T\_clk = 320e6 \* 8 ns         = 2.56 s
```
`counter`	Estado	`led = {G,B,R}`	Canales encendidos
0	Rojo	`3'b001`	R
80 000 000	Amarillo	`3'b101`	R + G
160 000 000	Verde	`3'b100`	G
240 000 000	Amarillo	`3'b101`	R + G
3.3 Mapeo de pines (`.xdc`)
Solo se habilitaron las líneas del reloj y del LED RGB LD6; que eran las unicas necesarias para esta implementación
```tcl
## Reloj 125 MHz
set\_property -dict { PACKAGE\_PIN K17 IOSTANDARD LVCMOS33 } \[get\_ports { clk }];
create\_clock -add -name sys\_clk\_pin -period 8.00 -waveform {0 4} \[get\_ports { clk }];

## LED RGB LD6
set\_property -dict { PACKAGE\_PIN V16 IOSTANDARD LVCMOS33 } \[get\_ports { led\[0] }]; # led6\_r
set\_property -dict { PACKAGE\_PIN M17 IOSTANDARD LVCMOS33 } \[get\_ports { led\[1] }]; # led6\_b
set\_property -dict { PACKAGE\_PIN F17 IOSTANDARD LVCMOS33 } \[get\_ports { led\[2] }]; # led6\_g
```
Señal HDL	Pin	Canal
`clk`	K17	Reloj del sistema (125 MHz)
`led\[0]`	V16	Rojo
`led\[1]`	M17	Azul
`led\[2]`	F17	Verde
`create\_clock` informa a la herramienta que el reloj tiene un periodo de 8 ns, que es el valor que usa el análisis de tiempos durante la implementación.
- *2.4 Evidencia de la correcta implementación*
https://github.com/user-attachments/assets/e99ffdbc-6585-4a58-9e17-00986aa4bfc6

En la prueba se programó el código base. Se observó la secuencia cíclica rojo → azul → verde → azul, con una duración aproximada de 0.64 s por estado, lo que confirma:
Que la FPGA se programa correctamente por JTAG.
Que el reloj de 125 MHz está presente y el `create\_clock` es coherente con la temporización observada.
Que los tres canales del LED RGB responden y están asignados a pines válidos en el `.xdc`.
La aparición del color azul en lugar del amarillo se explica en la sección siguiente.
- *2.6 Observaciones sobre el código base*

1	El amarillo se codificaba como `3'b010`	Según el `.xdc`, `led\[1]` corresponde al canal azul (M17), por lo que el estado "amarillo" se vio azul	Se cambió a `3'b101` (R + G) en `src/semaforo.v`
El LED RGB no tiene un canal amarillo propio: el amarillo se obtiene encendiendo simultáneamente los canales rojo y verde. Con el mapeo del `.xdc` (`led = {G, B, R}`), eso corresponde a `3'b101`.
> \*\*Nota:\*\* la corrección de colores se identificó al analizar el video. La versión corregida incluida en `src/semaforo.v` no quedó registrada en el video de la prueba.
---
- *3. Test Funcional Propuesta propia*
- *3.1 Descripción del diseño*



- *3.2 Entradas y construcción de operandos*
Entrada	Origen	Uso
`SW\[3:0]`	Switches de la tarjeta	[T16, W13, P15, G15] Construyen un número de 4 bits
`BTN\[3:0]`	Botones de la tarjeta	[Y16, K19, P16, K18] Construyen un número de 4 bits
`BTN\[4]`	Botón externo (Pmod [JC], pin [V15]) Se encarga de decidir que operación se realizará
`BTN\[5]`	Botón externo (Pmod [JC], pin [W14]) Cuado se acciona invierte el número generado por el arreglo de botones de la tarjeta
Botones externos: en la Zybo Z7, BTN4 y BTN5 están conectados a pines MIO del procesador (PS) y no son accesibles directamente desde la lógica programable. Por esta razón se agregaron dos pulsadores externos con resistencia de pull-down de [10k] Ω conectados al puerto Pmod JD

- *3.3 Operaciones implementadas* 
- *Suma*
- *Resta*
- *Compara* si los números ingresados son iguales.
La operación a realizar se realiza mediante el uso de uno de lo botones, la resta es la operación por defecto. Si los número son iguales se detecta de forma automática.
- *3.4 Salidas* 
Salida	- Significado
`LED\[3:0]`	[ ] Enseña el resultado de la operación
`LED\_RGB` Amarillo	[ ] Identifica si los dos numeros son iguales. 
`LED\_RGB` Blanco	[ ]  Identifica si se realiza una resta.
`LED\_RGB` Rojo	[ ]
- *3.5 Evidencia*
Debido al peso de los videos grabados mostranso el funcionamiento, se decidio subirlos a youtube, a continuación se encuentran los respectivos link
- *Suma*
https://www.youtube.com/post/UgkxqJWBuRDRpbTTP529ywnDsrrxRszGwlTm
- *Resta*
http://youtube.com/post/UgkxCSxVErJU7BjNxqNJ24GnIfKiw0TfXPmx?si=q7t2bkdnnUVDWNZM
- *Inversión*
http://youtube.com/post/UgkxSmo_cgUaAY2VPtY3IEqNEs5w1QeJdv0Z?si=hmwzP5bkY0CaG0Qi
- *Comparación*
http://youtube.com/post/Ugkx4-mQdEe4J9XcFDsBRo5mgFXRNFOoItOl?si=AX0MZMJWkvbgoTGe
---
- *4. Conclusiones*

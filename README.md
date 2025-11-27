# Proyecto corto III: División de enteros

## 1. Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays

## 2. Referencias
[0] David Harris y Sarah Harris. *Digital Design and Computer Architecture. RISC-V Edition.* Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3

[1] David Medina. Video tutorial para principiantes. Flujo abierto para TangNano 9k. Jul. de 2024. url: https://www.youtube.com/watch?v=AKO-SaOM7BA.

[2] David Medina. Wiki tutorial sobre el uso de la TangNano 9k y el flujo abierto de herramientas. Mayo de 2024. url: https://github.com/DJosueMM/open_source_fpga_environment/wiki

[4] razavi b. (2013) fundamentals of microelectronics. segunda edición. john wiley & sons

## 3. Descripción general del funcionamiento del circuito

### 3.1 Descripción general

El sistema implementado corresponde a un divisor binario digital, capaz de recibir dos operandos de hasta 7 bits cada uno, realizar la división mediante el algoritmo de división binaria restaurada (restoring division) y desplegar tanto el cociente como el residuo en formato BCD utilizando cuatro displays de 7 segmentos multiplexados.

El usuario ingresa los operandos mediante un teclado hexadecimal 4×4, el cual es leído por un módulo de escaneo y debouncing que garantiza la captura estable del valor presionado. El sistema almacena primero el dividendo y luego el divisor, cada uno compuesto por dos cifras hexadecimales, equivalentes a un número de 7 bits. Una vez que ambos valores han sido ingresados y validados, el módulo divisor realiza el proceso secuencial para calcular:

el cociente Q

el residuo R

Finalmente, los resultados se envían al sistema de conversión binario-a-BCD y luego al multiplexor de displays, el cual refresca los 4 dígitos a suficiente frecuencia para aparentar iluminación continua.
Con esto se obtiene una implementación funcional totalmente compatible con la FPGA Gowin Tang Nano 9K

### 3.2 Descripción de cada subsistema 

1. Módulo de lectura del teclado (Keypad Reader + Debouncer)

Este bloque se encarga de:

generar el patrón de escaneo por filas del teclado 4×4,

leer el estado de las columnas,

identificar cuál tecla fue presionada,

filtrar rebotes mecánicos mediante un debouncer basado en contador.

El módulo asegura que solo un valor limpio y estable se entregue al sistema superior.
Cada tecla genera un código hexadecimal entre 0 y F, el cual se envía junto con un pulso key_valid.

2. Módulo de captura de operandos

Recibe las teclas válidas provenientes del lector y las organiza en:

Primer operando (dividendo) – dos dígitos hex (MSB y LSB)

Segundo operando (divisor) – dos dígitos hex

El módulo cuenta con una pequeña máquina de estados:

WAIT_A_MSB

WAIT_A_LSB

WAIT_B_MSB

WAIT_B_LSB

READY

Una vez que los cuatro dígitos han sido ingresados en orden, se activa la señal operands_ready.
El módulo también convierte cada dígito hexadecimal en su representación binaria (7 bits máximo).

3. Módulo divisor binario (Restoring Divider)

Implementa el algoritmo clásico de división restaurada, usando registros y lógica secuencial:

Registro Q: contiene el dividendo y acumula el cociente.

Registro A: acumulador donde se realizan las restas parciales.

Comparador y restador: permiten determinar si el divisor cabe en el acumulador.

Control secuencial mediante un contador de iteraciones.

4. Convertidor binario–a–BCD
   
El divisor produce resultados binarios (hasta 7 bits para el cociente y residuo).
Para poder desplegarlos en los displays, es necesario convertirlos a BCD.

Se carga el número binario en un registro ampliado, luego se desplaza bit a bit hacia la izquierda y antes de cada desplazamiento, si algún dígito BCD ≥ 5, se le suman 3. El módulo produce:

bcd3, bcd2, bcd1, bcd0

conv_done

5. Multiplexor de displays de 7 segmentos (Display Mux)

Realiza:
Selección temporal del dígito activo (anodos).
Conversión de cada dígito BCD en su patrón de segmentos (a–g).
Refresco a frecuencia suficientemente alta (> 1 kHz).
Este módulo funciona de manera continua, independientemente de la división.

6. Módulo top (Integración general)

Este bloque interconecta todos los anteriores.
Su función es coordinar:
entrada desde el teclado,
carga y validación de operandos,
inicio del módulo divisor,
conversión binaria a BCD,
despliegue en los displays.
El módulo top es completamente sincronizado por el reloj del sistema (27 MHz) y gestiona las señales de control (start, ready, done) de cada subsistema.

### 3.3 Diagramas de bloques 

### 3.4 Diagramas de estado 

## 4. Simulación funcional del sistema completo

## 5. Análisis de consumo de recursos

## 6. Reporte de velocidades

## 7, Análisis de principales problemas hallados durante el trabajo 

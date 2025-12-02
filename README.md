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
Con esto se obtiene una implementación funcional totalmente compatible con la FPGA Gowin Tang Nano 9K.

### 3.2 Descripción de cada subsistema 

#### 1. Subsistema de Lectura de Datos

Este subsistema permite ingresar el dividendo A y el divisor B desde un teclado matricial de 16 teclas. Se encarga de: Sincronizar las señales mecánicas del teclado, eliminar rebotes mediante un módulo debounce, escanear columnas del teclado para detectar teclas, setectar flanco de presión (key_down) y administrar el proceso de ingreso mediante una máquina de estados finita (FSM).

Debounce:

El módulo debounce toma cada fila del teclado y: Sincroniza la señal mediante doble muestreo (SAMPLE1, SAMPLE2). detecta si la señal ha cambiado, utiliza un contador saturable que debe estabilizarse durante 2ⁿ ciclos para considerar válida la tecla. genera la señal estable key_pressed.

Resultado: cada tecla es vista como una señal limpia y estable.

Teclado:
Este módulo implementa un escaneo de columnas:

Cada cierto número de ciclos activa una columna distinta. Lee las filas para determinar cuál tecla se presionó. Convierte la combinación fila/columna en un valor hexadecimal de 4 bits.

#### 2. Subsistema de Cálculo de División Entera

Este subsistema convierte primero los valores en BCD a binario (0–15) mediante el módulo; bcd_binario, convierte {decenas, unidades} en un valor de 4 bits (0–15), luego entra al divisor secuencial:

Divisor secuencial (operacion.sv)

Implementa el algoritmo iterativo de división de enteros:

Desplazar residuo, insertar bits del dividendo, realizar resta, decidir entre aceptar la resta o conservar residuo, Formar gradualmente el cociente. Este divisor opera en 4 iteraciones, una por bit del dividendo, el módulo usa:

Registros r_reg (resto) y q_reg (cociente)

Un contador para avanzar por los bits y una pequeña máquina de control implícita (derivada del pseudocódigo).

Latch de resultados

El diseño incluye:

op_cnt → contador para darle tiempo al divisor

Q_LATCH y R_LATCH → registros donde se congela el resultado una vez estable

op_latched → señal que indica que el divisor terminó

De esta manera, los resultados no siguen cambiando mientras se actualiza el display.

El subsistema entrega:

Q_LATCH → cociente (4 bits)

R_LATCH → residuo (4 bits)


#### 3. Subsistema de Conversión a BCD

Aunque la especificación original pide convertir binario → BCD, en este proyecto los resultados del divisor ya corresponden a números pequeños (0–15), por lo cual basta con enviarlos directamente al display en formato hexadecimal.
Si se requiriera la conversión completa, el módulo bcd_binario o un conversor tipo Double Dabble se podrían utilizar. Este subsistema permite que los datos enviados al display sean los adecuado.

#### 4. Subsistema de Despliegue en Display de 7 Segmentos
   
Este bloque toma el valor a mostrar y lo distribuye entre los cuatro dígitos disponibles.

4.1 Multiplexado

El módulo realiza; división de frecuencia para obtener ~1 kHz por dígito, alterna entre 4 ánodos (anodo_selec), registro intermedio para evitar glitches.

4.2 Decodificación HEX → 7 segmentos

El módulo display_bin_hex convierte un nibble de 4 bits en su representación en 7 segmentos (activo en bajo).

4.3 Datos mostrados según el estado

El top.sv define qué mostrar; en INPUT_A → A1, A0, en INPUT_B → B1, B0, en OPERACION → a_bin, Q_LATCH, b_bin, R_LATCH. Así el usuario puede ver lo que ingresa y luego los resultados.

### 3.3 Diagramas de bloques 

### 3.4 Diagramas de estado 

## 4. Simulación funcional del sistema completo

Para validar el funcionamiento lógico del sistema sumador BCD implementado en FPGA, se desarrolló un testbench en SystemVerilog que permite simular el comportamiento completo del circuito antes de su síntesis física.

Resultado al ejecutar makeTest

![WhatsApp Image 2025-12-02 at 3 06 13 PM](https://github.com/user-attachments/assets/b1b622e0-4423-4ef7-aeb6-b1bd80676e5b)

Resultado al ejecutar make WV

![WhatsApp Image 2025-12-02 at 3 06 26 PM](https://github.com/user-attachments/assets/c459da84-3561-432a-9617-644f82966f82)


## 5. Análisis de consumo de recursos

## 6. Reporte de velocidades

## 7 Análisis de principales problemas hallados durante el trabajo 

## Bitacoras 

### Bitacora  Ismael Isaac Flores Mercado




### Bitacora Juan Esteban Obando Perez

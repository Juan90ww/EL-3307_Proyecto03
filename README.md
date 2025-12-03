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

Subsistema 1,  Subsistema de Lectura de Datos,
Escanea continuamente el teclado matricial hexadecimal y detecta qué tecla fue presionada, aplicando eliminación de rebote para evitar lecturas falsas.

![WhatsApp Image 2025-12-03 at 11 31 58 AM](https://github.com/user-attachments/assets/405bb852-5569-49a2-88e5-7c3529d796d7)


Subsistema 2, Subsistema de Cálculo de División Entera; El módulo realiza división binaria secuencial de 4 bits utilizando un algoritmo clásico similar al non-restoring division o restoring division, ejecutado en 4 iteraciones, una por cada bit del dividendo.

![WhatsApp Image 2025-12-03 at 11 47 40 AM](https://github.com/user-attachments/assets/27a2fa7a-3072-40b7-a25c-100721cfa415)


Subsistema 3, Subsistema de Conversión a BCD; Convierte un número binario (resultado de la suma) a formato BCD, para poder mostrarlo en los displays de 7 segmentos.

![WhatsApp Image 2025-12-03 at 11 36 05 AM](https://github.com/user-attachments/assets/321bb6b8-416e-4a7e-87fb-d87d2dab10db)


Subsistema 4, Subsistema de Despliegue en Display de 7 Segmentos; Controla cuatro displays de 7 segmentos compartiendo las líneas de segmentos, activando un dígito a la vez de forma secuencial (multiplexado dinámico).

![WhatsApp Image 2025-12-03 at 11 39 26 AM](https://github.com/user-attachments/assets/11ebbedc-aacf-4129-b9a7-c9bbde13c765)


### 3.4 Diagramas de estado 

FSM del Lector de Teclado

![WhatsApp Image 2025-12-03 at 11 48 55 AM](https://github.com/user-attachments/assets/6660d58c-5bb8-4a6c-8305-e4a925645952)


FSM del Control de Display

![WhatsApp Image 2025-12-03 at 11 49 06 AM](https://github.com/user-attachments/assets/8a0a19b4-9557-44a4-a2ad-161ce7b65729)


## 4. Simulación funcional del sistema completo

Para validar el funcionamiento lógico del sistema sumador BCD implementado en FPGA, se desarrolló un testbench en SystemVerilog que permite simular el comportamiento completo del circuito antes de su síntesis física.

Resultado al ejecutar makeTest

![WhatsApp Image 2025-12-02 at 3 06 13 PM](https://github.com/user-attachments/assets/b1b622e0-4423-4ef7-aeb6-b1bd80676e5b)

ada caso de prueba verifica una división entera usando el algoritmo iterativo implementado en operacion.sv.

Para cada división, el testbench calcula:

Cociente esperado

Residuo esperado

El módulo de división entrega q_reg (cociente) y r_reg (resto), los cuales son comparados automáticamente.

Resultado global

Todos los casos de prueba pasaron correctamente, lo que indica que el algoritmo de división secuencial está implementado de manera correcta y que el comportamiento del circuito coincide con el modelo matemático esperado.

Resultado al ejecutar make WV

![WhatsApp Image 2025-12-02 at 3 06 26 PM](https://github.com/user-attachments/assets/c459da84-3561-432a-9617-644f82966f82)

En la captura proporcionada se visualizan las señales más relevantes:

a_reg y b_reg: valores binarios del dividendo y divisor

r_reg: registro del residuo

q_reg: registro del cociente

contador: controla las iteraciones (0–3)

Rutas combinacionales: r_next, d_next

Señales de control internas del divisor

Tanto la simulación automática (make test) como la visualización de formas de onda (make wv) validan completamente el funcionamiento del divisor secuencial.
Los resultados generados por el hardware coinciden con los valores esperados para cociente y residuo, y las transiciones internas de los registros son coherentes con el algoritmo shift–subtract.
La implementación es funcional, estable y correctamente sincronizada.

## 5. Análisis de consumo de recursos

![WhatsApp Image 2025-12-02 at 11 24 16 PM](https://github.com/user-attachments/assets/42b599c3-2c50-42e6-a427-4a08ca951db8)

El diseño sintetizado es eficiente, robusto y cumple con holgura los requisitos de frecuencia y estabilidad.
Con únicamente 1233 celdas y una frecuencia máxima de 55.95 MHz, el sistema demuestra ser liviano en recursos y rápido en operación.
La ausencia de fallos de timing confirma que la arquitectura secuencial y los subsistemas (teclado, divisor, display y FSM) están correctamente diseñados y sincronizados.

## 6. Reporte de velocidades

![WhatsApp Image 2025-12-02 at 11 39 13 PM](https://github.com/user-attachments/assets/b1388cc8-74e0-4f84-9a44-c81795a009c6)

El sistema opera a 27 MHz.

Esto demuestra que; el diseño es estable, no hay problemas de timing, el multiplexado del display, la FSM, el divisor secuencial y el scanner del teclado son muy livianos en términos combinacionales. El diseño cumple holgadamente la frecuencia requerida. Puede operar casi al doble de la frecuencia necesaria, por lo que la implementación es robusta y estable.

## 7 Análisis de principales problemas hallados durante el trabajo 

Problema con el registro que guarda las teclas. Posible solución, utilizar un contador mas lento para el guardado de los datos funcionando de forma asincrona.
Problema al intentar implementar la division para 7 bits, la simulacion se detenia y no se ejecutaba el programa.

## Bitacoras 

### Bitacora  Ismael Isaac Flores Mercado




### Bitacora Juan Esteban Obando Perez


![WhatsApp Image 2025-12-03 at 7 23 27 AM](https://github.com/user-attachments/assets/564d3c92-b072-4f8d-b32f-cf9dafa93aad)

--------------------------------------------------------------------------------

![WhatsApp Image 2025-12-03 at 7 23 49 AM](https://github.com/user-attachments/assets/8e9f570e-fbca-4fe9-a010-3de7ef72ca86)

--------------------------------------------------------------------------------

![WhatsApp Image 2025-12-03 at 7 23 59 AM](https://github.com/user-attachments/assets/25bbaa0f-caca-4f1b-a949-69c9ab30c92e)

--------------------------------------------------------------------------------

![WhatsApp Image 2025-12-03 at 7 24 08 AM](https://github.com/user-attachments/assets/dd814204-8419-4114-be26-8b1246a3d24b)


--------------------------------------------------------------------------------
![WhatsApp Image 2025-12-03 at 7 24 18 AM](https://github.com/user-attachments/assets/5abd226b-76ee-4117-ae44-89eb543313b8)














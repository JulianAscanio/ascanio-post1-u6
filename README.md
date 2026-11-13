**Laboratorio Práctico: Instrucciones y Modos de Direccionamiento en x86 — Programación en NASM sobre DOSBox**  
**Asignatura:** Arquitectura de Computadores  
   
 **Unidad 6:** Post-contenido (Laboratorio)  
   
 **Estudiante:** Julián Andrés Ascanio  
 [  
 **Repositorio Oficial:** `ascanio-post1-u6`  
   
 **Herramientas:** DOSBox 0.74-3, Netwide Assembler (NASM v2.14+ / nasm.exe DOS), Depurador DEBUG.COM / DEBUG.EXE]
  
---  
**1. Contexto y Objetivos del Laboratorio**  
El presente laboratorio guiado aborda de manera práctica y verificable dos pilares esenciales de la arquitectura del repertorio de instrucciones (ISA) del procesador Intel x86 en modo real de 16 bits: el conjunto representativo de instrucciones de cómputo y control, y los mecanismos de cálculo de direcciones efectivas en memoria mediante diversos modos de direccionamiento.  
1. **Parte 1 (Categorías Fundamentales de Instrucciones x86):** Se implementa y verifica en `src/lab6_instrucciones.asm` la secuencia de operaciones que abarca la transferencia de datos (`MOV`, `LEA`, `XCHG`, `PUSH`/`POP`), la aritmética entera con análisis detallado de flags (`ADD`, `SUB`, `INC`, `DEC`, `MUL`, `DIV`), la manipulación lógica de bits (`AND`, `OR`, `XOR`, `TEST`, `SHL`, `SHR`), el control de flujo condicional e iterativo (`CMP`, `JG`, `JE`, `LOOP`, `DEC`/`JNZ`) y un bloque comparativo dedicado a contrastar el desplazamiento de bits frente a las rotaciones circulares (`SHL`/`SHR` frente a `ROL`/`ROR`), demostrando el descarte o preservación del bit saliente y su aplicación al intercambio de nibbles. Adicionalmente, se desarrolla en `src/lab6_factorial.asm` la variante del bucle iterativo para calcular el factorial de 5 (5! = 120).  
2. **Parte 2 (Demostración Rigurosa de Modos de Direccionamiento):** Se desarrolla en `src/lab6_modos.asm` un conjunto estructurado de accesos a memoria que aísla los cuatro modos fundamentales de direccionamiento: inmediato, directo, indirecto por registro e indexado (base + índice + desplazamiento). Este diseño se extiende mediante la construcción de un marco de variables locales en la pila gobernado por el registro puntero base (`BP`) y la dereferenciación de una matriz bidimensional de 3 \times 3 elementos de 16 bits mediante cálculo algebraico de doble indexación (fila y columna).  
  
---  
**2. Estructura del Repositorio**  
El repositorio conserva una jerarquía limpia, modular y reproducible:  
```  
ascanio-post1-u6/  
 ├── README.md                      # Informe técnico completo, tablas de traza y decisiones justificadas  
 ├── dosbox.conf                    # Configuración optimizada de emulación de ciclos y montura DOSBox 
 ├── .gitignore                     # Filtro de herramientas binarias DOS y temporales  
 ├── src/                           # Código fuente en lenguaje ensamblador NASM (16 bits)  
 │   ├── lab6_instrucciones.asm     # Programa principal de la Parte 1 (5 bloques de instrucciones)  
 │   ├── lab6_factorial.asm         # Variante del bucle iterativo (Cálculo de 5! = 120)  
 │   └── lab6_modos.asm             # Programa principal de la Parte 2 (Modos de direccionamiento)  
 ├── bin/                           # Binarios planos ejecutables en formato .COM (Modo Real 16 bits)  
 │   ├── lab6_instrucciones.com     # Ejecutable generado de la Parte 1  
 │   ├── lab6_factorial.com         # Ejecutable generado del factorial  
 │   └── lab6_modos.com             # Ejecutable generado de la Parte 2  
 └── capturas/                      # Evidencias auténticas capturadas en DOSBox/DEBUG  
     ├── CP1_compilacion_parte1.png  
     ├── CP2_trazado_flags_parte1.png  
     ├── CP3_bucle_loop_parte1.png  
     ├── CP4_rotacion_bloque5_parte1.png  
     ├── CP5_factorial_parte1.png  
     ├── CP6_dump_estructura_parte2.png  
     ├── CP7_trazado_indirecto_parte2.png  
     ├── CP8_modo_indexado_parte2.png  
     ├── CP9_marco_pila_bp_parte2.png  
     ├── CP10_matriz_2d_parte2.png  
     └── CP11_decisiones_tecnicas.png  
   
```  
  
---  
**3. Parte 1: Programa de Instrucciones Mixtas en NASM**  
**3.1 Descripción Técnica de los Bloques de Instrucciones**  
- **Bloque 1 (Transferencia de Datos):** Carga los operandos escalares `valor_a` (45 = `002Dh`) y `valor_b` (12 = `000Ch`) hacia los registros `AX` y `BX`. Demuestra la transferencia inter-registro con `MOV cx, ax` y `MOV dx, bx`. Contrasta la lectura del contenido de memoria contra la obtención de su dirección efectiva mediante `LEA si, [valor_a]`, accediendo luego al valor de manera indirecta vía `MOV ax, [si]`. Demuestra el intercambio atómico de registros mediante `XCHG cx, dx` y la preservación temporal de contexto con `PUSH ax` y `POP ax`.  
- **Bloque 2 (Operaciones Aritméticas):** Ejecuta `ADD ax, [valor_b]` resultando en 45 + 12 = 57 (`0039h`), con flags en estado neutro (`CF=0, ZF=0, SF=0, OF=0`). Posteriormente evalúa la sustracción `SUB ax, [valor_a]` sobre `valor_b`, calculando 12 - 45 = -33 (`FFDFh` en complemento a dos de 16 bits), activando el flag de signo `SF=1` y el flag de acarreo/préstamo `CF=1` (`CY`). Se verifica que `INC` y `DEC` incrementan y decrementan unitariamente sin alterar `CF`. Se realiza la multiplicación sin signo `MUL bl` (10 \times 7 = 70 = \text{0046h}) almacenada en `AX`, y la división entera `DIV bl` (100 / 7), generando en `AL` el cociente 14 (`0Eh`) y en `AH` el residuo 2 (`02h`).  
- **Bloque 3 (Operaciones Lógicas y Desplazamientos):** Aplica enmascaramiento selectivo `AND al, [mascara]` sobre `0B7h` (`1011 0111b`) con `0Fh` (`0000 1111b`), aislando los cuatro bits bajos (`07h`). Ejecuta `OR al, 0F0h` para activar los cuatro bits superiores resultando en `F7h`. Aplica `XOR al, 0FFh` para invertir la totalidad de los bits de `0AAh` resultando en `55h`. Demuestra la optimización `XOR bx, bx` para limpiar registros en 2 bytes sin generar tráfico de bus. Verifica con `TEST al, 01h` la imparidad del dato sin destruirlo. Finalmente, ejecuta `SHL al, 2` (8 \times 2^2 = 32 = \text{20h}) y `SHR al, 1` (32 / 2 = 16 = \text{10h}).  
- **Bloque 4 (Control de Flujo):** Compara `valor_a` frente a `valor_b` mediante `CMP ax, [valor_b]`. Al ser 45 > 12, la resta interna produce un resultado positivo (33), evaluado por `JG .mayor` para establecer el indicador de control en 1. A continuación, implementa una suma acumulada de 1 a 5 mediante la instrucción `LOOP .bucle_suma` gobernada por el registro `CX`, totalizando 1+2+3+4+5 = 15 (`000Fh`), y demuestra su contraparte funcionalmente equivalente con la secuencia explícita `DEC cx` y `JNZ .bucle_dec`.  
- **Bloque 5 (Desplazamientos frente a Rotaciones y Nibble Swap):** Aplica desplazamientos y rotaciones sobre el valor `81h` (`1000 0001b`):  
  - `SHL bl, 1`: Expulsa el bit 7 (1) hacia el flag `CF=1`, ingresando un 0 por el bit 0. El registro queda en `02h` perdiendo el bit saliente.  
  - `ROL cl, 1`: Expulsa el bit 7 (1) hacia el flag `CF=1`, pero lo reinserta simultáneamente por el bit 0. El registro queda en `03h`, preservando íntegra la información.  
  - `SHR dl, 1`: Expulsa el bit 0 (1) hacia `CF=1`, ingresando un 0 por el bit 7. El registro queda en `40h`.  
  - `ROR bh, 1`: Expulsa el bit 0 (1) hacia `CF=1` y lo reinserta en el bit 7. El registro queda en `C0h`.  
  - `ROL al, 4` sobre `0A5h` (`1010 0101b`): Intercambia los dos nibbles, produciendo de manera exacta `5Ah` (`0101 1010b`).  
  
---  
**3.2 Tabla de Transiciones de Registros y Flags en DEBUG**  
  
|  |  |  |  |  |  
| - | - | - | - | - |  
| **Instrucción Analizada** |  **Operandos / Acción** |  **Registros Clave Resultantes** |  **Flags en DEBUG (16-bit FLAGS)** |  **Interpretación Arquitectónica** |  
| `MOV ax, [valor_a]` |  Memoria a registro |  `AX=002Dh` (45 dec) |  Inalterados |  Transferencia directa desde espacio de datos en `DS`. |  
| `ADD ax, [valor_b]` |  Suma 45 + 12 |  `AX=0039h` (57 dec) |  `NV UP EI PL NZ NA PO NC` |  `CF=0` (sin acarreo), `ZF=0` (no cero), `SF=0` (positivo), `OF=0`. |  
| `SUB ax, [valor_a]` |  Resta 12 - 45 |  `AX=FFDFh` (-33 dec) |  `NV UP EI NG NZ AC PO CY` |  `CF=1` (`CY`: préstamo requerido), `SF=1` (`NG`: negativo), `ZF=0`. |  
| `INC ax / DEC ax` |  Inc/Dec unitario |  `AX=002Dh` (45 dec) |  `NV UP EI PL NZ NA PO NC` |  Modifican `ZF, SF, OF, PF`, pero preservan intacto `CF`. |  
| `MUL bl` |  10 \times 7 sin signo |  `AX=0046h` (70 dec), `DX=0` |  `NV UP EI PL NZ NA PO NC` |  `CF=0, OF=0` dado que la mitad alta `AH` es estrictamente cero. |  
| `DIV bl` |  100 / 7 sin signo |  `AX=020Eh` (`AL=14, AH=2`) |  Indefinidos por ISA |  Cociente entero en `AL` y residuo en `AH`. No altera flags estándar. |  
| `AND al, [mascara]` |  `B7h AND 0Fh` |  `AL=07h` |  `NV UP EI PL NZ NA PE NC` |  Borra bits 7..4. `CF=0, OF=0, ZF=0`. `PE` indica paridad par. |  
| `OR al, 0F0h` |  `B7h OR F0h` |  `AL=F7h` |  `NV UP EI NG NZ NA PE NC` |  Enciende bits 7..4. `SF=1, CF=0, OF=0`. |  
| `XOR al, 0FFh` |  `AAh XOR FFh` |  `AL=55h` |  `NV UP EI PL NZ NA PE NC` |  Inversión bit a bit completa (equivalente a `NOT`). |  
| `TEST al, 01h` |  `B7h AND 01h` |  `AL=B7h` (preservado) |  `NV UP EI PL NZ NA PO NC` |  Bit 0 es 1 (impar). `ZF=0`. Registro destino no sufre alteración. |  
| `CMP ax, [valor_b]` |  45 - 12 = 33 |  `AX=002Dh`, `BX=000Ch` |  `NV UP EI PL NZ NA PO NC` |  `ZF=0, CF=0, SF=0`. `JG` bifurca exitosamente hacia `.mayor`. |  
| `LOOP .bucle_suma` |  Fin del bucle 1..5 |  `AX=000Fh` (15 dec), `CX=0` |  `NV UP EI PL NZ NA PO NC` |  Acumulador `AX` suma 1+2+3+4+5. `CX` decae hasta cero. |  
| `SHL bl, 1` |  `81h << 1` |  `BL=02h` |  `OV UP EI PL NZ NA PO CY` |  Bit 7 original expulsado a `CF=1` (`CY`). Se llena con cero. |  
| `ROL cl, 1` |  `81h ROL 1` |  `CL=03h` |  `OV UP EI PL NZ NA PO CY` |  Bit 7 viaja a `CF=1` y reingresa en bit 0 (10000001b \to 00000011b). |  
| `SHR dl, 1` |  `81h >> 1` |  `DL=40h` |  `OV UP EI PL NZ NA PO CY` |  Bit 0 original expulsado a `CF=1`. Bit 7 ingresa como cero. |  
| `ROR bh, 1` |  `81h ROR 1` |  `BH=C0h` |  `OV UP EI PL NZ NA PO CY` |  Bit 0 viaja a `CF=1` y reingresa en bit 7 (10000001b \to 11000000b). |  
| `ROL al, 4` |  `A5h ROL 4` |  `AL=5Ah` |  `OV UP EI PL NZ NA PE NC` |  Intercambio perfecto de nibbles (1010\\,0101b \to 0101\\,1010b). |  
  
   
  
---  
**3.3 Variante del Bucle: Cálculo del Factorial de 5 (**`lab6_factorial.asm`**)**  
Para dar cumplimiento al Checkpoint 3, se adaptó la estructura del bucle iterativo reemplazando la adición acumulada por la multiplicación sucesiva sin signo:  
- Se inicializa el acumulador neutro en `AX = 1`, el registro multiplicador en `BX = 1` y el contador en `CX = 5`.  
- En cada paso, la instrucción `MUL bx` multiplica `AX` por `BX`. El incremento `INC bx` prepara el siguiente factor y `LOOP .bucle_factorial` decrementa `CX`, bifurcando mientras `CX != 0`.  
- Al agotar las 5 iteraciones (1 \times 1 \times 2 \times 3 \times 4 \times 5), el acumulador almacena de forma exacta 120 decimal (`0078h`), respaldado en la variable `resultado_fact` e inspeccionado mediante `DEBUG`.  
  
---  
**3.4 Evidencias Gráficas de la Parte 1**  
***Checkpoint 1: Compilación Exitosa con NASM en DOSBox***  
Verificación de la versión del compilador `NASM` dentro del entorno emulado y generación sin advertencias ni errores de los ejecutables `.COM`.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 2: Trazado de Instrucciones Aritméticas, Lógicas y Verificación de Flags***  
Inspección en modo traza (`T`) con `DEBUG` constatando `AX=0039h` (57 dec) tras `ADD`, `AX=FFDFh` (-33 dec) con `SF=1/CF=1` tras `SUB`, y transiciones lógicas de `AND`, `TEST` y `CMP`.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 3: Verificación del Bucle LOOP (Suma Acumulada AX=15)***  
Ejecución del bucle mediante comando `G 22E` evidenciando `AX=000Fh` (15 decimal) y `CX=0000h` tras la suma de 1 a 5.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 4: Trazado del Bloque 5 de Rotación (ROL/ROR vs SHL/SHR y Nibble Swap)***  
Constatación de `CF=1` en los cuatro desplazamientos/rotaciones, valores `BL=02h`, `CL=03h`, `DL=40h`, `BH=C0h`, y resultado final de `AL=5Ah` tras la rotación de 4 bits sobre `0A5h`.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 5: Ejecución y Trazado de la Variante Factorial de 5 (AX=120)***  
Verificación del cálculo de 5! = 120 (`0078h`) en `lab6_factorial.com` tanto en consola DOS como en los registros de `DEBUG`.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
  
---  
**4. Decisiones Técnicas de la Parte 1**  
**Decisión Técnica 1: Criterios de Selección entre Desplazamiento (SHL/SHR) y Rotación (ROL/ROR)**  
***Justificación Arquitectónica:***  
   
 *En la arquitectura x86, la selección entre instrucciones de desplazamiento (`SHL`/`SHR`) y rotación (`ROL`/`ROR`) está estrictamente dictada por la semántica requerida para los bits que abandonan los límites físicos del registro. Las operaciones de desplazamiento lógico son las herramientas idóneas para la aritmética entera sin signo cuando se requiere multiplicar o dividir magnitudes por potencias de dos (2^k). En este contexto aritmético, los bits expulsados fuera de la palabra representan órdenes de magnitud que desbordan la precisión del contenedor o fracciones truncadas; por consiguiente, deben descartarse de la cifra numérica, rellenando el extremo opuesto con ceros para conservar la validez del valor posicional.*  
*Por el contrario, las instrucciones de rotación resultan indispensables cuando la totalidad del contenido binario debe preservarse intacto dentro del flujo de cómputo, tal como ocurre en el cifrado simétrico por permutación, el cálculo de códigos de redundancia cíclica (CRC/checksums circulares) y la manipulación de campos de bits empaquetados. Un ejemplo paradigmático es el intercambio de los dos nibbles de un byte: al ejecutar `ROL al, 4` sobre el valor `0A5h` (`1010 0101b`), el nibble alto (`1010b`) es transferido circularmente a las posiciones 3..0, mientras que el nibble bajo (`0101b`) es reinsertado en las posiciones 7..4, obteniéndose con precisión `5Ah` (`0101 1010b`). Este reordenamiento posicional resulta matemáticamente imposible de lograr utilizando únicamente instrucciones de desplazamiento `SHL` sobre el mismo registro: cualquier aplicación de `SHL` sobre `0A5h` expulsará irrevocablemente los bits del nibble alto hacia el flag de acarreo `CF`, perdiéndose su valor en el registro e impidiendo que una posterior operación lógica `OR` pueda reconstruirlos sin un respaldo auxiliar en memoria o en un segundo registro.*  
*Esta diferencia fundamental se evidencia al analizar el bit más significativo (bit 7) al partir del dato de prueba `AL = 81h` (`1000 0001b`): tras ejecutar `SHL al, 1`, el bit 7 original (1) se expulsa hacia el flag `CF` y se descarta del byte, ingresando un 0 por el bit 0 y dejando el registro en `02h` (`0000 0010b`). En contraste, al aplicar `ROL al, 1` sobre el mismo operando inicial, el bit 7 viaja hacia `CF` pero se reinyecta simultáneamente por el extremo derecho en la posición 0, produciendo `03h` (`0000 0011b`). En conclusión, se debe emplear `SHL`/`SHR` cuando la información desplazada no forma parte del resultado algebraico, y `ROL`/`ROR` cuando los bits deben conservar su existencia mediante recirculación posicional.*  
  
---  
**Decisión Técnica 2: Evaluación Comparativa entre LOOP y la Secuencia DEC/JNZ**  
***Justificación Arquitectónica:***  
   
 *Desde la perspectiva del diseño del código fuente y la densidad de empaquetamiento, la instrucción `LOOP` ofrece notables ventajas de legibilidad, elegancia sintáctica y compacidad: condensa en un único opcode de 2 bytes la acción compuesta de decrementar el registro contador `CX` y realizar una bifurcación relativa corta condicionada a que `CX != 0`. Esto clarifica la intención algorítmica de un bucle contado y ahorra espacio frente a la codificación manual de instrucciones separadas en memorias de código estrechas propias del estándar original del procesador 8086.*  
*No obstante, en la microarquitectura de procesadores x86 posteriores (a partir del Intel 80486, la familia Pentium y de forma pronunciada en las arquitecturas modernas Core y Zen), la cantidad de instrucciones presentes en el archivo fuente no constituye un indicador fidedigno del número real de ciclos de reloj que demanda la ejecución en hardware. La instrucción `LOOP` es una instrucción compleja de microcódigo heredado que no suele mapearse a las rutas de decodificación directa de alta velocidad de los procesadores actuales; típicamente genera múltiples microoperaciones internas (\mu\text{ops}) y presenta una latencia mayor. En contraste, la secuencia desacoplada `DEC cx` seguida de `JNZ etiqueta` (o `SUB cx, 1` / `JNZ`) es reconocida de manera óptima por los decodificadores superescalares modernos, los cuales implementan macro-fusion, fusionando la comparación y el salto en una única microoperación de ejecución inmediata en una sola pasada de pipeline y beneficiándose plenamente de los predictores de saltos dinámicos.*  
*Asimismo, existe una disparidad de comportamiento funcional crítica: `DEC` actualiza los flags de estado aritmético (`ZF, SF, OF, PF`), mientras que `LOOP` decrementa `CX` de forma neutra sin modificar ningún flag del registro `FLAGS`. En el caso particular del bucle de 5 iteraciones desarrollado en este laboratorio, la penalización temporal de `LOOP` frente a `DEC/JNZ` resulta completamente imperceptible y despreciable frente a los costos de sobrecarga de invocación del sistema operativo emulado. Sin embargo, en bucles de procesamiento intensivo que ejecutan millones de repeticiones en entornos de cómputo de alto rendimiento, reemplazar `LOOP` por la secuencia optimizada `DEC/JNZ` genera un ahorro acumulativo de ciclos sustancial, justificando plenamente su adopción en compiladores optimizadores modernos.*  
  
---  
**5. Parte 2: Demostración de Modos de Direccionamiento**  
**5.1 Tabla Resumen de los Modos de Direccionamiento Implementados**  
  
|  |  |  |  |  |  
| - | - | - | - | - |  
| **Modo de Direccionamiento** |  **Fórmula de Dirección Efectiva (EA)** |  **Instrucción NASM Demostrada** |  **Registros Involucrados** |  **Valor Observado en DEBUG / Memoria** |  
| **Inmediato** |  No calcula EA (dato embebido en opcode de CS) |  `MOV ax, 100` |  `AX` |  `AX=0064h` (100 dec). Opcode: `B8 64 00`. Sin bus de datos. |  
| **Directo** |  EA = \text{Offset fijo codificado} |  `MOV ax, [var_x]` |  `AX`, `DS` |  `AX=FFFFh` leído de `DS:0113h`. Escribe `0000h` con `MOV [var_x], 0`. |  
| **Directo (Array)** |  EA = \text{Offset base del array} |  `MOV bx, [array]` |  `BX`, `DS` |  `BX=000Ah` (10 dec), correspondiente a `array[0]`. |  
| **Indirecto por Registro** |  EA = \[SI\] (o \[BX\]) |  `MOV ax, [si]` tras `MOV si, nota1` |  `SI`, `AX`, `DS` |  `SI=010Dh`, `AX=0055h` (85 dec). Acceso vía puntero. |  
| **Indirecto por Registro** |  EA = \[SI\] |  `MOV [si], ax` tras `MOV si, promedio` |  `SI`, `AX`, `DS` |  `SI=0111h`, escribe `promedio = 004Fh` (79 dec) en memoria. |  
| **Indexado (Base + Índice)** |  EA = BX + SI |  `MOV ax, [bx + si]` |  `BX`, `SI`, `AX` |  `BX=0103h`, `SI=0004h`, `AX=001Eh` (30 dec, `array[2]`). |  
| **Indexado (Bucle Asc.)** |  EA = BX + SI (paso +2) |  `ADD ax, [bx + si]` |  `BX`, `SI`, `CX`, `AX` |  Suma acumulada de 5 words: `AX=0096h` (150 decimal). |  
| **Indexado con Desplaz.** |  EA = BX + \text{desplazamiento} |  `MOV cx, [bx + 2]` |  `BX`, `CX`, `DS` |  `BX=010Dh` (base struct), lee `nota2 = 0049h` (73 dec). |  
| **Indexado (Bucle Inv.)** |  EA = BX + SI (paso -2) |  `ADD ax, [bx + si]` |  `BX`, `SI`, `CX`, `AX` |  Recorrido de `array[4]` a `array[0]`: `AX=0096h` (150 dec). |  
| **Indirecto BP (Marco Pila)** |  EA = SS:\[BP - \text{offset}\] |  `MOV ax, [bp - 2]` |  `BP`, `SP`, `SS`, `AX` |  `BP=FFEEh`, variables locales en `SS:FFEA` (`99` y `250`). Suma: `015Dh`. |  
| **Doble Indexación (Matriz)** |  EA = BX + (\text{Fila}\times 6) + (\text{Col}\times 2) |  `MOV dx, [bx + si]` |  `BX`, `SI`, `DX`, `DS` |  `BX=0115h`, `SI=000Ah` (10 dec), `DX=0006h` (`matriz[1][2]`). |  
| **Directo (Matriz Fija)** |  EA = \text{matriz} + 10 |  `MOV ax, [matriz + 10]` |  `AX`, `DS` |  `AX=0006h`. Mismo dato sin costo de cómputo en tiempo de ejecución. |  
  
   
  
---  
**5.2 Trazado Detallado del Modo Indirecto por Registro**  
La siguiente tabla refleja la secuencia de ejecución paso a paso con el depurador `DEBUG` en el bloque de cálculo de promedio de notas mediante punteros:  
  
|  |  |  |  |  
| - | - | - | - |  
| **Paso / Instrucción** |  **Registro Modificado** |  **Valor Resultante** |  **Propósito y Comportamiento Observado** |  
| `MOV si, nota1` |  `SI` |  `010Dh` |  Carga el puntero con la dirección de memoria de `nota1`. |  
| `MOV ax, [si]` |  `AX` |  `0055h` (85 dec) |  Dereferenciación indirecta: extrae el valor apuntado por `SI`. |  
| `MOV si, nota2` |  `SI` |  `010Fh` |  Conmuta el puntero para direccionar el campo contiguo `nota2`. |  
| `MOV bx, [si]` |  `BX` |  `0049h` (73 dec) |  Dereferenciación indirecta: extrae la segunda calificación en `BX`. |  
| `ADD ax, bx` |  `AX` |  `009Eh` (158 dec) |  Suma aritmética de las dos notas (85 + 73 = 158). |  
| `SHR ax, 1` |  `AX` |  `004Fh` (79 dec) |  División entera rápida entre dos: promedio calculado en `AX`. |  
| `MOV si, promedio` |  `SI` |  `0111h` |  Apunta el registro base/índice hacia la dirección de destino. |  
| `MOV [si], ax` |  Memoria (`[0111h]`) |  `004Fh` (79 dec) |  Escritura indirecta del promedio en el espacio de datos en memoria. |  
  
   
  
---  
**5.3 Extensión: Recorrido Inverso del Array**  
Para el Checkpoint 3 de la Parte 2, se programó un recorrido inverso sobre el arreglo unidimensional `array`:  
- Se posicionó el registro base en `BX = array` (`0103h`) y el índice en el último elemento: `SI = 8` (offset correspondiente a `array[4] = 50`).  
- En cada ciclo se acumula `ADD ax, [bx + si]`, se decrementa el índice en una palabra con `SUB si, 2` y se itera mediante `LOOP .bucle_array_inv`.  
- El resultado final acumulado en `AX` es estrictamente `0096h` (150 decimal), idéntico al obtenido en el barrido ascendente, comprobando la simetría del direccionamiento indexado bidireccional.  
  
---  
**5.4 Marco de Variables Locales en Pila mediante BP**  
Se estructuró el marco de activación convencional de llamada a función:  
1. `PUSH bp`: Se preserva el puntero base anterior.  
2. `MOV bp, sp`: Se ancla el marco fijando `BP` al tope actual de la pila (`FFEEh`).  
3. `SUB sp, 4`: Se reservan 4 bytes contiguos en la pila, desplazando `SP` a `FFEA`.  
4. Mediante direccionamiento indirecto con desplazamiento negativo respecto a `BP`, se inicializan las dos variables locales:  
  - `MOV word [bp - 2], 99`\to Escribe `0063h` (`63 00` en little-endian) en `SS:FFEC`.  
  - `MOV word [bp - 4], 250`\to Escribe `00FAh` (`FA 00` en little-endian) en `SS:FFEA`.  
5. Se efectúa la suma `MOV ax, [bp - 2]` y `ADD ax, [bp - 4]`, obteniendo en `AX` el valor 99 + 250 = 349 (`015Dh`).  
6. Se desmantela el marco mediante `MOV sp, bp` y `POP bp`, retornando `SP` y `BP` exactamente a sus estados iniciales de ejecución.  
  
---  
**5.5 Acceso a Matriz 3x3 mediante Doble Indexación**  
Para el acceso al elemento `matriz[1][2]` (fila 1, columna 2, cuyo valor es 6):  
   
 \text{Offset Total} = (\text{Fila} \times \text{ColumnasPorFila} \times \text{BytesPorElemento}) + (\text{Columna} \times \text{BytesPorElemento})  
   
 \text{Offset Total} = (1 \times 3 \times 2) + (2 \times 2) = 6 + 4 = 10\text{ bytes} = \text{000Ah}  
   
 El código ensamblador calcula dinámicamente este desplazamiento alojándolo en `SI = 000Ah` y ejecuta `MOV dx, [bx + si]`, recuperando de memoria el valor `0006h`. Se contrasta con el direccionamiento directo de desplazamiento constante `MOV ax, [matriz + 10]`, verificando que ambas instrucciones acceden a la misma celda de memoria.  
  
---  
**5.6 Evidencias Gráficas de la Parte 2**  
***Checkpoint 6: Dump de Memoria de la Estructura de Datos (Modo Directo e Inmediato)***  
Volcado `D DS:100` con `DEBUG` mostrando el arreglo `10, 20, 30, 40, 50` en representación little-endian (`0A 00 14 00 1E 00 28 00 32 00`) y las notas `55 00` (85) y `49 00` (73).  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 7: Trazado del Modo Indirecto por Registro***  
Inspección paso a paso con `SI` apuntando a `nota1` (`AX=0055h`), `nota2` (`BX=0049h`), división para promedio `AX=004Fh` (79 dec) y almacenamiento verificado con dump en `DS:0111h`.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 8: Modo Indexado con Recorrido Ascendente e Inverso***  
Verificación de la suma acumulada de los 5 enteros del array, comprobando `AX=0096h` (150 decimal) al término del recorrido ascendente y `AX=0096h` en el recorrido inverso.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 9: Marco de Pila con BP y Variables Locales***  
Comprobación de la igualdad inicial `BP=SP`, reserva con `SUB sp, 4` (`SP=FFEA`), dump en `SS:FFEA` con los valores `FA 00` (250) y `63 00` (99), suma resultante `AX=015Dh` (349 dec) y restauración limpia de `BP` y `SP`.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 10: Acceso a Matriz 3x3 con Doble Indexación***  
Dump de los 18 bytes continuos de la matriz, cálculo algebraico con `SI=000Ah` (10 decimal) y extracción exitosa en `DX=0006h` correspondiente a `matriz[1][2]`.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
***Checkpoint 11: Ejecución Final de los Programas en Consola DOSBox***  
Ejecución de los tres binarios (`lab6_instrucciones.com`, `lab6_factorial.com` y `lab6_modos.com`) demostrando terminación limpia con `INT 20h` y emisión de cadenas informativas.  
   
 ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAxElEQVR4nO1W0Q6AIAiE/v+bpaeaYyYc6NLVvbRm484DL1lEKAIRIWaG1zQ4IgAhsHCMJkc31BXQKmbtvF73iOkKQIvV8LbpFqAJ9Dvac2Z2iQ4N4UiYQ2gJ9G7g6TsupQw7UpHjefTCBCEmwueEaPAMhBzQBVDC+tkit2pOOQWXEx5H0gIy/ScK/Atq0os4k5ihHOilHJyYyyfhTIjIJg48idQ5EME6DrwlZB0HthaQcRG+FbeQuaZ/ewb2ScJfQBSe9p77EZ7a26s/yQAAAABJRU5ErkJggg==)  
  
---  
**6. Decisiones Técnicas de la Parte 2**  
**Decisión Técnica 3: Modo Directo frente a Modo Indexado para Posiciones Fijas**  
***Justificación Arquitectónica:***  
   
 *Cuando la posición de un elemento dentro de una estructura matricial o arreglo se encuentra rígidamente predeterminada y es plenamente conocida en tiempo de compilación —como ocurre en el caso del elemento `matriz[1][2]`—, el modo de direccionamiento directo con desplazamiento constante representa la opción técnica indiscutiblemente superior en términos de eficiencia de ciclos de reloj, huella de memoria y utilización de registros. En el modo directo (`MOV ax, [matriz + 10]`), el ensamblador efectúa la aritmética de punteros estática durante la fase de traducción, resolviendo la dirección efectiva como una constante embebida directamente en el opcode de la instrucción. Esto le permite al procesador ejecutar una única lectura de memoria sin consumir ciclos de ejecución en la Unidad Aritmético Lógica (ALU) ni comprometer registros de propósito general.*  
*Por el contrario, la implementación de la doble indexación en tiempo de ejecución exige desplegar una cadena considerable de instrucciones: una multiplicación entera `MUL bx` para ponderar la fila, un desplazamiento `SHL ax, 1` para convertir unidades a bytes, un segundo desplazamiento `SHL cx, 1` para la columna, una adición `ADD si, cx` para consolidar el offset y finalmente la lectura indexada `MOV dx, [bx + si]`. Esta secuencia introduce una severa penalización temporal por latencia de ejecución, genera dependencias de datos que frenan el cauce del procesador y altera múltiples flags de estado.*  
*No obstante, el modo indexado deja de ser una alternativa ineficiente y se convierte en una necesidad arquitectónica ineludible en el momento en que las coordenadas de fila o columna dejan de ser literales constantes y pasan a depender de variables dinámicas calculadas en tiempo de ejecución, tales como los índices generados por estructuras de bucles anidados que recorren la matriz. Si un algoritmo requiere calcular la sumatoria de las 9 celdas de la matriz bidimensional, implementar dicho recorrido mediante direccionamiento directo requeriría codificar manualmente 9 instrucciones `MOV`/`ADD` independientes con 9 etiquetas o desplazamientos fijos cableados en el código. Esta aproximación resultaría rígida, propensa a errores humanos y totalmente inviable ante matrices de mayor escala (N \times M). Por consiguiente, el direccionamiento indexado es el único mecanismo viable y escalable para el procesamiento iterativo general de colecciones de datos dinámicas.*  
  
---  
**Decisión Técnica 4: Análisis de Registros Base: BP frente a BX/SI y Segmentos Implícitos**  
***Justificación Arquitectónica:***  
   
 *En la arquitectura x86 de 16 bits en modo real, la diferenciación funcional entre el registro puntero base `BP` y los registros base/índice convencionales `BX`, `SI` y `DI` no es meramente una convención de nomenclatura del programador, sino una regla cableada en el diseño del decodificador de instrucciones de la Unidad de Gestión de Memoria (MMU). De acuerdo con la especificación de la arquitectura, cualquier instrucción de acceso a memoria que utilice `BP` como registro base calcula su dirección física asociándola de forma implícita y predeterminada al Segmento de Pila (`SS`), mientras que las instrucciones fundamentadas en `BX`, `SI` o `DI` calculan su dirección física referenciada por defecto al Segmento de Datos (`DS`). Esta separación responde a la necesidad de construir marcos de activación de procedimientos seguros: `BP` actúa como punto de anclaje estático para leer parámetros y variables locales alojadas en la pila sin que la variación dinámica del puntero `SP` altere las referencias relativas.*  
*En el contexto específico de este laboratorio, al implementar programas en formato `.COM`, el sistema operativo DOS establece un único segmento de memoria compartida donde `CS = DS = SS = ES`. Por esta razón particular, el acceso `[bp - 2]` y el acceso `[bx + si]` resuelven físicamente en la misma área de memoria lineal de 64 KB, ocultando cualquier anomalía visible. Sin embargo, en un programa de estructura segmentada estándar (formato ejecutable `.EXE`), el segmento de datos `DS` y el segmento de pila `SS` residen en bloques de memoria física completamente desacoplados (DS \neq SS). En dicho entorno, si un desarrollador asume erróneamente que `[bp + desplazamiento]` leerá una variable ubicada en el segmento de datos, el hardware x86 intentará dereferenciar ese offset dentro del segmento de pila `SS`. Esto provocará fallas lógicas críticas, lecturas de datos basura o corrupción catastrófica del marco de llamadas al sobreescribir direcciones de retorno.*  
*Para neutralizar esta regla arquitectónica y forzar a que una instrucción basada en `BP` acceda a variables ubicadas en el segmento de datos `DS`, es imperativo anteponer de forma explícita un prefijo de sobrescritura de segmento (Segment Override Prefix), codificando la instrucción bajo la sintaxis `MOV ax, [ds:bp + 2]`. Esta técnica adquiere sentido técnico real en sistemas operativos o bibliotecas de bajo nivel donde una función de inspección o depuración de memoria recibe en `BP` un puntero hacia una estructura de control alojada deliberadamente en el segmento de datos global. En código de producción mantenible, la buena práctica dicta respetar rigurosamente la convención de silicio: reservar `BP` con `SS` para la pila y emplear `BX`/`SI`/`DI` con `DS` para el acceso a datos.*  
  
---  
**7. Conclusiones**  
1. **Jerarquía y Eficiencia en la ISA x86:** Se constató experimentalmente que el repertorio de instrucciones x86 ofrece múltiples rutas operativas para resolver un mismo problema, pero con costos dispares en tiempo de procesador y ocupación de memoria. La manipulación de bits mediante rotaciones circulares (`ROL`/`ROR`) resuelve problemas de permutación posicional (como el intercambio de nibbles) que resultarían irresolubles con desplazamientos lógicos lineales (`SHL`/`SHR`), mientras que la sustitución de `LOOP` por `DEC/JNZ` fundamenta las bases de optimización en compiladores modernos.  
2. **Versatilidad de los Modos de Direccionamiento:** La arquitectura x86 proporciona un esquema altamente flexible de cálculo de direcciones efectivas. El modo inmediato y el directo son insustituibles para constantes y variables escalares fijas por su nulo costo de cómputo en ejecución. Por su parte, el direccionamiento indirecto por registro posibilita el concepto fundamental de punteros, y el direccionamiento indexado (base + índice + desplazamiento) permite modelar estructuras contiguas complejas, registros heterogéneos y matrices multidimensionales.  
3. **Rigurosidad de los Segmentos y la Pila:** La experimentación con el registro `BP` permitió verificar cómo se materializan los marcos de activación de variables locales a bajo nivel. Se comprendió que el acoplamiento implícito de `BP` al segmento `SS` garantiza la coherencia en la ejecución de subrutinas, evidenciando la importancia de distinguir entre el entorno unificado de un archivo `.COM` y el modelo multimultisegmento de un ejecutable `.EXE`.  
  
---  
**8. Referencias Técnicas**  
- Intel Corporation. (2024). *Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 1: Basic Architecture*. Intel Corporation. [https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html "https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html")  
- Advanced Micro Devices (AMD). (2024). *AMD64 Architecture Programmer’s Manual, Volume 1: Application Programming*. AMD. [https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/24592.pdf](https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/24592.pdf "https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/24592.pdf")  
- Fog, A. (2025). *Instruction tables: Lists of instruction latencies, throughputs and micro-operation breakdowns for Intel, AMD, and VIA CPUs*. Copenhagen University College of Engineering. [https://www.agner.org/optimize/instruction_tables.pdf](https://www.agner.org/optimize/instruction_tables.pdf "https://www.agner.org/optimize/instruction_tables.pdf")  
- The Netwide Assembler (NASM). (2024). *NASM - The Netwide Assembler version 2.16.03 Manual*. [https://www.nasm.us/doc/](https://www.nasm.us/doc/ "https://www.nasm.us/doc/")  

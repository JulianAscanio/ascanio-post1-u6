; ==============================================================================
; lab6_modos.asm
; Arquitectura de Computadores - Unidad 6: Post-contenido
; Demostración práctica de los 4 modos de direccionamiento x86:
; Inmediato, Directo, Indirecto por Registro e Indexado (Base + Índice + Desplazamiento),
; extendido con Marco de Pila (BP) y Arreglo Bidimensional (Matriz 3x3).
;
; Estudiante: Julián Ascanio
; Formato: COM (Modo Real x86 de 16 bits, CS=DS=SS=ES, Offset 100h)
; Compilación: nasm -f bin lab6_modos.asm -o lab6_modos.com
; ==============================================================================

bits 16
org  100h

; ------------------------------------------------------------------------------
; SECCIÓN DE DATOS
; ------------------------------------------------------------------------------
jmp inicio

; 1. Arreglo unidimensional de 5 enteros de 16 bits (words)
; Valores: 10 (000Ah), 20 (0014h), 30 (001Eh), 40 (0028h), 50 (0032h)
array           dw  10, 20, 30, 40, 50

; 2. Estructura de registro de estudiante (3 campos de 16 bits contiguos)
nota1           dw  85          ; 0055h (85 decimal)
nota2           dw  73          ; 0049h (73 decimal)
promedio        dw  0           ; Almacenará (85 + 73) / 2 = 79 (004Fh)

; 3. Variable escalar para direccionamiento directo
var_x           dw  0FFFFh      ; Variable inicializada en FFFFh

; 4. Matriz 3x3 de enteros de 16 bits (9 elementos, 18 bytes en memoria contigua)
; Fila 0: 1 (0001h), 2 (0002h), 3 (0003h)
; Fila 1: 4 (0004h), 5 (0005h), 6 (0006h)
; Fila 2: 7 (0007h), 8 (0008h), 9 (0009h)
matriz          dw  1, 2, 3
                dw  4, 5, 6
                dw  7, 8, 9

; 5. Tabla de conversión hexadecimal (opcional para XLAT)
tabla_hex       db  '0123456789ABCDEF'

; 6. Variables de auditoría para verificar resultados en memoria
val_inmediato   dw  0
val_directo_x   dw  0
val_directo_arr dw  0
val_directo_nt1 dw  0
val_indir_nota1 dw  0
val_indir_nota2 dw  0
val_index_elem2 dw  0
suma_ascendente dw  0
suma_inversa    dw  0
struct_nota1    dw  0
struct_nota2    dw  0
struct_promedio dw  0
bp_suma_locales dw  0
matriz_desplaz  dw  0
matriz_elem_idx dw  0
matriz_elem_dir dw  0

; 7. Mensaje informativo de salida
msg_modos       db  'Parte 2 finalizada: Modos de direccionamiento verificados con exito.$', 13, 10, '$'

; ------------------------------------------------------------------------------
; SECCIÓN DE CÓDIGO
; ------------------------------------------------------------------------------
inicio:

    ; ── MODO 1: INMEDIATO ────────────────────────────────────────────────────
    ; El operando forma parte intrínseca de la instrucción codificada en CS.
    ; No genera accesos adicionales al bus para buscar direcciones de datos.
    MOV  ax, 100                ; AX = 100 (0064h) - constante decimal
    MOV  bx, 0A5h               ; BX = 00A5h - constante hexadecimal
    ADD  cx, 55                 ; CX += 55 (0037h)
    AND  dx, 00FFh              ; DX AND 00FFh - máscara inmediata
    MOV  [val_inmediato], ax    ; Guarda 0064h

    ; ── MODO 2: DIRECTO ──────────────────────────────────────────────────────
    ; La dirección efectiva (offset) del operando está fija en el opcode.
    MOV  ax, [var_x]            ; AX = mem[dir_var_x] = 0FFFFh
    MOV  [val_directo_x], ax
    MOV  bx, [array]            ; BX = mem[dir_array] = 10 (000Ah) - elemento 0
    MOV  [val_directo_arr], bx
    MOV  cx, [nota1]            ; CX = mem[dir_nota1] = 85 (0055h)
    MOV  [val_directo_nt1], cx
    MOV  word [var_x], 0        ; Modificación directa en memoria: var_x = 0000h

    ; ── MODO 3: INDIRECTO POR REGISTRO ───────────────────────────────────────
    ; El operando se encuentra en la dirección apuntada por el registro SI o BX.
    ; Permite la implementación de punteros dinámicos en tiempo de ejecución.
    MOV  si, nota1              ; SI = dirección de memoria de nota1
    MOV  ax, [si]               ; AX = mem[SI] = 85 (0055h)
    MOV  [val_indir_nota1], ax

    MOV  si, nota2              ; SI = dirección de memoria de nota2
    MOV  bx, [si]               ; BX = mem[SI] = 73 (0049h)
    MOV  [val_indir_nota2], bx

    ; Cálculo del promedio: (nota1 + nota2) / 2
    ADD  ax, bx                 ; AX = 85 + 73 = 158 (009Eh)
    SHR  ax, 1                  ; AX = 158 / 2 = 79 (004Fh)
    MOV  si, promedio           ; SI = dirección de promedio
    MOV  [si], ax               ; mem[SI] = 79 (004Fh) - guarda resultado vía puntero

    ; ── MODO 4: INDEXADO (BASE + ÍNDICE + DESPLAZAMIENTO) ────────────────────
    ; Dirección efectiva EA = Base + Índice (+ Desplazamiento)
    ; Acceso a elemento puntual: array[2] (índice 2 * 2 bytes/word = offset 4)
    MOV  bx, array              ; BX = dirección base del array
    MOV  si, 4                  ; SI = índice de bytes (2 * 2 = 4)
    MOV  ax, [bx + si]          ; AX = mem[BX + SI] = array[2] = 30 (001Eh)
    MOV  [val_index_elem2], ax

    ; Recorrido ascendente del array completo (elementos 0 a 4)
    XOR  ax, ax                 ; AX = 0 (acumulador de suma)
    MOV  bx, array              ; Base del arreglo
    MOV  cx, 5                  ; 5 elementos a sumar
    XOR  si, si                 ; SI = 0 (inicio en array[0])
.bucle_array_asc:
    ADD  ax, [bx + si]          ; AX += elemento actual
    ADD  si, 2                  ; Avanzar 1 word (2 bytes)
    LOOP .bucle_array_asc       ; Repite hasta completar los 5 elementos
    MOV  [suma_ascendente], ax  ; AX = 10+20+30+40+50 = 150 (0096h)

    ; Acceso a campos contiguos de estructura con base y desplazamiento fijo
    MOV  bx, nota1              ; BX = base del struct de estudiante
    MOV  ax, [bx]               ; Campo 1: nota1 (desplazamiento +0) = 85 (0055h)
    MOV  [struct_nota1], ax
    MOV  cx, [bx + 2]           ; Campo 2: nota2 (desplazamiento +2) = 73 (0049h)
    MOV  [struct_nota2], cx
    MOV  dx, [bx + 4]           ; Campo 3: promedio (desplazamiento +4) = 79 (004Fh)
    MOV  [struct_promedio], dx

    ; Extensión Checkpoint 3: Recorrido inverso del array (de array[4] a array[0])
    XOR  ax, ax                 ; AX = 0 (acumulador)
    MOV  bx, array              ; BX = dirección base
    MOV  cx, 5                  ; 5 elementos
    MOV  si, 8                  ; SI = offset del último elemento: 4 * 2 = 8
.bucle_array_inv:
    ADD  ax, [bx + si]          ; AX += array[si/2]
    SUB  si, 2                  ; Retroceder 1 word (2 bytes)
    LOOP .bucle_array_inv
    MOV  [suma_inversa], ax     ; AX = 50+40+30+20+10 = 150 (0096h)

    ; ── MODO 3b: INDIRECTO POR REGISTRO BP (Marco de Pila / Variables Locales)
    ; BP asume por arquitectura el segmento SS (Stack Segment) de forma predeterminada.
    PUSH bp                     ; Preservar el valor de BP del llamador
    MOV  bp, sp                 ; BP = SP (establece la base del nuevo marco de activación)
    SUB  sp, 4                  ; Reserva espacio en la pila para dos variables locales (4 bytes)

    ; Asignación a variables locales relativas al puntero base BP
    MOV  word [bp - 2], 99      ; local_1 = 99 (0063h) en [SS:BP-2]
    MOV  word [bp - 4], 250     ; local_2 = 250 (00FAh) en [SS:BP-4]

    ; Operación aritmética con operandos alojados en la pila
    MOV  ax, [bp - 2]           ; AX = 99
    ADD  ax, [bp - 4]           ; AX = 99 + 250 = 349 (015Dh)
    MOV  [bp_suma_locales], ax  ; Almacena 015Dh

    ; Desmontaje del marco de pila y restauración de registros
    MOV  sp, bp                 ; Desasigna las variables locales
    POP  bp                     ; Restaura el BP original

    ; ── ACCESO A MATRIZ 3x3: Doble Indexación (Fila y Columna) ───────────────
    ; Cálculo de dirección efectiva:
    ; Offset = (fila * num_columnas * tamaño_elemento) + (columna * tamaño_elemento)
    ; Elemento objetivo: matriz[1][2] (Fila 1, Columna 2) -> Valor: 6
    MOV  ax, 1                  ; Fila = 1
    MOV  bx, 3                  ; Ancho de fila = 3 elementos (columnas)
    MUL  bx                     ; AX = 1 * 3 = 3 elementos acumulados
    SHL  ax, 1                  ; AX = 3 * 2 bytes = 6 bytes (desplazamiento de fila)
    MOV  si, ax                 ; SI = 6

    MOV  cx, 2                  ; Columna = 2
    SHL  cx, 1                  ; CX = 2 * 2 bytes = 4 bytes (desplazamiento de columna)
    ADD  si, cx                 ; SI = 6 + 4 = 10 bytes de desplazamiento total (000Ah)
    MOV  [matriz_desplaz], si

    MOV  bx, matriz             ; BX = dirección base de la matriz
    MOV  dx, [bx + si]          ; DX = mem[BX + SI] = matriz[1][2] = 6 (0006h)
    MOV  [matriz_elem_idx], dx

    ; Comparación con direccionamiento directo para posición fija conocida en compilación:
    ; Offset constante: 10 bytes -> [matriz + 10]
    MOV  ax, [matriz + 10]      ; AX = mem[matriz + 10] = 6 (0006h)
    MOV  [matriz_elem_dir], ax

    ; ── Finalización del programa ────────────────────────────────────────────
    MOV  dx, msg_modos
    MOV  ah, 09h
    INT  21h
    INT  20h                    ; Retorno a DOS

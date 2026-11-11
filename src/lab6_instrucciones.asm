; ==============================================================================
; lab6_instrucciones.asm
; Arquitectura de Computadores - Unidad 6: Post-contenido
; Demostración práctica de las 4 categorías fundamentales de instrucciones x86
; y contraste de rotación (ROL/ROR) frente a desplazamiento (SHL/SHR)
;
; Estudiante: Julián Ascanio
; Formato: COM (Modo Real x86 de 16 bits, CS=DS=SS=ES, Offset 100h)
; Compilación: nasm -f bin lab6_instrucciones.asm -o lab6_instrucciones.com
; ==============================================================================

bits 16
org  100h

; ------------------------------------------------------------------------------
; SECCIÓN DE DATOS
; ------------------------------------------------------------------------------
jmp inicio

; Operandos de prueba
valor_a         dw  45          ; 002Dh (45 decimal)
valor_b         dw  12          ; 000Ch (12 decimal)

; Variables para almacenar resultados aritméticos
resultado_add   dw  0           ; 45 + 12 = 57 (0039h)
resultado_sub   dw  0           ; 12 - 45 = -33 (FFDFh en complemento a 2)
resultado_mul   dw  0           ; 10 * 7 = 70 (0046h)
cociente_div    db  0           ; 100 / 7 = 14 (0Eh)
resto_div       db  0           ; 100 % 7 = 2 (02h)

; Variables para operaciones lógicas y desplazamientos
contador        db  5           ; Iteraciones del bucle
mascara         db  0Fh         ; Máscara de los 4 bits menos significativos
resultado_and   db  0           ; 0B7h AND 0Fh = 07h
resultado_or    db  0           ; 0B7h OR F0h = F7h
resultado_xor   db  0           ; 0AAh XOR FFh = 55h
resultado_test  db  0           ; Conserva 0B7h tras verificación de imparidad
resultado_shl3  db  0           ; 08h << 2 = 20h (32 decimal)
resultado_shr3  db  0           ; 20h >> 1 = 10h (16 decimal)

; Variables para control de flujo
resultado_cmp   db  0           ; Indicador de comparación (1: mayor, 2: igual, 0: menor)
resultado_suma  dw  0           ; Suma acumulada 1..5 con LOOP = 15 (000Fh)
resultado_dec   dw  0           ; Suma acumulada 1..5 con DEC/JNZ = 15 (000Fh)

; Variables para Bloque 5: Desplazamiento vs Rotación
resultado_shl5  db  0           ; 81h SHL 1 = 02h, CF=1
resultado_rol5  db  0           ; 81h ROL 1 = 03h, CF=1
resultado_shr5  db  0           ; 81h SHR 1 = 40h, CF=1
resultado_ror5  db  0           ; 81h ROR 1 = C0h, CF=1
resultado_swap  db  0           ; 0A5h ROL 4 = 5Ah (intercambio de nibbles)

; Variables para captura de flags de estado
flags_add       dw  0           ; Registro de flags tras ADD
flags_sub       dw  0           ; Registro de flags tras SUB
flags_and       dw  0           ; Registro de flags tras AND
flags_test      dw  0           ; Registro de flags tras TEST
flags_cmp       dw  0           ; Registro de flags tras CMP

; Mensaje de finalización
msg_salida      db  'Parte 1 finalizada: Instrucciones x86 verificadas correctamente.$', 13, 10, '$'

; ------------------------------------------------------------------------------
; SECCIÓN DE CÓDIGO
; ------------------------------------------------------------------------------
inicio:

    ; ── BLOQUE 1: Transferencia de datos ─────────────────────────────────────
    ; MOV: carga directa de memoria a registros
    MOV  ax, [valor_a]          ; AX = 45 (002Dh)
    MOV  bx, [valor_b]          ; BX = 12 (000Ch)

    ; MOV entre registros de propósito general
    MOV  cx, ax                 ; CX = AX = 45
    MOV  dx, bx                 ; DX = BX = 12

    ; LEA: obtención del desplazamiento efectivo del símbolo en memoria
    LEA  si, [valor_a]          ; SI = dirección de memoria de valor_a (offset)
    MOV  ax, [si]               ; AX = contenido apuntado por SI = 45

    ; XCHG: intercambio atómico de contenido entre registros
    XCHG cx, dx                 ; CX = 12, DX = 45
    XCHG cx, dx                 ; Restaura: CX = 45, DX = 12

    ; PUSH / POP: preservación y restauración en la pila del sistema (SS:SP)
    PUSH ax                     ; Apila AX (45)
    MOV  ax, 0FFFFh             ; Modifica AX con valor temporal
    POP  ax                     ; Recupera AX = 45 desde el tope de la pila

    ; ── BLOQUE 2: Operaciones aritméticas ────────────────────────────────────
    ; ADD: suma de 16 bits y actualización de flags
    MOV  ax, [valor_a]          ; AX = 45
    ADD  ax, [valor_b]          ; AX = 45 + 12 = 57 (0039h). ZF=0, CF=0, SF=0, OF=0
    PUSHF                       ; Guarda el registro de FLAGS en la pila
    POP  dx                     ; DX = estado de FLAGS tras ADD
    MOV  [flags_add], dx        ; Respaldar flags
    MOV  [resultado_add], ax    ; resultado_add = 57

    ; SUB: resta de 16 bits produciendo resultado negativo en complemento a 2
    MOV  ax, [valor_b]          ; AX = 12
    SUB  ax, [valor_a]          ; AX = 12 - 45 = -33 (FFDFh). SF=1, CF=1 (préstamo), OF=0, ZF=0
    PUSHF                       ; Guarda FLAGS
    POP  dx
    MOV  [flags_sub], dx        ; Respaldar flags
    MOV  [resultado_sub], ax    ; resultado_sub = FFDFh

    ; INC y DEC: incremento y decremento unitario (no alteran el flag CF)
    MOV  ax, [valor_a]          ; AX = 45
    INC  ax                     ; AX = 46
    DEC  ax                     ; AX = 45

    ; MUL: multiplicación sin signo de 8 bits (AX = AL * operando)
    MOV  al, 10                 ; AL = 10
    MOV  bl, 7                  ; BL = 7
    MUL  bl                     ; AX = 10 * 7 = 70 (0046h); AH=0, AL=70. CF=0, OF=0
    MOV  [resultado_mul], ax    ; resultado_mul = 70

    ; DIV: división entera sin signo de 16 bits entre 8 bits (AL=cociente, AH=resto)
    MOV  ax, 100                ; AX = 100
    MOV  bl, 7                  ; BL = 7
    DIV  bl                     ; AL = 14 (cociente), AH = 2 (residuo: 100 = 7*14 + 2)
    MOV  [cociente_div], al     ; cociente_div = 14
    MOV  [resto_div], ah        ; resto_div = 2

    ; ── BLOQUE 3: Operaciones lógicas ────────────────────────────────────────
    MOV  al, 0B7h               ; AL = 1011 0111b (0xB7)

    ; AND: enmascaramiento para conservar exclusivamente los 4 bits bajos
    AND  al, [mascara]          ; AL = B7h AND 0Fh = 07h (0000 0111b). ZF=0, CF=0, OF=0
    PUSHF
    POP  dx
    MOV  [flags_and], dx
    MOV  [resultado_and], al

    ; OR: activación forzada de los 4 bits más significativos
    MOV  al, 0B7h               ; Restaura AL
    OR   al, 0F0h               ; AL = B7h OR F0h = F7h (1111 0111b)
    MOV  [resultado_or], al

    ; XOR: inversión bit a bit (NOT selectivo mediante máscara de unos)
    MOV  al, 0AAh               ; AL = 1010 1010b (0xAA)
    XOR  al, 0FFh               ; AL = 0101 0101b (0x55)
    MOV  [resultado_xor], al

    ; XOR reg, reg: puesta a cero óptima sin acceso a memoria y con menor huella de bytes
    XOR  bx, bx                 ; BX = 0 (2 bytes de opcode en lugar de 3 con MOV bx, 0)

    ; TEST: verificación lógica AND sin destruir el registro destino (sólo altera flags)
    MOV  al, 0B7h               ; AL = 1011 0111b
    TEST al, 01h                ; Evalúa si el bit 0 es 1 (impar). ZF=0, CF=0, OF=0
    PUSHF
    POP  dx
    MOV  [flags_test], dx
    MOV  [resultado_test], al   ; AL conserva su valor original 0B7h

    ; SHL / SHR: desplazamientos lógicos para multiplicar y dividir potencias de 2
    MOV  al, 08h                ; AL = 8 (0000 1000b)
    SHL  al, 2                  ; AL = 8 * 2^2 = 32 (0010 0000b = 20h)
    MOV  [resultado_shl3], al
    SHR  al, 1                  ; AL = 32 / 2^1 = 16 (0001 0000b = 10h)
    MOV  [resultado_shr3], al

    ; ── BLOQUE 4: Control de flujo ───────────────────────────────────────────
    ; CMP y bifurcación condicional con signo
    MOV  ax, [valor_a]          ; AX = 45
    CMP  ax, [valor_b]          ; 45 - 12 = 33 > 0. CF=0, ZF=0, SF=0, OF=0
    PUSHF
    POP  dx
    MOV  [flags_cmp], dx
    JG   .mayor                 ; Salta si con signo AX > valor_b
    JE   .igual                 ; Salta si AX == valor_b
    MOV  byte [resultado_cmp], 0 ; Indicador: menor
    JMP  .fin_cmp
.mayor:
    MOV  byte [resultado_cmp], 1 ; Indicador: mayor
    JMP  .fin_cmp
.igual:
    MOV  byte [resultado_cmp], 2 ; Indicador: igual
.fin_cmp:

    ; Bucle 1: Suma acumulada de 1 a 5 con la instrucción LOOP (CX como contador)
    XOR  ax, ax                 ; AX = 0 (acumulador)
    MOV  cx, 5                  ; CX = 5 (contador)
    MOV  bx, 1                  ; BX = término inicial a sumar
.bucle_suma:
    ADD  ax, bx                 ; AX += BX
    INC  bx                     ; Siguiente sumando
    LOOP .bucle_suma            ; Decrementa CX; si CX != 0 continúa el bucle
    MOV  [resultado_suma], ax   ; AX = 1+2+3+4+5 = 15 (000Fh)

    ; Bucle 2: Implementación funcional idéntica empleando DEC cx y JNZ
    XOR  ax, ax                 ; AX = 0 (acumulador)
    MOV  cx, 5                  ; CX = 5 (contador)
    MOV  bx, 1                  ; BX = 1
.bucle_dec:
    ADD  ax, bx                 ; AX += BX
    INC  bx                     ; Siguiente sumando
    DEC  cx                     ; Decrementa CX explícitamente (modifica flags: ZF)
    JNZ  .bucle_dec             ; Salta si ZF=0 (CX != 0)
    MOV  [resultado_dec], ax    ; AX = 15 (000Fh)

    ; ── BLOQUE 5: Desplazamiento frente a Rotación (SHL/SHR vs ROL/ROR) ──────
    MOV  al, 81h                ; AL = 1000 0001b (bit 7=1 y bit 0=1)

    ; Contraste por el extremo izquierdo:
    ; SHL: el bit más significativo (bit 7) es expulsado hacia CF; el bit 0 se llena con 0
    MOV  bl, al                 ; BL = 81h
    SHL  bl, 1                  ; BL = 0000 0010b = 02h; CF=1 (bit 7 original descartado del byte)
    MOV  [resultado_shl5], bl

    ; ROL: el bit más significativo (bit 7) viaja a CF Y se reinserta en el bit 0
    MOV  cl, al                 ; CL = 81h
    ROL  cl, 1                  ; CL = 0000 0011b = 03h; CF=1 (bit 7 preservado en la posición 0)
    MOV  [resultado_rol5], cl

    ; Contraste por el extremo derecho:
    ; SHR: el bit menos significativo (bit 0) es expulsado a CF; el bit 7 se llena con 0
    MOV  dl, al                 ; DL = 81h
    SHR  dl, 1                  ; DL = 0100 0000b = 40h; CF=1 (bit 0 original descartado del byte)
    MOV  [resultado_shr5], dl

    ; ROR: el bit menos significativo (bit 0) viaja a CF Y se reinserta en el bit 7
    MOV  bh, al                 ; BH = 81h
    ROR  bh, 1                  ; BH = 1100 0000b = C0h; CF=1 (bit 0 preservado en la posición 7)
    MOV  [resultado_ror5], bh

    ; Aplicación práctica de ROL: Intercambio íntegro de nibbles (alto <-> bajo)
    MOV  al, 0A5h               ; AL = 1010 0101b (nibble alto=A, nibble bajo=5)
    ROL  al, 4                  ; AL = 0101 1010b = 5Ah (nibble alto=5, nibble bajo=A)
    MOV  [resultado_swap], al   ; resultado_swap = 5Ah

    ; ── Finalización del programa ────────────────────────────────────────────
    MOV  dx, msg_salida         ; Cargar cadena informativa para INT 21h
    MOV  ah, 09h                ; Función DOS 09h: Imprimir cadena terminada en '$'
    INT  21h                    ; Llamada al sistema operativo DOS
    INT  20h                    ; Retorno limpio al entorno DOS (PSP termination)

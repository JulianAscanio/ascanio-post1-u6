; ==============================================================================
; lab6_factorial.asm
; Arquitectura de Computadores - Unidad 6: Post-contenido (Checkpoint 3)
; Variante del bucle iterativo: Cálculo del factorial de 5 (5! = 120)
;
; Estudiante: Julián Ascanio
; Formato: COM (Modo Real x86 de 16 bits, CS=DS=SS=ES, Offset 100h)
; Compilación: nasm -f bin lab6_factorial.asm -o lab6_factorial.com
; ==============================================================================

bits 16
org  100h

; ------------------------------------------------------------------------------
; SECCIÓN DE DATOS
; ------------------------------------------------------------------------------
jmp inicio

numero_n        dw  5           ; Valor de n para calcular n!
resultado_fact  dw  0           ; 5! = 5 * 4 * 3 * 2 * 1 = 120 (0078h)
msg_fact        db  'Calculo de factorial: 5! = 120 (0078h) completado.$', 13, 10, '$'

; ------------------------------------------------------------------------------
; SECCIÓN DE CÓDIGO
; ------------------------------------------------------------------------------
inicio:
    ; Inicialización para cálculo del producto acumulado
    MOV  ax, 1                  ; AX = 1 (acumulador multiplicativo neutro)
    MOV  bx, 1                  ; BX = factor multiplicador inicial (1..5)
    MOV  cx, [numero_n]         ; CX = 5 (contador de iteraciones para LOOP)

.bucle_factorial:
    MUL  bx                     ; AX = AX * BX (parte alta en DX queda 0000h)
    INC  bx                     ; Siguiente multiplicador
    LOOP .bucle_factorial       ; Decrementa CX y salta si CX != 0

    ; Al terminar el bucle, AX contiene 120 (0078h)
    MOV  [resultado_fact], ax   ; Almacena 120 en memoria

    ; Notificación por consola DOS
    MOV  dx, msg_fact
    MOV  ah, 09h
    INT  21h

    ; Retorno a DOS
    INT  20h

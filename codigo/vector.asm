; Programa interactivo con vectores - TASM 16-bit
; Versi?n corregida

.MODEL SMALL
.STACK 100h
.DATA
menu_title DB 13,10,'Menu:','$'
menu_o1 DB '1-Ingresar 10 numeros',13,10,'$'
menu_o2 DB '2-Mostrar vector',13,10,'$'
menu_o3 DB '3-Promedio',13,10,'$'
menu_o4 DB '4-Mayor',13,10,'$'
menu_o5 DB '5-Menor',13,10,'$'
menu_o6 DB '6-Salir',13,10,'$'
prompt DB '-> $'
ingreso DB 13,10,'Ingrese numero: $'
newline DB 13,10,'$'

numeros DW 10 DUP(0)
mayor DW 0
menor DW 0
suma DW 0
opcion DB 0
    entered_count DB 0
    full_msg DB 13,10,'Vector lleno. Presione una tecla para continuar...','$'

.CODE
start:
    MOV AX, SEG numeros
    MOV DS, AX

main_loop:
    LEA DX, menu_title
    MOV AH,09h
    INT 21h
    LEA DX, menu_o1
    MOV AH,09h
    INT 21h
    LEA DX, menu_o2
    MOV AH,09h
    INT 21h
    LEA DX, menu_o3
    MOV AH,09h
    INT 21h
    LEA DX, menu_o4
    MOV AH,09h
    INT 21h
    LEA DX, menu_o5
    MOV AH,09h
    INT 21h
    LEA DX, menu_o6
    MOV AH,09h
    INT 21h
    LEA DX, prompt
    MOV AH,09h
    INT 21h

    MOV AH,01h
    INT 21h
    SUB AL,30h
    MOV opcion, AL

    CMP AL,1
    JNE .chk2
    JMP do_ingresar
.chk2:
    CMP AL,2
    JNE .chk3
    JMP do_mostrar
.chk3:
    CMP AL,3
    JNE .chk4
    JMP do_promedio
.chk4:
    CMP AL,4
    JNE .chk5
    JMP do_mayor
.chk5:
    CMP AL,5
    JNE .chk6
    JMP do_menor
.chk6:
    CMP AL,6
    JNE main_loop
    JMP do_salir

; Ingresar 10 numeros
do_ingresar:
    ; comenzar desde entered_count, permitir hasta 10 entradas en total
    MOV AL, [entered_count]
    CMP AL, 10
    JGE .full
    ; CX = remaining = 10 - entered_count
    MOV AH, 0
    MOV BX, 10
    MOV AL, [entered_count]
    XOR AH, AH
    SUB BX, AX
    MOV CX, BX
    ; SI = entered_count * 2 (byte offset in words)
    MOV AL, [entered_count]
    XOR AH, AH
    MOV SI, AX
    SHL SI, 1
.ingresar_loop2:
    LEA DX, ingreso
    MOV AH, 09h
    INT 21h
    CALL leer_numero
    MOV [numeros+SI], AX
    ADD SI, 2
    INC BYTE PTR [entered_count]
    LOOP .ingresar_loop2
    JMP main_loop
.full:
    LEA DX, full_msg
    MOV AH,09h
    INT 21h
    MOV AH,01h
    INT 21h
    JMP main_loop

; Mostrar vector
do_mostrar:
    LEA DX, newline
    MOV AH,09h
    INT 21h
    MOV CX,10
    XOR SI,SI
.show_loop:
    MOV AX,[numeros+SI]
    CALL print_num
    LEA DX, newline
    MOV AH,09h
    INT 21h
    ADD SI,2
    LOOP .show_loop
    JMP main_loop

; Promedio
do_promedio:
    XOR AX,AX
    XOR SI,SI
    MOV CX,10
.sum_loop:
    ADD AX,[numeros+SI]
    ADD SI,2
    LOOP .sum_loop
    MOV suma,AX
    MOV DX,0
    MOV CX,10
    DIV CX
    CALL print_num
    JMP main_loop

; Mayor
do_mayor:
    MOV AX,[numeros]
    MOV mayor,AX
    MOV CX,9
    MOV SI,2
.max_loop:
    MOV AX,[numeros+SI]
    CMP AX, mayor
    JLE .nextm
    MOV mayor,AX
.nextm:
    ADD SI,2
    LOOP .max_loop
    MOV AX, mayor
    CALL print_num
    JMP main_loop

; Menor
do_menor:
    MOV AX,[numeros]
    MOV menor,AX
    MOV CX,9
    MOV SI,2
.min_loop:
    MOV AX,[numeros+SI]
    CMP AX, menor
    JGE .nextn
    MOV menor,AX
.nextn:
    ADD SI,2
    LOOP .min_loop
    MOV AX, menor
    CALL print_num
    JMP main_loop

; Salir
do_salir:
    MOV AH,4Ch
    INT 21h
; Rutinas
; Leer hasta 2 dígitos. Devuelve AX con el numero (0 si solo Enter).
leer_numero PROC
    ; Preserve BX (used as accumulator) and CX (used as temp)
    PUSH BX
    PUSH CX

    XOR BX, BX        ; accumulator in BX (word)
    XOR CX, CX        ; digit counter

leer_loop:
    MOV AH,01h
    INT 21h
    CMP AL,13
    JE leer_done
    CMP AL,'0'
    JB leer_loop
    CMP AL,'9'
    JA leer_loop
    SUB AL,30h         ; AL = digit (0-9)
    MOV AH,0           ; zero-extend AL into AX (AX = 0:AL)

    ; BX = BX*10 -> BX*8 + BX*2
    MOV DX, BX
    SHL BX, 1          ; BX = BX*2
    SHL DX, 3          ; DX = original*8
    ADD BX, DX         ; BX = original*10
    ADD BX, AX         ; BX += digit

    INC CX
    CMP CX, 2
    JNE leer_loop

    ; limpiar resto hasta Enter
consume_rest:
    MOV AH,01h
    INT 21h
    CMP AL,13
    JNE consume_rest

leer_done:
    MOV AX, BX
    POP CX
    POP BX
    RET
leer_numero ENDP

; Imprimir numero decimal en AX
print_num PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX,0
    CMP AX,0
    JNE p_calc
    MOV DL,'0'
    MOV AH,02h
    INT 21h
    JMP p_done
p_calc:
    MOV BX,10
p_conv:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX,0
    JNE p_conv
p_print:
    POP DX
    ADD DL,30h
    MOV AH,02h
    INT 21h
    LOOP p_print
p_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
print_num ENDP

END start
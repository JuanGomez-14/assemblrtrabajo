; -------------------------------------------------------------
; PROGRAMA INTERACTIVO CON VECTORES - TASM 16-bit
; -------------------------------------------------------------
; Autor: (Tu nombre)
; Descripción general:
; Este programa permite al usuario trabajar con un vector (arreglo)
; de 10 números enteros de dos dígitos (00 a 99).
;
; Funcionalidades del programa:
;  1. Ingresar 10 números (cada uno de dos dígitos exactos)
;  2. Mostrar el contenido del vector
;  3. Calcular e imprimir el promedio de los 10 números
;  4. Mostrar el número mayor
;  5. Mostrar el número menor
;  6. Salir del programa
;
; El programa usa interrupciones de DOS (INT 21h) para la entrada
; y salida de datos. Está escrito para modo real de 16 bits (TASM).
; -------------------------------------------------------------

.MODEL SMALL          ; Modelo de memoria pequeño (código y datos separados)
.STACK 100h           ; Tamaño de la pila: 256 bytes

.DATA                 ; Sección de datos (variables y textos)

; ---- Textos del menú que se muestran al usuario ----
menu_title DB 13,10,'Menu:','$'
menu_o1 DB '1-Ingresar 10 numeros',13,10,'$'
menu_o2 DB '2-Mostrar vector',13,10,'$'
menu_o3 DB '3-Promedio',13,10,'$'
menu_o4 DB '4-Mayor',13,10,'$'
menu_o5 DB '5-Menor',13,10,'$'
menu_o6 DB '6-Salir',13,10,'$'
prompt DB '-> $'                      ; Símbolo del menú para ingresar opción
ingreso DB 13,10,'Ingrese numero: $'  ; Mensaje que pide el número
newline DB 13,10,'$'                  ; Salto de línea

; ---- Variables para cálculos ----
numeros DW 10 DUP(0)                  ; Vector de 10 números (2 bytes cada uno)
mayor DW 0                            ; Guardará el número mayor
menor DW 0                            ; Guardará el número menor
suma DW 0                             ; Guardará la suma de los 10 números
opcion DB 0                           ; Opción elegida del menú
entered_count DB 0                    ; Contador de cuántos números se han ingresado
full_msg DB 13,10,'Vector lleno. Presione una tecla para continuar...','$'

.CODE
start:
    ; Inicialización del segmento de datos.
    ; Esto es necesario para que el programa pueda acceder correctamente
    ; a las variables definidas en la sección .DATA.
    MOV AX, SEG numeros
    MOV DS, AX


; ==============================================================
;                   MENÚ PRINCIPAL DEL PROGRAMA
; ==============================================================
main_loop:
    ; Muestra en pantalla todas las opciones del menú.
    ; Se usa la interrupción 21h, función 09h, para imprimir cadenas.

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

    ; Muestra el símbolo "->" para que el usuario ingrese su opción.
    LEA DX, prompt
    MOV AH,09h
    INT 21h

    ; Espera que el usuario presione una tecla (número 1 al 6)
    MOV AH,01h
    INT 21h           ; devuelve el carácter ASCII en AL
    SUB AL,30h        ; convierte el carácter ASCII ('1') en número (1)
    MOV opcion, AL    ; guarda la opción ingresada

    ; Imprime salto de línea
    LEA DX, newline
    MOV AH,09h
    INT 21h


    ; --- Verifica qué opción seleccionó el usuario ---
    CMP AL,1
    JNE .chk2
    JMP do_ingresar   ; Opción 1
.chk2:
    CMP AL,2
    JNE .chk3
    JMP do_mostrar    ; Opción 2
.chk3:
    CMP AL,3
    JNE .chk4
    JMP do_promedio   ; Opción 3
.chk4:
    CMP AL,4
    JNE .chk5
    JMP do_mayor      ; Opción 4
.chk5:
    CMP AL,5
    JNE .chk6
    JMP do_menor      ; Opción 5
.chk6:
    CMP AL,6
    JNE main_loop
    JMP do_salir      ; Opción 6


; ==============================================================
; OPCIÓN 1: INGRESAR LOS 10 NÚMEROS
; ==============================================================
do_ingresar:
    ; Verifica si ya se ingresaron los 10 números.
    ; Si el vector está lleno, muestra mensaje y regresa al menú.
    MOV AL, [entered_count]
    CMP AL, 10
    JGE .full

    ; Calcula cuántos números faltan por ingresar:
    ; CX = 10 - entered_count
    MOV AH, 0
    MOV BX, 10
    MOV AL, [entered_count]
    XOR AH, AH
    SUB BX, AX
    MOV CX, BX

    ; Calcula la posición inicial donde guardar los nuevos números.
    ; Como cada número ocupa 2 bytes (palabra), multiplicamos por 2.
    MOV AL, [entered_count]
    XOR AH, AH
    MOV SI, AX
    SHL SI, 1

.ingresar_loop2:
    ; Muestra mensaje para que el usuario escriba un número.
    LEA DX, ingreso
    MOV AH, 09h
    INT 21h

    ; Llama a la rutina que lee exactamente dos dígitos.
    CALL leer_numero

    ; Guarda el número leído en el vector.
    MOV [numeros+SI], AX

    ; Avanza al siguiente espacio del vector.
    ADD SI, 2

    ; Aumenta el contador de números ingresados.
    INC BYTE PTR [entered_count]

    ; Repite hasta completar los números que faltan.
    LOOP .ingresar_loop2
    JMP main_loop

.full:
    ; Si ya se habían ingresado 10 números, muestra un mensaje.
    LEA DX, full_msg
    MOV AH,09h
    INT 21h

    ; Espera que el usuario presione una tecla para continuar.
    MOV AH,01h
    INT 21h
    JMP main_loop


; ==============================================================
; OPCIÓN 2: MOSTRAR LOS NÚMEROS DEL VECTOR
; ==============================================================
do_mostrar:
    LEA DX, newline
    MOV AH,09h
    INT 21h

    ; Se van a mostrar los 10 números.
    MOV CX,10
    XOR SI,SI

.show_loop:
    ; Carga el número actual en AX.
    MOV AX,[numeros+SI]

    ; Llama a la subrutina que imprime el número en decimal.
    CALL print_num

    ; Salta de línea después de cada número.
    LEA DX, newline
    MOV AH,09h
    INT 21h

    ; Pasa al siguiente número del vector.
    ADD SI,2
    LOOP .show_loop

    JMP main_loop


; ==============================================================
; OPCIÓN 3: CALCULAR EL PROMEDIO
; ==============================================================
do_promedio:
    ; Inicializa los registros y variables necesarias.
    XOR AX,AX          ; acumulador de suma = 0
    XOR SI,SI
    MOV CX,10          ; contador de 10 números

.sum_loop:
    ; Suma cada número del vector.
    ADD AX,[numeros+SI]
    ADD SI,2
    LOOP .sum_loop

    ; Guarda la suma total.
    MOV suma,AX

    ; Divide entre 10 para obtener el promedio.
    MOV DX,0
    MOV CX,10
    DIV CX             ; AX = suma / 10

    ; Muestra el resultado en pantalla.
    CALL print_num
    JMP main_loop


; ==============================================================
; OPCIÓN 4: ENCONTRAR EL NÚMERO MAYOR
; ==============================================================
do_mayor:
    ; Comienza suponiendo que el primer número es el mayor.
    MOV AX,[numeros]
    MOV mayor,AX

    MOV CX,9           ; Quedan 9 números por comparar.
    MOV SI,2

.max_loop:
    MOV AX,[numeros+SI]
    CMP AX, mayor
    JLE .nextm          ; Si no es mayor, pasa al siguiente.
    MOV mayor,AX        ; Si sí es mayor, actualiza la variable.
.nextm:
    ADD SI,2
    LOOP .max_loop

    ; Imprime el número mayor encontrado.
    MOV AX, mayor
    CALL print_num
    JMP main_loop


; ==============================================================
; OPCIÓN 5: ENCONTRAR EL NÚMERO MENOR
; ==============================================================
do_menor:
    ; Asume que el primer número es el menor.
    MOV AX,[numeros]
    MOV menor,AX

    MOV CX,9
    MOV SI,2

.min_loop:
    MOV AX,[numeros+SI]
    CMP AX, menor
    JGE .nextn          ; Si no es menor, continúa.
    MOV menor,AX        ; Si es menor, actualiza.
.nextn:
    ADD SI,2
    LOOP .min_loop

    ; Imprime el número menor encontrado.
    MOV AX, menor
    CALL print_num
    JMP main_loop


; ==============================================================
; OPCIÓN 6: SALIR DEL PROGRAMA
; ==============================================================
do_salir:
    ; Interrupción DOS 21h función 4Ch: Finaliza el programa.
    MOV AH,4Ch
    INT 21h


; ==============================================================
; SUBRUTINA: LEER NÚMERO DE 2 DÍGITOS (00–99)
; ==============================================================
; Esta rutina lee exactamente dos caracteres numéricos del teclado.
; Si el usuario escribe letras u otros símbolos, se ignoran.
; Al final, devuelve el número completo (dos dígitos) en AX.
;
; Ejemplo:
;   Usuario ingresa 4 y luego 2 → AX = 42
; ==============================================================
leer_numero PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    XOR BX, BX        ; BL = primer dígito, BH = segundo dígito
    XOR CX, CX        ; contador de dígitos leídos
    XOR DX, DX

.read_loop:
    ; Leer un carácter del teclado
    MOV AH, 01h
    INT 21h

    ; Verificar que sea un número (entre '0' y '9')
    CMP AL, '0'
    JB .read_loop     ; si es menor que '0', ignorar
    CMP AL, '9'
    JA .read_loop     ; si es mayor que '9', ignorar

    ; Convertir de ASCII a número real (restar 30h)
    SUB AL, 30h

    ; Si es el primer dígito, guardarlo en BL.
    CMP CX, 0
    JE .store_first

    ; Si es el segundo dígito, guardarlo en BH.
    MOV BH, AL
    INC CX
    JMP .calc_value

.store_first:
    MOV BL, AL
    INC CX
    JMP .read_loop    ; leer el segundo dígito

.calc_value:
    ; Calcular el número final: (primer_digito * 10) + segundo_digito
    MOV AL, BL
    XOR AH, AH
    MOV CL, 10
    MUL CL            ; AX = BL * 10
    MOV DL, BH
    XOR DH, DH
    ADD AX, DX        ; AX = (BL * 10) + BH

    ; Restaurar registros y salir
    POP SI
    POP DX
    POP CX
    POP BX
    RET
leer_numero ENDP


; ==============================================================
; SUBRUTINA: IMPRIMIR NÚMERO EN AX (EN DECIMAL)
; ==============================================================
; Convierte el valor numérico en AX a caracteres ASCII
; y los muestra en pantalla uno por uno.
; Por ejemplo: AX = 42 → imprime '4' luego '2'
; ==============================================================
print_num PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV CX,0
    CMP AX,0
    JNE p_calc

    ; Si el número es 0, simplemente imprime '0'.
    MOV DL,'0'
    MOV AH,02h
    INT 21h
    JMP p_done

p_calc:
    MOV BX,10
p_conv:
    ; Divide AX entre 10 para extraer los dígitos.
    XOR DX,DX
    DIV BX            ; AX = cociente, DX = residuo (último dígito)
    PUSH DX           ; Guarda el dígito para imprimir después.
    INC CX
    CMP AX,0
    JNE p_conv        ; Repetir hasta que el número se reduzca a 0.

p_print:
    ; Imprime los dígitos en orden correcto.
    POP DX
    ADD DL,30h        ; Convierte número a carácter ASCII.
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

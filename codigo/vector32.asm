.386
.model flat, stdcall
.stack 4096
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

.data
menuMsg db 13,10, "=== MENU VECTOR ===",13,10,
        "1. Ingresar 10 numeros",13,10,
        "2. Mostrar vector",13,10,
        "3. Calcular promedio",13,10,
        "4. Mostrar mayor",13,10,
        "5. Mostrar menor",13,10,
        "6. Salir",13,10,
        "Seleccione opcion: ",0

vector dd 10 dup(0)
msgIngreso db "Ingrese numero: ",0
msgPromedio db "Promedio: %d",13,10,0
msgMayor db "Mayor: %d",13,10,0
msgMenor db "Menor: %d",13,10,0
msgOpcion db "%d",0
msgMostrar db "Vector: ",0
fmtInt db "%d ",0
msgNL db 13,10,0

numIngresados dd 0
opcion dd ?

.code
main PROC
inicio:
    push offset menuMsg
    call crt_printf
    call crt_scanf, offset msgOpcion, offset opcion

    mov eax, opcion
    cmp eax, 1
    je ingresar
    cmp eax, 2
    je mostrar
    cmp eax, 3
    je promedio
    cmp eax, 4
    je mayor
    cmp eax, 5
    je menor
    cmp eax, 6
    je salir
    jmp inicio

ingresar:
    mov ecx, 10
    lea esi, vector
leer:
    push offset msgIngreso
    call crt_printf
    call crt_scanf, offset msgOpcion, esi
    add esi, 4
    loop leer
    jmp inicio

mostrar:
    push offset msgMostrar
    call crt_printf
    lea esi, vector
    mov ecx, 10
mostrar_loop:
    mov eax, [esi]
    push eax
    push offset fmtInt
    call crt_printf
    add esi, 4
    loop mostrar_loop
    push offset msgNL
    call crt_printf
    jmp inicio

promedio:
    xor eax, eax
    lea esi, vector
    mov ecx, 10
suma:
    add eax, [esi]
    add esi, 4
    loop suma
    mov ebx, 10
    cdq
    idiv ebx
    push eax
    push offset msgPromedio
    call crt_printf
    add esp, 8
    jmp inicio

mayor:
    lea esi, vector
    mov eax, [esi]
    mov ecx, 9
sigM:
    add esi, 4
    cmp eax, [esi]
    jge noCamb
    mov eax, [esi]
noCamb:
    loop sigM
    push eax
    push offset msgMayor
    call crt_printf
    add esp, 8
    jmp inicio

menor:
    lea esi, vector
    mov eax, [esi]
    mov ecx, 9
sigm:
    add esi, 4
    cmp eax, [esi]
    jle noC
    mov eax, [esi]
noC:
    loop sigm
    push eax
    push offset msgMenor
    call crt_printf
    add esp, 8
    jmp inicio

salir:
    call ExitProcess, 0
main ENDP

END main

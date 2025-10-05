.model small
.stack 100h
.data
mensaje db 'Hola Mundo!$'

.code
main proc
    mov ax, @data
    mov ds, ax

    mov ah, 9
    lea dx, mensaje
    int 21h

    mov ah, 4Ch
    int 21h
main endp
end main

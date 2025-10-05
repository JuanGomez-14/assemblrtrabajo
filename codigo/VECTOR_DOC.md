# Documentación detallada del programa `vector.asm`

Este documento explica en detalle cada parte del programa `vector.asm` (ensamblador TASM 16‑bit) para que puedas exponerlo al profesor: cómo funciona, qué hacen las rutinas, qué registros usa cada parte, formatos de datos, instrucciones DOS usadas, casos límite y sugerencias de mejora.

## Resumen funcional

Programa interactivo en DOS que permite al usuario:
- Ingresar hasta 10 números (cada uno con hasta 2 dígitos: 0..99).
- Mostrar el contenido del vector (10 posiciones, palabras de 16 bits).
- Calcular y mostrar el promedio (entero) de los 10 valores.
- Mostrar el mayor y el menor valor del vector.
- Salir del programa.

Los datos se almacenan como palabras (DW) en la tabla `numeros` de 10 elementos.

## Estructura del archivo

- Directivas:
  - `.MODEL SMALL` — modelo de memoria pequeño: código y datos en segmentos separados, DS apunta al segmento de datos.
  - `.STACK 100h` — reserva 256 bytes para la pila.
  - `.DATA` — sección de datos (mensajes, variables, vector).
  - `.CODE` — sección de código (rutinas y punto de entrada `start`).
  - `END start` — marca la etiqueta de entrada para el linker.

- Secciones principales:
  - Datos (mensajes y variables): cadenas terminadas en `$` para INT 21h AH=09h.
  - Código: `start`, `main_loop` (menu), rutinas `do_ingresar`, `do_mostrar`, `do_promedio`, `do_mayor`, `do_menor`, `do_salir`, subrutinas auxiliares `leer_numero` y `print_num`.

## Datos y variables (explicación)

- `menu_title`, `menu_o1`..`menu_o6`, `prompt`, `ingreso`, `newline`, `full_msg`:
  - Cadenas ASCII terminadas con `$` (requeridas por INT 21h AH=09h que las imprime hasta `$`).
  - Ej.: `ingreso DB 13,10,'Ingrese numero: $'` — incluye CR+LF antes del texto.

- `numeros DW 10 DUP(0)`:
  - Vector de 10 palabras (cada palabra 16 bits). Inicialmente todos 0.
  - El uso de `DW` implica que cuando accedemos a `numeros+SI` debemos sumar offsets en bytes (cada elemento ocupa 2 bytes).

- `mayor DW 0`, `menor DW 0`, `suma DW 0`:
  - Variables auxiliares para almacenar resultados (se usan como almacenamiento temporal si es necesario).

- `opcion DB 0`:
  - Guarda la opción de menú en un byte.

- `entered_count DB 0`:
  - Contador de entradas efectivamente ingresadas (0..10). Usado para limitar a 10 entradas y para ubicar dónde insertar.

## Registro y convención de uso (qué hace cada registro)

Se usan los registros 16-bit/8-bit clásicos del x86 real-mode. A continuación, una guía sobre su rol en este programa:

- AX (AH/AL): registro de propósito general; AH frecuentemente se usa para seleccionar funciones de INT 21h (ej. AH=09h imprimir cadena, AH=01h leer carácter, AH=02h escribir carácter, AH=4Ch salir). AL se usa para leer el carácter (INT 21h AH=01h devuelve el carácter en AL). AX también se usa para operaciones aritméticas y para pasar el número leído a `print_num`.

- BX: en `leer_numero` se usa como acumulador (word) para construir el número ingresado. En `print_num` se usa como divisor (`MOV BX,10`) y en otras rutinas se respeta su preservación o se guarda/restaura con `PUSH`/`POP`.

- CX: contador (usado por `LOOP` y también como contador de dígitos o bucles en distintas rutinas).

- DX (DL/DH): se usa para pasar la dirección de las cadenas a INT 21h (DX = offset string) y en `print_num`/operaciones de división; DL también se usa para imprimir caracteres (INT 21h AH=02h usa DL).

- SI: índice en bytes para recorrer `numeros` (cada elemento: 2 bytes). Al multiplicar el índice de elemento por 2 (SHL SI,1) se obtiene el desplazamiento por bytes.

- SP/stack: usado por llamadas a procedimientos y preservación de registros (`PUSH`/`POP`).

Convención de preservación: cuando una rutina necesita usar registros que el resto del programa puede necesitar después, generalmente `PUSH` antes y `POP` al regresar para preservar su valor.

## Descripción detallada de las rutinas

A continuación se describe cada rutina con su lógica y notas de implementación.

### start
- Inicializa DS con el segmento de `numeros` (MOV AX, SEG numeros / MOV DS, AX).
- Salta al bucle principal `main_loop`.

### main_loop (menú)
- Imprime las líneas del menú (cada impresión: LEA DX,<cadena> / MOV AH,09h / INT 21h).
- Muestra `prompt` y luego lee una tecla con INT 21h AH=01h (carácter en AL).
- Resta 0x30 al carácter para convertir ASCII digit a su valor numérico: `SUB AL,30h`.
- Guarda la opción en `opcion` y salta a la rutina adecuada según AL (comparaciones con `CMP AL,1`, etc.).
- Observación: el menú espera que el usuario presione una tecla numérica (1..6). No hay validación extendida (si el usuario presiona otra tecla vuelve al menu).

### do_ingresar
- Objetivo: permitir ingresar nuevos números hasta completar 10.
- Lógica clave:
  - Comprueba `entered_count` (byte). Si >=10 muestra `full_msg` y vuelve al menú.
  - Calcula `CX = 10 - entered_count` (cuántos elementos restan por ingresar) para usar como contador de bucle.
  - Calcula `SI = entered_count * 2` (offset en bytes donde empezar a almacenar) usando `SHL SI,1`.
  - Loop: para cada entrada muestra `ingreso`, llama a `leer_numero`, guarda el resultado (word) en `[numeros+SI]`, incrementa SI por 2 e incrementa `entered_count`.
  - Vuelve al `main_loop`.

Notas:
- Guardado: `MOV [numeros+SI], AX` escribe la palabra leída.
- El bucle usa `LOOP` con CX inicializado al número de iteraciones restantes.

### do_mostrar
- Recorre los 10 elementos (SI usado como offset byte, CX=10) y para cada elemento:
  - Lee la palabra con `MOV AX,[numeros+SI]`.
  - Llama a `print_num` (muestra el número en decimal con INT 21h AH=02h por dígito).
  - Imprime `newline`.

### do_promedio
- Suma las 10 palabras en AX acumulando: `ADD AX,[numeros+SI]` y luego divide por 10 (`DIV CX` con `CX=10`).
- Almacena y pasa el resultado a `print_num`.
- Nota: si el vector contiene valores que sumen > 65535 puede haber overflow; en el programa actual asumimos valores pequeños (0..99). Si se quiere robustez hay que usar DX:AX para suma amplia.

### do_mayor / do_menor
- Inicializan `mayor`/`menor` con `numeros[0]` y luego iteran sobre los 9 elementos restantes comparando y actualizando.
- Finalmente mueven el valor a AX y llaman a `print_num`.

### do_salir
- INT 21h AH=4Ch — termina el programa devolviendo el control a DOS.

### leer_numero (subrutina clave)
- Propósito: leer hasta 2 dígitos (0..99) y devolver el valor en AX.
- Mecanismo (versión actual del archivo):
  - Preserva `BX` y `CX` con `PUSH BX / PUSH CX`.
  - Usa `BX` como acumulador (word) e `CX` como contador de dígitos.
  - En cada iteración: lee un carácter (INT 21h AH=01h), si es Enter (CR = 13) termina; si no es dígito lo ignora.
  - Para un dígito válido: convierte `AL` de ASCII a su valor numérico (`SUB AL,30h`) y extiende AH=0 para que AX contenga el valor del dígito.
  - Calcula `BX = BX * 10` usando `BX*8 + BX*2` con desplazamientos (SHL) y suma el dígito: evita usar instrucciones MUL que en algunos entornos han causado problemas de operandos.
  - Acepta máximo 2 dígitos (`CMP CX,2` y sale del loop si llega a 2).
  - Limpia la entrada (consume hasta Enter) para que el siguiente `INT 21h` del menú esté sincronizado.
  - Devuelve el resultado en AX (MOV AX,BX) y restaura registros con `POP` antes de `RET`.

Notas de diseño:
- La rutina devuelve 0 si el usuario simplemente presiona Enter sin teclear dígitos.
- El diseño presume sólo dígitos positivos y no incluye soporte de retroceso (Backspace) — podría añadirse si se desea mejor UX.

### print_num
- Objetivo: imprimir en ASCII un número decimal contenido en AX.
- Algoritmo:
  - Maneja caso AX=0 imprimiendo '0'.
  - Divide repetidamente por 10 para extraer dígitos: usa `DIV BX` con `BX=10`, acumula los restos (los dígitos en orden inverso) en la pila con `PUSH DX` y cuenta los dígitos con CX.
  - Luego saca los restos (`POP DX`) y por cada uno suma 0x30 para convertir a ASCII y llama a INT 21h AH=02h (imprimir char desde DL).
  - Preserva/ restaura los registros usados con `PUSH`/`POP` al inicio/fin.

Limitaciones y supuestos
- Los números son assumedo positivos y de hasta 2 dígitos (0..99). Si se cargan números fuera de ese rango puede haber resultados inesperados.
- La suma en `do_promedio` asume que la suma de los 10 valores cabe en 16 bits. Si los valores se ampliaran (por ejemplo 0..9999) habría overflow; se necesitaría usar DX:AX durante la suma.
- `leer_numero` descarta caracteres no numéricos y no soporta edición (backspace). El buffer es inmediato (carácter a carácter por INT 21h AH=01h).
- El programa se desarrolla para Turbo Assembler (TASM 4.x) en modo real (DOS). Requiere que el archivo .ASM esté guardado sin BOM (ANSI/OEM), porque TASM es sensible a la codificación.

Instrucciones DOS usadas (INT 21h)
- AH=09h, DX=offset cadena terminada en '$' — imprimir cadena.
- AH=01h — leer carácter (sin eco en algunas BIOS; devuelve AL con ASCII). En este programa se usa para leer pulsaciones.
- AH=02h, DL=carácter — imprimir un carácter.
- AH=4Ch — salir del programa (AL = código retorno opcional).

Explicación de instrucciones clave (breve)
- LEA DX, etiqueta — carga en DX el offset dentro del segmento de datos de la cadena.
- MOV reg, valor/reg — copia de registros/valores.
- ADD/ SUB/ CMP — aritmética y comparaciones.
- SHL reg, n — desplazamiento lógico a la izquierda (multiplica por 2^n).
- LOOP etiqueta — decrementa CX y salta si CX != 0 (útil para bucles con CX como contador).
- PUSH/POP — apilar/desapilar para preservar registros o pasar datos temporales.
- INT 21h — llamada al servicio DOS; su comportamiento depende del valor en AH.

Cómo compilar y ejecutar (en tu entorno)
- Guardar el archivo en codificación ANSI/OEM (sin BOM). En VS Code: File → Save With Encoding → "Western (Windows 1252)" o "OEM 437".
- Usar Turbo Assembler y TLINK (o la GUI Turbo Assembler que incluye DOSBox):

  1) Ensamblar:
  ```powershell
  & 'C:\Users\emanu\VSCode Projects\assemblrtrabajo\TASM\TASM.EXE' /ml /z /zi 'C:\Users\emanu\VSCode Projects\assemblrtrabajo\codigo\vector.asm'
  ```

  2) Enlazar:
  ```powershell
  & 'C:\Users\emanu\VSCode Projects\assemblrtrabajo\TASM\TLINK.EXE' 'vector.obj'
  ```

  3) Ejecutar el `.exe` dentro de DOSBox (o desde la GUI TASM que invoca DOSBox).

Notas para la exposición al profesor
- Menciona la estructura de memoria (segmentos DS/CS/SS) y el modelo `SMALL` (datos y stack en un segmento, código en otro). Explica por qué inicializas `DS` con `SEG numeros`.
- Señala decisiones de diseño: por qué almacenar números como `DW` (permanecer en futuro con valores hasta 65535) y por qué limitar la entrada a 2 dígitos (simplificar, evitar overflow en operaciones).
- Explica manejo de IO con INT 21h (funciones 01h,02h,09h,4Ch).
- Indica los puntos de mejora (soporte Backspace, números negativos, validación de entrada, manejo de errores y suma con DX:AX para evitar overflow).

Casos de prueba sugeridos
1. Ingresar 10 números aleatorios (ej. 1, 22, 5, 0, 99, 13, 7, 8, 10, 50) y usar opción mostrar, promedio, mayor y menor; verificar valores manualmente.
2. Presionar Enter sin ingresar dígitos para comprobar que se guarda 0.
3. Intentar ingresar más de 10 números: debe mostrarse `full_msg`.
4. Ingresar caracteres no numéricos entre dígitos: deben ignorarse.

Mejoras propuestas (para hablar en clase)
- Soporte de edición en `leer_numero` (Backspace) y eco de teclado.
- Soporte para números negativos (verificar primer carácter '-' y ajustar acumulador con signo).
- Aumentar límite de dígitos y usar DX:AX para sumar sin overflow.
- Añadir opción en el menú "Borrar vector" para reiniciar `numeros` y `entered_count`.
- Añadir validación más robusta de la opción del menú (aceptar Enter + número multi‑digito, o leer línea completa antes de parsear).

Apéndice: Ejemplo de flujo de ejecución
1. Al iniciar, se muestra el menú.
2. Usuario presiona `1` y Enter — se entra a `do_ingresar`.
3. Se muestran mensajes "Ingrese numero:" repetidamente; para cada entrada se lee hasta 2 dígitos y se guarda en `numeros`.
4. Tras 10 entradas o al seleccionar otra opción del menú, el programa ejecuta las acciones solicitadas (mostrar, promedio, mayor, menor) y vuelve al menú.

---

Si quieres, genero aparte una versión imprimible (PDF) o añado diagramas de flujo simples para las rutinas `leer_numero` y `print_num`. También puedo añadir comentarios inline directamente en `vector.asm` con esta misma explicación para que tu profesor vea las anotaciones en el código.

¿Quieres que añada los comentarios inline en `vector.asm` o que traduzca esta documentación a un PDF listo para imprimir?
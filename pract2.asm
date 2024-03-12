;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Segmento de datos
DATA SEGMENT
	; Matriz a comparar
	V1		DW 1, 0, 0
	V2		DW 0, 1, 0
	V3		DW 0, 0, 1
	
	; Matriz identidad
	I1		DW 1, 0, 0
	I2		DW 0, 1, 0
	I3		DW 0, 0, 1
	
	RESULT	DW (?)
	BUFFER	DB 200 dup ('$'), 13, 10, '$'
DATA ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Segmento de pila
PILA SEGMENT STACK "STACK"
	DB 40H DUP(0); Definimos el tamaño de la pila
PILA ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Segmento extra
EXTRA SEGMENT
	EX DW 0,0
EXTRA ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Segmento de codigo
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:EXTRA, SS:PILA

;_______________________________________________________________________________________;

; Proceso principal.
START PROC
	; Guardamos los segmentos en sus respectivos espacios
	MOV AX, DATA
	MOV DS, AX

	MOV AX, PILA
	MOV SS, AX

	MOV AX, EXTRA
	MOV ES, AX

	; Codigo
	MOV CX, 0			; Inicializamos el contador
	MOV	BX, OFFSET V1	; Offset de la matriz a comparar
	MOV BP, OFFSET I1	; Offser de la matriz identidad

	; Funcion para comprobar si la matriz es identidad
	CHECK_ID:
		CMP cx, 3
		JE IS_ID ; Se mete si ha comparado toda la matriz --> Es identidad
		
		; Reseteamos el contador de la fila
		MOV SI, 0
	
		; Comparamos el primer valor de la fila
		MOV AX, DS:[BX][SI] ; Guardamos el elemento de la matriz
		MOV DX, DS:[BP][SI] ; Guardamos el elemento de la identidad
		CMP AX, DX 			; Comparamos
		JNE NOIS_ID 		; Si no son iguales, no es identidad
		ADD SI, 2
		
		; Comparamos el segundo valor
		MOV AX, DS:[BX][SI]
		MOV DX, DS:[BP][SI]
		CMP AX, DX
		JNE NOIS_ID
		ADD SI, 2
		
		; Comparamos el tercer valor
		MOV AX, DS:[BX][SI]
		MOV DX, DS:[BP][SI]
		CMP AX, DX
		JNE NOIS_ID
	
		; Sumamos a los offsets de la siguiente iteracion
		INC CX
		ADD BX, 6	; Sumamos 6 porque cada numero ocupa 2 bytes --> 2 * 3 = 6
		ADD BP, 6
		JMP CHECK_ID
	
	; Es identidad
	IS_ID:
		MOV RESULT, "IS"
		JMP PRINT_NUMBER

	; No es identidad
	NOIS_ID:
		MOV RESULT, "ON"
		JMP PRINT_NUMBER

	; Funcion para guardar todos los numeros de la matriz en texto
	PRINT_NUMBER:
		; Inicializamos contadores para poder iterar
		MOV CX, 0			; Inicializamos el contador
		MOV	BP, OFFSET V1	; Offset de la matriz a comparar
		MOV DI, 0
		
		; Bucle donde vamos guardando cada numero
		WHILE_MATRIX:
			MOV SI, 0	; Reseteamos el indice de los elementos de la fila
			CMP cx, 3
			JE END_PROG
		
			; Añadimos una '|' (7Ch - 124d) al principio, junto a un espacio (20h)
			MOV BL, 7Ch
			MOV DS:BUFFER[DI], BL
			MOV DS:BUFFER[DI + 1], 20H
			ADD DI, 2
		
			; Guardamos el primer numero de la fila
			MOV BX, DS:[BP][SI]	; Guardamos el numero en BX
			CALL ADD_TEXT		; Llamamos a la funcion que nos guarda el numero
			ADD SI, 2			; Incrementamos el indice de la fila
		
			; Guardamos el segundo numero de la fila
			MOV BX, DS:[BP][SI]
			CALL ADD_TEXT
			ADD SI, 2
		
			; Guardamos el tercer numero de la fila
			MOV BX, DS:[BP][SI]
			CALL ADD_TEXT
		
			; Añadimos la '|' (7CH) final 
			MOV BL, 7Ch
			MOV DS:BUFFER[DI], BL
			INC DI
		
			; Si estamos en la fila del medio, imprimimos el resultado
			CMP CX, 1
			JE PRINT_RESULT
	
		POST_RESULT:
			; Imprimimos el salto de linea (0AH)
			MOV BL, 0Ah
			MOV DS:BUFFER[DI], BL
			INC DI
		
			; Aumentamos los contadores
			ADD BP, 6			; Incrementamos el valor para apuntar a la siguiente fila
			INC CX				; Aumentamos el contador de filas leidas
			JMP WHILE_MATRIX
	
	
	; Imprimimos el valor de la variable 'RESULT', que nos dice si la matriz era o no identidad
	PRINT_RESULT:
		; Movemos el ersultado (SI/NO) al final del mensaje de identidad --> caracter 16
		MOV BX, RESULT
		MOV BUFFER[DI], 20H
		MOV BUFFER[DI + 1], BL
		MOV BUFFER[DI + 2], BH
		ADD DI, 3
		JMP POST_RESULT

	; Finalizamos el programa
	END_PROG:
		; MAL:
			;CARGAMOS en DX el segmento y en AX el offset de la variable para despues imprimir
			; MOV DX, SEG		BUFFER
			; MOV AX, OFFSET	BUFFER
		; BIEN:
			; Guardamos la info para despues imprimir por pantalla
			MOV DX, OFFSET BUFFER	; Puntero a donde empieza la cadena
			MOV AH, 9				; Acción para que escriba por pantalla
		INT 21H			; Interrupcion 
		MOV AX, 4C00H	; Valor para expresar que vamos a terminar el programa
		INT 21H			; Interrupción

START ENDP

;_______________________________________________________________________________________;

; Proceso para guardar un numero en una variable en formato ASCII
;		Recibimos el numero en el registro BX
ADD_TEXT PROC
	ADD BX, 30H					; Le sumamos 30H ('0') para convertirlo a ASCII
	MOV DS:BUFFER[DI], BL		; Guardamos el caracter en el siguiente espacio disponible
	MOV	DS:BUFFER[DI + 1], 20H	; Ponemos un espacio
	ADD DI, 2					; Sumamos e1 al índice que lleva la cuenta del ultimo caracter copiado

	RET							; Volvemos al proceso principal, con los cambios efectuados
ADD_TEXT ENDP

;_______________________________________________________________________________________;

CODE ENDS
END START


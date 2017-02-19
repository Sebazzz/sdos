bits 32

WHITE_ON_BLUE EQU 17H

global putchr
global looper
 
    nop
	nop
	nop
	xor eax, eax
	nop
	nop

putchr:
	; remember: al = character (first arg), cx = repeat (second arg)
	push ebp
	mov ebp, esp
	
	mov eax, [ebp + 8] ; First arg
	and eax, 0xFF      ; Only interested in lower 8 bytes (8-bit al register)
	mov cx, [ebp + 12] ; Second arg
	call PutChar
	
	pop ebp
	ret
	
looper:
	rst:
	xor eax, eax
	jmp rst
	ret

%include "../io.incl.asm"

cursor_X db 0
cursor_Y db 0


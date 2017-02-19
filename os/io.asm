bits 16

WHITE_ON_BLUE EQU 17H
STACK_PTR EQU 0x9000

extern kmain
global putchr
global kinit
global done

kinit:
	; Cursor position passed in ax,cx
	mov [cursor_X], ax
	mov [cursor_Y], cx
	
	; Set up stack pointer since we will not return to the bootloader
	mov sp, STACK_PTR
	mov bp, STACK_PTR
	
	push bp
	mov bp, sp
	push ax
	push cx
	call kmain
	pop bp
	
	call done
	hlt

putchr:
	; remember: al = character (first arg), cx = repeat (second arg)
	push bp
	mov bp, sp
	
	mov ax, [bp + 8] ; First arg
	and ax, 0xFF      ; Only interested in lower 8 bytes (8-bit al register)
	mov cx, [bp + 12] ; Second arg
	call PutChar
	
	pop bp
	ret
	
done:
	call PrintEndMsg
	hlt

; Print end message
PrintEndMsg:
	; Print
	mov si, endMsg
	call PrintLn
	ret

%include "../io.incl.asm"

cursor_X db 0
cursor_Y db 0

endMsg db "@@ System execution completed - system shutdown", 0
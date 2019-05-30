; keyboard.asm
; Keyboard control routines

[bits 32]

%include "../hwport.incl.asm"

section .text

; get_scancode
; Get a single scan code from the keyboard
;
; Input: nothing
; Output: char
global get_scancode
get_scancode: 
.loop:
	in al, KDB_PS2_ADDR			; store key code in eax
	cmp al, 0xFE
	jz .loop 			; Essentially, keep looping until found
	in al, KDB_PS2_ADDR
	
	; SystemV calling convention expects return value in eax
	movzx eax, byte al
	ret
	
; keyboard_handler
; Record the latest keyboard scan code
;

global keyboard_handler
keyboard_handler:
	xor eax, eax
	in al, KDB_PS2_ADDR
	mov [last_scancode],eax
	ret

section .data

last_scancode:
dd 0x0
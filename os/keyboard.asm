; keyboard.asm
; Keyboard control routines

[bits 32]

section .text
global get_scancode

; get_scancode
; Get a single scan code from the keyboard
;
; Input: nothing
; Output: char
get_scancode: 
.loop:
	in al, 0x60			; store key code in eax
	cmp al, 0xFE
	jz .loop 			; Essentially, keep looping until found
	in al, 0x60
	
	; SystemV calling convention expects return value in eax
	movzx eax, byte al
	ret

section .data

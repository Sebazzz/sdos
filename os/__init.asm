; _init.asm
; jump to kinit
[bits 32]

__init:
	extern kinit
	jmp kinit
	nop
	nop
	nop
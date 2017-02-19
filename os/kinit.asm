; kinit.asm
;
; set-up of 32-bit protected mode

bits 16

global kinit
extern kmain

kinit:
	nop
	cli				;disable interrupts
	lgdt [gdt_info]		; load GDT register
	mov eax, cr0
	or al, 1		; Protection Enable
	mov cr0, eax	
	jmp 08h:kinit_core

; kinit_core: 32-bit protected mode procedure

kinit_core:
	jmp kmain

gdt_start:
	nop

gdt_info:
	dw gdt_info - gdt_start - 1
	dq gdt_start
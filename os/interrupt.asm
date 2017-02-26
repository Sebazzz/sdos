; interrupt.asm
; 
; Sets up the interrupt table and contains common interrupt handlers

[bits 32]
%include "../macro.incl.asm"

IDT_BASE_HIGH_OFFSET EQU 6

extern vid_clear
extern vid_set_attribute
extern vid_print_string

; init_interrupt
; Set up the interrupt table and enables interrupts

global init_interrupt

init_interrupt:
	mov eax, idt
	
	; set-up exception handler
	mov edx, exception_handler
	mov [ex_low], dx
	
	shr edx, 16
	mov [ex_high], dx
	
	mov [ex_seg], cs
	
	; load table
	lidt [idt_desc]
	
	;sti					; Enable interrupts
	ret

global exception_handler
exception_handler:
	cli
	pushad
	
	; Create clean RSOD
	push 0x4E	; Red bg, yellow fg
	call vid_set_attribute
	clear_stack_ns(1)
	
	call vid_clear
	
	; Write error message
	push exMsg
	call vid_print_string
	clear_stack_ns(1)
	
	; Put system in permanent halt state
	popad
.resume:
	hlt
	jmp .resume
	iret

section .data

idt:
ex_low dw 0xFFFF			; base (lower bits)
ex_seg dw 0x0008			; segment
db 0x00				; unused
db 0b1000_1111		; type
ex_high dw 0xFFFF			; base (higher bits)

idt_end: 					; Used to calculate the size of the GDT
idt_desc: 					; The GDT descriptor 
	dw idt_end - idt - 1 	; Limit (size) 
	dd idt 					; Address of the GDT

section .rodata
exMsg db "@@ System execution error - CPU exception", 0
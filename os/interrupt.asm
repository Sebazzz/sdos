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
	push 0x0
	push 0xF
	push exception_handler
	call install_interrupt_handler
	clear_stack_ns(3)
	
	; load table
	lidt [idt_desc]
	
	sti					; Enable interrupts
	ret

; install_interrupt_handler
; Installs an interrupt handler for the specified interrupt type
;
; Input: vector (char)
;		 type (char) 0x5=task_gate, 0xE = interrupt_gate, 0xF=trap_gate
;		 handler (void *)
;
; Output: Nothing
;
; Registers touched: edx, eax
global install_interrupt_handler
install_interrupt_handler:
	; We need to calculate the initial offset
	mov eax, IDT_HANDLER_SIZE
	mul byte param_ns(2)
	add eax, idt
	
	mov edx, param_ns(0)						; handler
	mov [eax + IDT_HANDLER_LOW_OFFSET], dx		; set handler low offset
	shr edx, 16									; get high offset
	mov [eax + IDT_HANDLER_HIGH_OFFSET], dx		; set handler low offset
	
	mov dl, param_ns(1)							; type
	or dl, 0b1000_0000							; set as actived
	mov [eax + IDT_HANDLER_TYPE_OFFSET], dl		; set type
	
	mov [eax + IDT_SEG_OFFSET], cs				; set segment
	
	ret

; uninstall_interrupt_handler
; Uninstalls / deactivates an interrupt handler for the specified interrupt type
;
; Input: vector (char)
; Output: Nothing
;
; Registers touched: edx, eax
global uninstall_interrupt_handler
uninstall_interrupt_handler:
	; We need to calculate the initial offset
	mov eax, IDT_HANDLER_SIZE
	mul byte param_ns(2)
	add eax, idt
	
	mov dl, [eax + IDT_HANDLER_TYPE_OFFSET]		; get type
	and dl, 0b0111_1111							; set P flag off
	mov [eax + IDT_HANDLER_TYPE_OFFSET], dl		; set type
	
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
	IDT_HANDLER_LOW_OFFSET equ $-idt
ex_low: dw 0xFFFF			; base (lower bits)
	IDT_SEG_OFFSET equ $-idt
ex_seg: dw 0x0008			; segment
db 0x00				; unused
	IDT_HANDLER_TYPE_OFFSET equ $-idt
db 0b1000_1111		; type
	IDT_HANDLER_HIGH_OFFSET equ $-idt
ex_high: dw 0xFFFF			; base (higher bits)
	IDT_HANDLER_SIZE equ $-idt

;%rep 255
;dw 0x0000 ; handler low
;dw 0x0008 ; segment
;db 0x00 ; unused
;db 0b0000_1111 ; type
;dw 0x0000	   ; handler (high)
;%endrep

idt_end: 					; Used to calculate the size of the GDT
idt_desc: 					; The GDT descriptor 
	dw idt_end - idt - 1 	; Limit (size) 
	dd idt 					; Address of the GDT

section .rodata
exMsg db "@@ System execution error - CPU exception", 0
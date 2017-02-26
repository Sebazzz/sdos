; interrupt.asm
; 
; Sets up the interrupt table and contains common interrupt handlers

[bits 32]
%include "../macro.incl.asm"

IDT_BASE_HIGH_OFFSET EQU 6

extern vid_clear
extern vid_set_attribute
extern vid_print_string_line
extern vid_advance_line

; macro: set_trap_handler
; Installs a trap interrupt handler
;
; Parameters: 1=vector, 2=handler
%macro set_trap_handler 2
	push %1
	push 0xF
	push %2
	call install_interrupt_handler
	clear_stack_ns(3)
%endmacro

; init_interrupt
; Set up the interrupt table and enables interrupts
global init_interrupt
init_interrupt:
	mov eax, idt
	
	; set-up exception handler for:
	set_trap_handler 0x0, divide_by_zero_handler		; divide by zero
	set_trap_handler 0xB, segment_np_handler			; segment not present
	;set_trap_handler 0xC, segment_overflow_handler		; stack segment fault
	;set_trap_handler 0xD, gp_fault_handler				; general protection fault
	;set_trap_handler 0x1E, security_exception_handler	; security exception (??)
	
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

; internal macro: create_exception_handler
; Creates an exception handler which prints the specified message
;
; Parameters: 1=name, 2=message
%macro create_trap_handler 2
	global %1
	%1:
		cli
		pushad
		
		; Create clean RSOD
		push 0x4E	; Red bg, yellow fg
		call vid_set_attribute
		clear_stack_ns(1)
		
		call vid_clear
		
		; Write generic error message
		push exMsg
		call vid_print_string_line
		clear_stack_ns(1)
		
		call vid_advance_line
		
		; Write specific error message
		push %2
		call vid_print_string_line
		clear_stack_ns(1)
		
		; Put system in permanent halt state
		popad
	.resume:
		hlt
		jmp .resume
		iret
%endmacro

create_trap_handler divide_by_zero_handler, exDivideMsg
create_trap_handler segment_np_handler, exSegmentMsg
;create_trap_handler segment_overflow_handler, exStSegOverflowMsg
;create_trap_handler gp_fault_handler, exGpFaultMsg
;create_trap_handler security_exception_handler, exSecurityExMsg

section .data

idt:
	IDT_HANDLER_LOW_OFFSET equ $-idt
dw 0xFFFF			; base (lower bits)
	IDT_SEG_OFFSET equ $-idt
dw 0x0008			; segment
db 0x00				; unused
	IDT_HANDLER_TYPE_OFFSET equ $-idt
db 0b1000_1111		; type
	IDT_HANDLER_HIGH_OFFSET equ $-idt
dw 0xFFFF			; base (higher bits)
	IDT_HANDLER_SIZE equ $-idt

%rep 13
dw 0xDEAD		; handler low
dw 0xBEEF		; segment
db 0x00			; unused
db 0x0F 		; type
dw 0xCAFE		; handler (high)
%endrep

idt_end: 					; Used to calculate the size of the GDT
idt_desc: 					; The GDT descriptor 
	dw idt_end - idt - 1 	; Limit (size) 
	dd idt 					; Address of the GDT

section .rodata
exMsg db "@@ System execution error - CPU exception", 0
exDivideMsg db "Divide by zero", 0
exSegmentMsg db "Segment not present", 0
;exStSegOverflowMsg db "Stack Segment Overflow", 0
;exGpFaultMsg db "General Protection Fault", 0
;exSecurityExMsg db "Security Exception", 0
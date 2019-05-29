; interrupt.asm
; 
; Sets up the interrupt table and contains common interrupt handlers

[bits 32]
%include "../macro.incl.asm"
%include "../hwport.incl.asm"

IDT_BASE_HIGH_OFFSET EQU 6

INTERRUPT_TASK_GATE EQU 0x5
INTERRUPT_IRQ_GATE EQU 0xE
INTERRUPT_TRAP_GATE EQU 0xF

ICW1_DISABLE EQU 0xFF ; Interrupt command word: initialization
ICW1_ICW4 EQU 0x01 ; Interrupt command word: ICW4 (not) needed
ICW1_SINGLE EQU 0x02 ; Interrupt command word: Single (cascade) mode
ICW1_INTERVAL4 EQU 0x04 ; Interrupt command word: Call address interval 4 (8)
ICW1_LEVEL EQU 0x08 ; Interrupt command word: Level triggered (edge) mode
ICW1_INIT EQU 0x10 ; Interrupt command word: Initialization - required!

ICW4_8086 EQU 0x01 ; Interrupt command word: 8086/88 (MCS-80/85) mode

PIC_IRQ0_OFFSET EQU 0x20
PIC_IRQ8_OFFSET EQU 0x28
PIC_EOI EQU 0x20

RTC_IRQ EQU PIC_IRQ8_OFFSET

extern vid_clear
extern vid_set_attribute
extern vid_print_string
extern vid_print_string_line
extern vid_advance_line

; macro: set_trap_handler
; Installs a trap interrupt handler
;
; Parameters: 1=vector, 2=handler
%macro set_trap_handler 2
	push %1
	push INTERRUPT_TRAP_GATE
	push %2
	call install_interrupt_handler
	clear_stack_ns(3)
%endmacro

; macro: set_irq_handler
; Installs a IRQ interrupt handler
;
; Parameters: 1=vector, 2=handler
%macro set_irq_handler 2
	push %1
	push INTERRUPT_IRQ_GATE
	push %2
	call install_interrupt_handler
	clear_stack_ns(3)
%endmacro

; macro: issue_end_of_interrupt
; Issue an "end of interrupt" to the PIC
;
; Parameters: 1=IRQ number
%macro issue_end_of_interrupt 1
push eax
mov eax, PIC_EOI
%if %1>=8
out PIC2_COMMAND, al
%endif
out PIC1_COMMAND, al
pop eax
%endmacro

; nmi_enable
; Enable non-maskable interrupt
global nmi_enable
nmi_enable:
	; Use eax as scratch register
	push eax
	
	in eax, RTC_ADDR
	and eax, 0x7F
	out RTC_ADDR, eax
	
	pop eax
	ret

; nmi_enable
; Disable non-maskable interrupt
global nmi_disable
nmi_disable:
	; Use eax as scratch register
	push eax
	
	in eax, RTC_ADDR
	or eax, 0x80
	out RTC_ADDR, eax
	
	pop eax
	ret

; init_interrupt
; Set up the interrupt table and enables interrupts
global init_interrupt
init_interrupt:
	call setup_pic
	
	; set-up exception handler for:
	set_trap_handler 0x0, divide_by_zero_handler		; divide by zero
	set_trap_handler 0x8, double_fault_handler			; double fault
	set_trap_handler 0xB, segment_np_handler			; segment not present
	set_trap_handler 0xC, segment_overflow_handler		; stack segment fault
	set_trap_handler 0xD, gp_fault_handler				; general protection fault
	set_trap_handler 0x1E, security_exception_handler	; security exception (??)
	
	; set-up interrupt handler for:
	;set_irq_handler 0x8, irq_rtc_handler				; IRQ 8, RTC
	;set_irq_handler PIC_IRQ0_OFFSET, irq_rtc_handler				; IRQ 8, RTC
	set_irq_handler RTC_IRQ, irq_rtc_handler				; IRQ 8, RTC
	
	; load table
	lidt [idt_desc]
	
	mov eax, 0x8
	push eax
	call pic_enable_interrupt
	pop eax
	
	sti					; Enable interrupts
	ret

; setup_pic
; Internal routine to set-up the pic so it won't trigger IRQ
; on reserved interrupt IDs (0-7), but above (higher than 0x1F)
setup_pic:
	; Start init sequence
		
	mov al, ICW1_INIT
	or al, ICW1_ICW4
	
	out PIC1_COMMAND, al ; starts the initialization sequence (in cascade mode)
	io_wait
	
	out PIC2_COMMAND, al
	io_wait
	
	mov al, PIC_IRQ0_OFFSET
	out PIC1_DATA, al ; ICW2: Master PIC vector offset
	io_wait
	
	mov al, PIC_IRQ8_OFFSET
	out PIC2_DATA, al ; ICW2: Slave PIC vector offset
	io_wait
	
	mov al, 0x4
	out PIC1_DATA, al ; ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
	io_wait
	
	mov al, 0x2
	out PIC2_DATA, al ; ICW3: tell Slave PIC its cascade identity (0000 0010)
	io_wait
	
	mov al, ICW4_8086
	out PIC1_DATA, al
	io_wait
	
	mov al, ICW4_8086
	out PIC1_DATA, al
	io_wait
	
	; disable IRQs
	mov al, 0x00
	out PIC1_DATA, al
	out PIC2_DATA, al
	
	; enable IRQ2
	mov eax, 0x2
	push eax
	call pic_enable_interrupt
	pop eax

	ret

; pic_enable_interrupt: Enable interrupt number on the PIC
; pic_disable_interrupt: Disable interrupt number on the PIC
; 
; Input: interrupt number (char)
; Output: Nothing
;	
PIC2_INTERRUPT_OFFSET EQU 8
pic_disable_interrupt:
	mov edx, PIC1_DATA
	mov eax, param_ns(0)
	
	cmp eax, PIC2_INTERRUPT_OFFSET
	jb .output_data
	
	; if interrupt >= 8, choose PIC 2
	mov edx, PIC2_DATA
	sub eax, PIC2_INTERRUPT_OFFSET
	
	.output_data:
	mov ecx, eax
	in al, dx	; get interrupt mask
	bts eax, ecx
	out dx, al  ; write register
	
	ret
	
pic_enable_interrupt:
	mov edx, PIC1_DATA
	mov eax, param_ns(0)
	
	cmp eax, PIC2_INTERRUPT_OFFSET
	jb .output_data
	
	; if interrupt >= 8, choose PIC 2
	mov edx, PIC2_DATA
	sub eax, PIC2_INTERRUPT_OFFSET
	
	.output_data:
	mov ecx, eax
	in al, dx	; get interrupt mask
	btr eax, ecx
	out dx, al  ; write register
	
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
	or dl, 0b1000_0000							; set as active
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

; internal macro: create_halt_trap_handler
; Creates an exception handler which prints the specified message and halts the system
;
; Parameters: 1=message
%macro create_halt_trap_handler 1
	cli	; Stop disturbing
	pushad
	
	; Create clean RSOD
	push 0x4E	; Red bg, yellow fg
	call vid_set_attribute
	clear_stack_ns(1)
	
	call vid_clear
	
	; Write generic error message
	push exMsgHeader
	call vid_print_string_line
	clear_stack_ns(1)
	
	call vid_advance_line
	
	push exMsg
	call vid_print_string_line
	clear_stack_ns(1)
	
	call vid_advance_line
	
	; Write specific error message
	push %1
	call vid_print_string
	clear_stack_ns(1)
	
	; Put system in permanent halt state
	popad
.resume:
	hlt
	jmp .resume
	iret
%endmacro

; internal macro: create_cont_trap_handler
; Creates an exception handler which prints the specified message and continues the system
;
; Parameters: 1=message
%macro create_cont_trap_handler 1
	cli	; Stop disturbing for duration of interrupt
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
	push %1
	call vid_print_string
	clear_stack_ns(1)
	
	; Resume
	popad
	sti
	clear_stack_ns(1)
	iret
%endmacro

; Below CPU exception handlers are auto-generated by the macros above.
; For debugging purposes, they all start with a dummy instruction so
; GDB can properly attach to that
global divide_by_zero_handler
divide_by_zero_handler:
mov eax, eax
create_halt_trap_handler exDivideMsg

global segment_np_handler
segment_np_handler:
mov eax, eax
create_halt_trap_handler exSegmentMsg

global double_fault_handler
double_fault_handler:
mov eax, eax
create_halt_trap_handler exDfMsg

global segment_overflow_handler
segment_overflow_handler:
mov eax, eax
create_halt_trap_handler exStSegOverflowMsg

global gp_fault_handler
gp_fault_handler:
mov eax, eax
create_halt_trap_handler exGpFaultMsg

global security_exception_handler
security_exception_handler:
mov eax, eax
create_halt_trap_handler exSecurityExMsg

; irq_rtc_handler
; Handler for IRQ 8 interrupts
;
irq_rtc_handler:
	cli
	
	pushad
	
	; Call actual handler
	extern ktime_ontick
	call ktime_ontick 
	
	; Acknowledge interrupt, or it won't fire again
	push eax
	mov al, 0x0C
	out RTC_ADDR, al ; register C
	in al, CMOS_ADDR ; read, but discard
	pop eax
	
	issue_end_of_interrupt 8
	
	popad
	
	sti
	iret

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

%rep 255
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
exDivideMsg db "Divide by zero or result too large", 0
exDfMsg db "Double fault", 0
exSegmentMsg db "Segment not present", 0
exStSegOverflowMsg db "Stack Segment Overflow", 0
exGpFaultMsg db "General Protection Fault", 0
exSecurityExMsg db "Security Exception", 0
exMsgHeader db "                 .               ", 0xA, "                 .               ", 0xA, "                 .       :       ", 0xA, "                 :      .        ", 0xA, "        :..   :  : :  .          ", 0xA, "           ..  ; :: .            ", 0xA, "              ... .. :..         ", 0xA, "             ::: :...            ", 0xA, "         ::.:.:...;; .....       ", 0xA, "      :..     .;.. :;     ..     ", 0xA, "            . :. .  ;.           ", 0xA, "             .: ;;: ;.           ", 0xA, "            :; .BRRRV;           ", 0xA, "               YB BMMMBR         ", 0xA, "              ;BVIMMMMMt         ", 0xA, "        .=YRBBBMMMMMMMB          ", 0xA, "      =RMMMMMMMMMMMMMM;          ", 0xA, "    ;BMMR=VMMMMMMMMMMMV.         ", 0xA, "   tMMR::VMMMMMMMMMMMMMB:        ", 0xA, "  tMMt ;BMMMMMMMMMMMMMMMB.       ", 0xA, " ;MMY ;MMMMMMMMMMMMMMMMMMV       ", 0xA, " XMB .BMMMMMMMMMMMMMMMMMMM:      ", 0xA, " BMI +MMMMMMMMMMMMMMMMMMMMi      ", 0xA, ".MM= XMMMMMMMMMMMMMMMMMMMMY      ", 0xA, " BMt YMMMMMMMMMMMMMMMMMMMMi      ", 0xA, " VMB +MMMMMMMMMMMMMMMMMMMM:      ", 0xA, " ;MM+ BMMMMMMMMMMMMMMMMMMR       ", 0xA, "  tMBVBMMMMMMMMMMMMMMMMMB.       ", 0xA, "   tMMMMMMMMMMMMMMMMMMMB:        ", 0xA, "    ;BMMMMMMMMMMMMMMMMY          ", 0xA, "      +BMMMMMMMMMMMBY:           ", 0xA, "        :+YRBBBRVt;", 0
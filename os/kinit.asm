; kinit.asm
;
; Kernel initialization and post-shutdown handling.

[bits 32]
%include "../macro.incl.asm"

YELLOW_ON_BLACK EQU 00001110b
STACK_SZ EQU 16384 ; 16 KiB

section .bss
align 0x4

stack_bottom:
resb STACK_SZ
stack_top:

section .text
global kinit
global kexec_done

global sleep_ticks
global sleep

extern vid_clear
extern vid_print_string
extern vid_set_attribute

; Print end message
print_halt_message:
	; Clear screen
	push dword YELLOW_ON_BLACK
	call vid_set_attribute
	clear_stack_ns(1)
	
	call vid_clear
	
	push endMsg
	call vid_print_string
	clear_stack_ns(1)
	
	ret

kinit:
	nop
	
	;call vid_clear
	
	nop
	
	; The bootloader has loaded us into 32-bit protected mode on a x86
	; machine. Interrupts are disabled. Paging is disabled. The kernel has full
	; control of the CPU. The kernel can only make use of hardware features
	; and any code it provides as part of itself. There are no security restrictions, no
	; safeguards, no debugging mechanisms, only what the kernel provides itself. 
	; It has absolute and complete power over the machine.
	
	; To set up a stack, we set the esp register to point to the top of our
	; stack (as it grows downwards on x86 systems). This is necessarily done
	; in assembly as languages such as C cannot function without a stack.
	mov esp, stack_top
	mov ebp, esp
	
	nop
	nop
	nop
	
	extern init_interrupt
	call init_interrupt
	
	nop
	
	;; Trigger exception for test
	mov eax, 0
	div eax
	
	nop
	nop
	nop
	
	extern kmain
	call kmain
	
	nop
	nop
	nop

	jmp kexec_done
	hlt

	
kexec_done:
	cli
	call print_halt_message
	
.done:
	hlt
	jmp .done

; sleep
; sleep_ticks
; Sleeps for a number of ticks (DOES NOT WORK YET ACCURATELY)
;
; Input: unsigned int ticks
; Output: nothing
sleep:
sleep_ticks:
	mov eax, 100000
	mul dword param_ns(0)
	pause
.loop:
	dec eax
	cmp eax, 0x0
	pause
	jne .loop
	ret

end:

section .rodata
endMsg db "@@ System execution completed - system shutdown", 0
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
	
	call kexec_verify_architecture
	
	nop
	
	call vid_clear
	
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
	
	extern kmain
	call kmain
	
	nop
	nop
	nop

	jmp kexec_done
	hlt

kexec_verify_architecture:
	; Write verify message
	push verifyMsg
	call vid_print_string
	clear_stack_ns(1)
	
	; Check CPUID - bit 29 contains the "long-jump supported" flag
	mov eax, 0x80000001
	cpuid
	test edx, 0b00100000000000000000000000000000
	jz .done
	
	; Oops, fall through. CPU does not support x64
	; ... Clear screen
	push dword YELLOW_ON_BLACK
	call vid_set_attribute
	clear_stack_ns(1)
	
	call vid_clear
	
	; ... Bad papa
	push verifyFailedMsg
	call vid_print_string
	clear_stack_ns(1)
	
	jmp kexec_done_halt
	
.done:
	push endMsg
	call verifySuccessMsg
	clear_stack_ns(1)
	
	ret

kexec_done:
	cli
	call print_halt_message
kexec_done_halt:
	
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
	nop
	mov eax, 100000
	mul dword param_ns(0)
.loop:
	dec eax
	cmp eax, 0x0
	jne .loop
	ret

end:

section .rodata
endMsg db "@@ System execution completed - system shutdown", 0
verifyMsg db "Verifying architecture...", 0
verifyFailedMsg db "... invalid architecture: does not support x64 (long mode)", 0
verifySuccessMsg db "... success", 0
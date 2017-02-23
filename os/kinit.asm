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
extern vid_clear
extern vid_print_string
extern vid_set_attribute

; Print end message
print_halt_message:
	; Clear screen
	push dword YELLOW_ON_BLACK
	call vid_set_attribute
	pop eax ; we don't care
	
	call vid_clear
	
	push endMsg
	call vid_print_string
	pop eax ; we don't care
	
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
	
	extern kmain
	;call kmain
	
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
end:

endMsg db "@@ System execution completed - system shutdown", 0
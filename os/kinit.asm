bits 32

STACK_SZ EQU 16384 ; 16 KiB

section .bss
align 0x4

stack_bottom:
resb STACK_SZ
stack_top:

section .text
global kinit
extern vid_clear

; Print end message
PrintEndMsg:
	; Print
	mov si, endMsg
	;call PrintLn
	ret

kinit:
	nop
	nop
	nop
	
	call vid_clear
	
	; The bootloader has loaded us into 32-bit protected mode on a x86
	; machine. Interrupts are disabled. Paging is disabled. The kernel has full
	; control of the CPU. The kernel can only make use of hardware features
	; and any code it provides as part of itself. There are no security restrictions, no
	; safeguards, no debugging mechanisms, only what the kernel provides
	; itself. It has absolute and complete power over the machine.
	; To set up a stack, we set the esp register to point to the top of our
	; stack (as it grows downwards on x86 systems). This is necessarily done
	; in assembly as languages such as C cannot function without a stack.
	mov esp, [stack_top]
	mov ebp, esp
	
	nop
	nop
	nop
	
	extern kmain
	call kmain
	
	nop
	nop
	nop

	jmp done
	hlt

putchr:
	push ebp
	
	mov eax, [ebp + 8] ; First arg
	and ax, 0xFF      ; Only interested in lower 8 bytes (8-bit al register)
	mov ecx, [ebp + 12] ; Second arg
	
	;call PutChar
	
	pop ebp
	ret
	
done:
	cli
	call PrintEndMsg
	
.done:
	hlt
	jmp .done
end:

cursor_X db 0
cursor_Y db 0

endMsg db "@@ System execution completed - system shutdown", 0
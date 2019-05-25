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
extern vid_print_string_line
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
	
	call kexec_verify_architecture
	
	nop
	
	extern kinit_init_timer
	call kinit_init_timer
	
	nop
	
	nop
	nop
	nop
	
	extern init_interrupt
	call init_interrupt
	
	nop
	
	extern kinit_enable_timer
	call kinit_enable_timer
	
	nop
	
	extern kmain
	call kmain
	
	nop
	nop
	nop

	jmp kexec_done
	hlt

EFLAGS_ID_BIT EQU 0x00200000
CPUID_GETVENDORSTRING EQU 0x0
CPUID_GET_FEATURESEX EQU 0x80000001
CPUID_FEAT_LONGMODE EQU 0b00100000000000000000000000000000

kexec_verify_architecture:
	; Write verify message
	push verifyMsg
	call vid_print_string_line
	clear_stack_ns(1)
	
.check_cpuid_support:
	; Verify CPUID support
	pushfd
	pushfd
	xor dword [esp], EFLAGS_ID_BIT ; Attempt to write ID bit
	popfd
	pushfd
	pop eax ; Possibly modified EFLAGS
	xor eax,[esp] ; Bits that were changed
	popfd ;Restore original flags
	test eax, EFLAGS_ID_BIT
	jnz .print_vendor_string ; if zero, no cpuid support
	
	; Fall-through
	mov eax, verifyUnknownMsg
	jmp kexec_verify_architecture_failed
	
.print_vendor_string:
	; Get the CPU vendor string
	mov eax, CPUID_GETVENDORSTRING
	cpuid
	push dword 0x0 ; zero-terminate
	push ecx
	push edx
	push ebx
	lea eax, [esp] ; Note that in reverse order the string is read, so we start at esp
	push eax; argument for vid_print_string_line
	
	call vid_print_string_line
	
	clear_stack_ns(5) ; 4 pushes, 1 pointer push(eax)
	
	jmp .check_long_mode_support
	jmp .done
	
.check_long_mode_support:
	; Check CPUID - bit 29 contains the "long-jump supported" flag
	; Ref: https://support.amd.com/TechDocs/24594.pdf page 71, chapter 3, table 3-1
	mov eax, CPUID_GET_FEATURESEX
	cpuid
	test edx, CPUID_FEAT_LONGMODE
	jnz .done ; if zero, no long jump support
	
	; Oops, fall through. CPU does not support x64
	mov eax, verifyFailedMsg
	jmp kexec_verify_architecture_failed

.done:
	push verifySuccessMsg
	call vid_print_string
	clear_stack_ns(1)
	
	ret

kexec_verify_architecture_failed:
	; Input: pointer to string in eax
	; Output: does not terminate
	
	push eax
	
	; ... Clear screen
	push dword YELLOW_ON_BLACK
	call vid_set_attribute
	clear_stack_ns(1)
	call vid_clear
	
	; .. Write message
	call vid_print_string ; on the stack by eax
	clear_stack_ns(1)
	
	jmp kexec_done_halt
	nop

kexec_done:
	cli
	call print_halt_message
kexec_done_halt:
	
.done:
	hlt
	jmp .done

end:

section .rodata
endMsg db "@@ System execution completed - system shutdown", 0
verifyMsg db "Verifying architecture...", 0
verifyUnknownMsg db "Incapable CPU: no CPUID support", 0
verifyFailedMsg db "Incapable CPU: does not support x64 (long mode)", 0
verifySuccessMsg db "... success", 0
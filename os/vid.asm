bits 32

section .text:

VGA_ORIGIN EQU 0xB8000
VGA_MAX EQU 80*25
VGA_END EQU VGA_ORIGIN + (VGA_MAX * 2)

ASCII_SPACE EQU 0x20
WHITE_ON_BLUE EQU 17H

global vid_clear

vid_clear:
	nop
	
	mov eax, VGA_ORIGIN
.vid_loop:
	mov dword [eax], ASCII_SPACE
	mov dword [eax + 1], WHITE_ON_BLUE
	
	add eax, 2
	cmp eax, VGA_END
	jl .vid_loop
	
.vid_loop_done:
	
	nop
	ret
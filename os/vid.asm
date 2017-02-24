; vid.asm - Video output functions
;

[bits 32]
%include "../macro.incl.asm"

section .text:

VGA_ORIGIN EQU 0xB8000
VGA_WIDTH EQU 80
VGA_WIDTH_OFF EQU VGA_WIDTH*2 ; With attribute offset

VGA_HEIGHT EQU 25
VGA_HEIGHT_OFF EQU VGA_HEIGHT*2  ; With attribute offset
VGA_MAX EQU VGA_WIDTH*VGA_HEIGHT
VGA_END EQU VGA_ORIGIN + (VGA_MAX * 2)

ASCII_SPACE EQU 0x20
WHITE_ON_BLUE EQU 17H

global vid_clear
global vid_set_attribute
global vid_reset_cursor
global vid_advance_cursor
global vid_print_string
global vid_put_char
global vid_advance_line
global vid_print_string_line

; vid_clear
; Clears the screen using the current set attribute. Resets cursor position.
;
; Inputs: void
; Outputs: void
vid_clear:
	mov eax, VGA_ORIGIN
	
.vid_loop:
	mov byte [eax], ASCII_SPACE
	mov cl, [screen_attr]
	mov [eax + 1], cl
	
	add eax, 2
	cmp eax, VGA_END
	jl .vid_loop ; if we didn't reach end of VGA buffer
	
.vid_loop_done:
	jmp vid_reset_cursor
	ret

; vid_reset_cursor
; Resets cursor position
;
; Inputs: void
; Outputs: void
vid_reset_cursor:
	mov [cursor_X], dword 0
	mov [cursor_Y], dword 0
	ret

; vid_set_attribute
; Set the current attribute to draw the screen with
;
; This function does not set-up its own stack because it doesn't need one.
;
; Inputs: unsigned integer
; Outputs: void
vid_set_attribute:
	mov al, param_ns(0) ; previous fn stack
	mov byte [screen_attr], al
	ret

; vid_advance_cursor
; Advances the cursor as expected, to the new line if necessary
;
; Input: void
; Output: void
vid_advance_cursor:
	mov eax, [cursor_X]
	add eax, 1
	cmp eax, VGA_WIDTH
	jge vid_advance_line ; done if still below VGA_WIDTH
	mov [cursor_X], eax
	ret

; vid_advance_line
; Advances the cursor to the next line, resets X position.
;
; Input: void
; Output: void
vid_advance_line:
	; in this case we need to increase cursor_Y
	mov eax, [cursor_Y]
	add eax, 1
	mov [cursor_Y], dword eax
	mov [cursor_X], dword 0
	ret

; vid_put_char
; Output single character to current position on screen. Advances the cursor.
;
; Input: char
; Output: void
vid_put_char:
	mov ecx, [ebp+8]
	; note: no jump, we fall through vid_put_char_internal
	
; vid_put_char_internal
; Output single character to current position
;
; Input: char in [ecx]
; Output: screen_attribute in ecx
vid_put_char_internal:
	; Calc target address
	mov eax, VGA_WIDTH_OFF
	mul dword [cursor_Y]				; lower-part is stored in eax
	add eax, [cursor_X]
	add eax, [cursor_X]
	add eax, VGA_ORIGIN
	
	mov byte [eax], cl 						; set char
	
	mov cl, byte [screen_attr]				; color
	mov byte [eax + 1], cl
	
	jmp vid_advance_cursor	
	ret

; vid_print_string
; Output zero-terminated 1-byte-per-char string to current position on screen.
;
; Input: char*
; Output: void
vid_print_string:
	push esi
	mov esi, param_ns(1)	; Grab incoming pointer
	
	.loop:
	movzx ecx, byte [esi]			; Store character for v_p_c_i, clear upper bytes
	cmp ecx, 0x0			; Check for \0 character
	je .done
	
	call vid_put_char_internal ; param = ecx
	inc esi 				; Next char
	jmp .loop
	
	.done:
	pop esi
	ret

; vid_print_string_line
; Output zero-terminated 1-byte-per-char string to current position on screen and
; advances to the next line.
;
; Input: char*
; Output: void
vid_print_string_line:
	mov eax, param_ns(0)
	
	push eax
	call vid_print_string
	pop eax
	
	call vid_advance_line
	ret

end:

section .data
screen_attr db WHITE_ON_BLUE
cursor_X dd 0
cursor_Y dd 0
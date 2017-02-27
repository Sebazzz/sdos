; vid.asm - Video output functions
;

[bits 32]
%include "../macro.incl.asm"

section .text:

VGA_ORIGIN EQU 0xB8000
VGA_WIDTH EQU 80
VGA_WIDTH_OFF EQU VGA_WIDTH*2 ; With attribute offset

VGA_HEIGHT EQU 25
VGA_MAX EQU (VGA_WIDTH*VGA_HEIGHT)
VGA_END EQU VGA_ORIGIN + (VGA_MAX * 2)

ASCII_SPACE EQU 0x20
WHITE_ON_BLUE EQU 0x1F

extern memcpy

; vid_clear
; Clears the screen using the current set attribute. Resets cursor position.
;
; Inputs: void
; Outputs: void
global vid_clear
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
global vid_reset_cursor
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
global vid_set_attribute
vid_set_attribute:
	mov al, param_ns(0) ; previous fn stack
	mov byte [screen_attr], al
	ret

; vid_set_fg
; Sets the current foreground color to draw with
;
; Input: char
; Output: void
global vid_set_fg
vid_set_fg:
	mov al, byte [screen_attr]
	and al, 0xF0				; Clear foreground bits
	or al, param_ns(0)			; Copy param value
	mov byte [screen_attr], al
	ret

; vid_set_bg
; Sets the current background color to draw with
;
; Input: char
; Output: void
global vid_set_bg
vid_set_bg:
	mov al, byte [screen_attr]
	and al, 0x0F				; Clear background bits
	mov dl, param_ns(0)
	shl dl, 4					; Shift bits to left
	or al, dl					; Copy value
	mov byte [screen_attr], al
	ret

; vid_advance_cursor
; Advances the cursor as expected, to the new line if necessary
;
; Input: void
; Output: void
global vid_advance_cursor
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
global vid_advance_line
vid_advance_line:
	; in this case we need to increase cursor_Y
	mov eax, [cursor_Y]
	add eax, 1
	cmp eax, VGA_HEIGHT-1			; Ensure smaller or need to scroll
	jle .store
	
	; Need to scroll. We do this by discarding the first line, and thus
	; copy the rest of the buffer to the first line.
	VGA_ORIGIN_WITH_FIRST_LINE EQU VGA_ORIGIN + VGA_WIDTH_OFF			; Source addr to copy from
	VGA_SZ_EXCEPT_FIRST_LINE EQU (VGA_MAX * 2) - VGA_WIDTH_OFF			; Number of bytes to copy
	VGA_LAST_LINE EQU VGA_ORIGIN + VGA_SZ_EXCEPT_FIRST_LINE
	
	push ecx					; Internal caller requires preservation of ecx
	push VGA_ORIGIN						; Destination
	push VGA_ORIGIN_WITH_FIRST_LINE		; Source
	push VGA_SZ_EXCEPT_FIRST_LINE		; Size
	call memcpy
	clear_stack_ns(3)			; Restore stack after pushing
	
	; Clear lower line
	mov eax, VGA_LAST_LINE		; Pick begin of last line and increase from there
	
	; ... Calc target address
.clear_line_loop:
	mov cl, ASCII_SPACE				; Write blank (=space)
	mov byte [eax], ASCII_SPACE 	; set char
	
	mov cl, byte [screen_attr]		; color
	mov byte [eax + 1], cl

	add eax, 2							; Add eax until line is cleared
	cmp eax, VGA_END
	jl .clear_line_loop
	
	; Done clearing line
	pop ecx						; Restore ECX for internal caller
	
	; Store new Y which is height - 1
	mov eax, VGA_HEIGHT - 1
	mov [cursor_Y], dword eax
	
.store:
	mov [cursor_Y], dword eax
	mov [cursor_X], dword 0
	ret

; vid_put_char
; Output single character to current position on screen. Advances the cursor.
;
; Input: char
; Output: void
global vid_put_char
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
global vid_print_string
vid_print_string:
	push esi
	mov esi, param_ns(1)	; Grab incoming pointer
	
.loop:
	movzx ecx, byte [esi]			; Store character for v_p_c_i, clear upper bytes
	cmp ecx, 0x0			; Check for \0 character
	je .done
	
	cmp ecx, 0xA
	je .newline
	
	call vid_put_char_internal ; param = ecx
	inc esi 				; Next char
	jmp .loop
	
.newline:
	call vid_advance_line
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
global vid_print_string_line
vid_print_string_line:
	mov eax, param_ns(0)
	
	push eax
	call vid_print_string
	clear_stack_ns(1)
	
	jmp vid_advance_line
	ret

end:

section .data
screen_attr db WHITE_ON_BLUE
cursor_X dd 0					; zero based X cursor (max: VGA_WIDTH - 1)
cursor_Y dd 0					; zero based Y cursor (max: VGA_HEIGHT - 1)
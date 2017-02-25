; string.asm
;
; Partial C stdlib implementation

[bits 32]
%include "../macro.incl.asm"

; memcpy
; Copies the values of num bytes from the location pointed to by source directly to the memory block pointed to by destination.
; 
; Input: void* destination, void* source, size_t num
global memcpy
memcpy:
	push edi			; Per x86 SystemV calling convention, preserve edi/esi
	push esi
	
	mov ecx, param_ns(0, 2)	; num
	mov esi, param_ns(1, 2)	; source
	mov edi, param_ns(2, 2) ; dest
	
	cld
	rep movsb
	
	pop esi				; Restore ESI and EDI
	pop edi
	ret
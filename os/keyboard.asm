; keyboard.asm
; Keyboard control routines

[bits 32]

global get_scancode

; get_scancode
; Get a single scan code from the keyboard
;
; Input: nothing
; Output: char
get_scancode: 
hlt				; TODO
ret
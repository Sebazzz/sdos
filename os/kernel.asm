; kernel.asm
; 
; Main OS kernel

WHITE_ON_BLUE EQU 17H

org 0x500
bits 16

  
   call InitByArgs
   
   call PrintEndMsg
   
   hlt
   
%include "../io.asm"

InitByArgs:
   ; Cursor position passed in ax,cx
   mov [cursor_X], ax
   mov [cursor_Y], cx
   
   ret

; Print end message
PrintEndMsg:
   ; Print
   mov si, endMsg
   call PrintLn
   
   ret
   
endMsg db "-- System execution completed - system shutdown", 0
cursor_X db 0
cursor_Y db 2
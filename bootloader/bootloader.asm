;******************************************
; Bootloader.asm		
; A Simple Bootloader
;******************************************

WHITE_ON_BLUE EQU 17H
READ_SUCCESS EQU 0H
ELF_OFFSET EQU 18h

bits 16
start: jmp boot

   ;; constant and variable definitions
bootMsg db "Booting the Damsteen Operating System!", 0
errMsg db "Error reading disk - terminated", 0
endMsg db "-- System execution completed - system shutdown", 0
cursor_X db 0
cursor_Y db 0

boot:
  cli	; no interrupts
  cld	; all that we need to init
  call InitGfx
  
  call PrintBootMsg
  call ReadKernel
  call ExecKernel
  call PrintEndMsg
  
  hlt	; halt the system

InitGfx:
   ; Init video mode
   mov ah, 00h
   mov al, 03h ; text     80x25     8x8* 16/8          CGA,EGA  b800  Comp,RGB,Enh
   int 0x10
   
   ; Clear via SCROLL DOWN WINDOW
   mov ah, 07h
   mov al, 00h ; clear
   mov bh, 10h
   mov ch, 0
   mov cl, 0
   mov dh, 25h
   mov dl, 80h
   int 0x10
   
   ; Cursor pos
   mov dh, 00h
   mov dl, 00h
   call MovCursor
   
   ret
   
   ; returns target address in ah
ReadKernel:
   mov ax, 0x50
   
   ; set buffer to read to
   
   mov es, ax
   xor bx, bx
   
   mov al, 2 ; read two sectors
   mov ch, 0 ; track 0
   mov cl, 2 ; sector to read
   mov dh, 0 ; head number
   mov dl, 0 ; drive number
   
   mov ah, 2 ; method
   int 13h ; BIOS
   
   ; error handling
   cmp ah, READ_SUCCESS
   jne ReadError
   
   ret

ReadError:
   ; Print
   mov si, errMsg
   call PrintLn
   
   ; Nothing 2 do
   hlt
   
ExecKernel:
   mov ax, [cursor_X]
   mov cx, [cursor_Y]
   jmp [500h + ELF_OFFSET]
   ret

%include "../io.incl.asm"
   
; Print the boot message
PrintBootMsg:
   ; Reset cursor
   mov bh, 0
   mov bl, 0
   call MovCursor
   
   ; Print
   mov si, bootMsg
   call PrintLn
   
   ret
   
; Print end message
PrintEndMsg:
   ; Print
   mov si, endMsg
   call PrintLn
   
   ret

   ; We have to be 512 bytes. Clear the rest of the bytes with 0
times 510 - ($-$$) db 0

dw 0xAA55   ; Boot Signature
   ; dl = x; dh = y
MovCursor:
   mov ah, 02h
   mov bh, 00h
   int 0x10
   
   mov [cursor_X], dl
   mov [cursor_Y], dh
   
   ret

   ; al = chr, cx = repeat
PutChar:
   mov ah, 09h
   mov al, al
   mov bl, WHITE_ON_BLUE
   mov cx, cx
   mov bh, 00h
   int 0x10
   
   add [cursor_X], cx
   mov dl, [cursor_X]
   mov dh, [cursor_Y]
   call MovCursor
   
   ret
   
   ;; ds:si = Zero terminated string
Print:
.loop:
   lodsb
   or al, al
   jz .done
   mov cx, 1
   call PutChar
   jmp .loop
   
   .done:
   ret
   
PrintLn:
   call Print
   
   mov al, [cursor_Y]
   mov dl, 0
   mov dh, [cursor_Y]
   add dh, 1
   call MovCursor
   
   ret
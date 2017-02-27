;******************************************
; Bootloader.asm		
; A Simple Bootloader
;******************************************

WHITE_ON_BLUE EQU 17H
READ_SUCCESS EQU 0H
ELF_OFFSET EQU 18h
KERNEL_LOCATION EQU 600h

[bits 16]
start: jmp word boot

	;; constant and variable definitions
bootMsg db "Booting the Damsteen Operating System!", 0
errMsg db "Error reading disk - terminated", 0
cursor_X db 0
cursor_Y db 0

boot:
  cli	; no interrupts
  cld	; all that we need to init
  call init_gfx
  
  call print_bootmsg
  call read_kernel
  jmp exec_kernel
  
  hlt	; halt the system - though we don't expect to come here

%include "io.incl.asm"
	
; Print the boot message
print_bootmsg:
	; Reset cursor
	mov bh, 0
	mov bl, 0
	call MovCursor
	
	; Print
	mov si, bootMsg
	call PrintLn
	
	ret
	

init_gfx:
	; Init video mode
	mov ah, 00h
	mov al, 03h ; text	  80x25	  8x8* 16/8			 CGA,EGA  b800  Comp,RGB,Enh
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
	
	; Disable cursor
	mov ah, 01h
	mov ch, 00100000b
	mov cl, 00000000b
	int 0x10
	
	ret
	
	; returns target address in ah
read_kernel:
	mov cx, 0x3		; retry count
	
.read_loop:
	mov ax, 0x50	; set buffer to read to
	
	mov es, ax
	xor bx, bx
	
	mov al, 16		; read some sectors
	mov ch, 0		; track 0
	mov cl, 2		; sector to read
	mov dh, 0		; head number
	mov dl, 0		; drive number
	
	mov ah, 2		; function
	int 13h			; Invoke BIOS
	
	; error handling
	cmp ah, READ_SUCCESS
	jne .read_err
	
	ret

.read_err:
	sub cx, 1
	cmp cx, 0
	jne .read_loop
	
	; Print
	mov si, errMsg
	call PrintLn
	
	; Nothing 2 do
	hlt
	
exec_kernel:
	cli
	xor ax, ax 				; Clear AX register 
	mov ds, ax 				; Set DS-register to 0 - used by lgdt
	
	lgdt [gdt_desc]			; Load the GDT descriptor
	
	; A20
	in al, 0x93
	or al, 2
	and al, ~1
	out 0x92, al
	
	; PM
	mov eax, cr0			; Copy the contents of CR0 into EAX
	or eax, 1				; Set bit 0 (0xFE = Real Mode)
	mov cr0, eax			; Copy the contents of EAX into CR0
	
	jmp (gdt_kernel_code - gdt_null) : exec_kernel_32

[bits 32]
exec_kernel_32:
	mov ax, gdt_kernel_data - gdt_null
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
	jmp (gdt_kernel_code - gdt_null):KERNEL_LOCATION
	hlt

;----------Global Descriptor Table----------;
gdt: 				; Address for the GDT
gdt_null: 			; Null Segment 
dd 0 
dd 0

KERNEL_CODE equ $-gdt

gdt_kernel_code: 
dw 0xFFFF 			; Limit 0xFFFF 
dw 0 				; Base 0:15 
db 0 				; Base 16:23 
db 10011010b		; Present, Ring 0, Code, Non-conforming, Readable 
db 11001111b		; Page-granular 
db 0 				; Base 24:31

KERNEL_DATA equ $-gdt

gdt_kernel_data: 
dw 0xFFFF 			; Limit 0xFFFF 
dw 0 				; Base 0:15 
db 0 				; Base 16:23 
db 10010010b		; Present, Ring 0, Data, Expand-up, Writable 
db 11001111b		; Page-granular 
db 0 				; Base 24:32

gdt_interrupts: 
dw 0FFFFh 
dw 01000h 
db 0 
db 10011110b 
db 11001111b 
db 0

gdt_end: 					; Used to calculate the size of the GDT
gdt_desc: 					; The GDT descriptor 
	dw gdt_end - gdt - 1 	; Limit (size) 
	dd gdt 					; Address of the GDT

	; We have to be 512 bytes. Clear the rest of the bytes with 0
times 510 - ($-$$) db 0

dw 0xAA55	; Boot Signature
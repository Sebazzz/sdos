; hwport.incl.asm
;
; Well-known hardware ports

RTC_ADDR EQU 0x70
CMOS_ADDR EQU 0x71

PIC1 EQU 0x20
PIC2 EQU 0xA0

PIC1_COMMAND EQU PIC1
PIC1_DATA EQU PIC1+1
PIC2_COMMAND EQU PIC2
PIC2_DATA EQU PIC2+1

; Wait for I/O operation to complete
%macro io_wait 0
out 0x80, eax
%endmacro
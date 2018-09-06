; ktime.asm
;
; Kernel timer

[bits 32]
%include "../macro.incl.asm"

RTC_ADDR EQU 0x70
CMOS_ADDR EQU 0x71

global sleep_ticks
global sleep
global kinit_init_timer
global kinit_enable_timer
global ktime_ontick

; kinit_init_timer
; Initializes the RTC
;
; Input: nothing
; Output: nothing
kinit_init_timer:
	cli ; we expect this to be called with interrupts off, but never mind retrying this
	
	; Using eax as scratch register
	push eax
	mov eax, 0x8A
	out RTC_ADDR, eax
	
	mov eax, 0x20
	out CMOS_ADDR, eax
	pop eax
	
	ret

; kinit_enable_timer
; Enable RTC interrupt. Do not call before interrupt handler is installed.
;
; Input: nothing
; Output: nothing
kinit_enable_timer:
	cli
	
	; Using eax as scratch register
	push eax
	
	mov eax, 0x8B
	out RTC_ADDR, eax  ;select register B, and disable NMI
	
	in eax, CMOS_ADDR   ;read the current value of register B
	
	push eax ; save eax, it is the only register we can use for in/out instructions
	mov eax, 0x8B
	out RTC_ADDR, eax  ;set the index again (a read will reset the index to register D)
	pop eax  ; restore eax, it contains the current value of register B
	
	; turn on bit 6
	or eax, 0x40
	out CMOS_ADDR, eax
	
	pop eax
	
	sti
	ret

; ktime_ontick
; Internal kernel method called on a tick. Increases internal timer.
;
; Input: nothing
; Output: nothing
ktime_ontick:
	nop
	lea eax, [tick_timer_count]
	inc dword [eax]
	nop
	ret

; sleep
; sleep_ticks
; Sleeps for a number of ticks (DOES NOT WORK YET ACCURATELY)
; One tick is 1024Hz. May not be accure for a low number of ticks.
;
; Input: unsigned int ticks
; Output: nothing
sleep:
sleep_ticks:
	nop
	mov eax, 100000
	mul dword param_ns(0)
.loop:
	dec eax
	cmp eax, 0x0
	jne .loop
	ret

section .data:

tick_timer_count:
dd 0x0
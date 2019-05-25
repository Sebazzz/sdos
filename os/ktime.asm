; ktime.asm
;
; Kernel timer

[bits 32]
%include "../macro.incl.asm"
%include "../hwport.incl.asm"

extern nmi_enable
extern nmi_disable

; kinit_init_timer
; Initializes the RTC
;
; Input: nothing
; Output: nothing
global kinit_init_timer
kinit_init_timer:
	cli ; we expect this to be called with interrupts off, but never mind retrying this
	
	call nmi_disable
	
	; Using eax as scratch register
	push eax
	mov eax, 0x8A
	out RTC_ADDR, eax
	
	mov eax, 0x20
	out CMOS_ADDR, eax
	pop eax
	
	call nmi_enable
	
	ret

; kinit_enable_timer
; Enable RTC interrupt. Do not call before interrupt handler is installed.
;
; Input: nothing
; Output: nothing
global kinit_enable_timer
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
	
	; Acknowledge interrupt, or it won't fire again
	mov eax, 0x0C
	out RTC_ADDR, eax ; register C
	in eax, CMOS_ADDR ; read, but discard
	
	; end eax as scratch register
	pop eax
	
	sti
	ret

; ktime_ontick
; Internal kernel method called on a tick. Increases internal timer.
;
; Input: nothing
; Output: nothing
global ktime_ontick
ktime_ontick:
	nop
	lea eax, [tick_timer_count]
	inc dword [eax]
	nop
	ret

; sleep
; sleep_ticks
; Sleeps for a number of ticks (DOES NOT WORK YET ACCURATELY)
; One tick every 1/1024 second. May not be accure for a low number of ticks.
;
; Input: unsigned int ticks
; Output: nothing
global sleep
global sleep_ticks
sleep:
sleep_ticks:
	nop
	
	; eax contains the target tick timer count
	push eax
	mov eax, param_ns(1)
	add eax, [tick_timer_count]

.loop:
	cmp eax, [tick_timer_count]
	jg .loop
	
	pop eax
	ret

section .data:

tick_timer_count:
dd 0x0
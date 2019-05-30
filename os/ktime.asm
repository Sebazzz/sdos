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
	
	mov al, 0x8B
	out RTC_ADDR, al  ;select register B, and disable NMI
	io_wait
	in al, CMOS_ADDR   ;read the current value of register B
	
	push eax ; save eax, it is the only register we can use for in/out instructions
	mov al, 0x8B
	out RTC_ADDR, al  ;set the index again (a read will reset the index to register D)
	pop eax  ; restore eax, it contains the current value of register B
	io_wait
	
	; turn on bit 6
	or al, 0x40
	out CMOS_ADDR, al
	
	; Acknowledge interrupt, or it won't fire again
	mov al, 0x0C
	out RTC_ADDR, al ; register C
	io_wait
	in al, CMOS_ADDR ; read, but discard
	
	; end eax as scratch register
	pop eax
	
	sti
	ret

; ktime_rtc_ontick
; Internal kernel method called on a tick from the RTC. Increases internal timer.
;
; Input: nothing
; Output: nothing
global ktime_rtc_ontick
ktime_rtc_ontick:
	nop
	lea eax, [rtc_tick_timer_count]
	inc dword [eax]
	nop
	ret
	
; ktime_pit_ontick
; Internal kernel method called on a tick from the PIT. Increases internal timer.
;
; Input: nothing
; Output: nothing
global ktime_pit_ontick
ktime_pit_ontick:
	nop

	mov eax, [pit_ms_between_irq]
	add [pit_tick_timer_ms_count], eax
	
	nop
	ret
	
; ktime_pit_init
; Initialize the program interrupt timer
;
; Input: nothing
; Output: nothing
global ktime_pit_init
ktime_pit_init:
	; Setup PIT with PIT_DESIRED_FREQ
	mov ebx, PIT_DESIRED_FREQ
	call setup_pit
	ret

; setup_pit
; Set-up the pit with a desired frequency
;
; Input: desired frequency in hz (ebx)
; Output: nothing
PIT_RLD_MAX EQU 3579545
setup_pit:
	pushad
	
	mov edx, 0
	mov [pit_frequency], bx
	mov eax, 1193180 
	div ebx
	
	push eax
	mov eax, 0x43
	out PIT_COMMAND, al	
	pop eax
	
	push eax
	and eax, 0xFF
	out PIT_CHANNEL0, al
	pop eax
	
	push eax
	shr eax, 8
	out PIT_CHANNEL0, al
	pop eax
	
	mov eax, ebx
	mov ebx, 1000
	mov edx, 0
	div ebx
	
	mov [pit_ms_between_irq], ax
	
	popad
	
	ret

; sleep
; sleep_ms
; Sleeps for a number of milliseconds (DOES NOT WORK YET ACCURATELY)
;
; Input: unsigned int ticks
; Output: nothing
global sleep
global sleep_ms
sleep:
sleep_ms:
	nop
	
	; eax contains the target tick timer count
	push eax
	mov eax, param_ns(1)
	add eax, [pit_tick_timer_ms_count]
	jmp .loop

.loop_wait:
	hlt
	
.loop:
	cmp eax, [pit_tick_timer_ms_count]
	jg .loop_wait
	
	pop eax
	ret

section .data:

rtc_tick_timer_count: dd 0x0
pit_tick_timer_ms_count: dd 0x0

pit_reload_value: dw 0
pit_frequency: dd 0
pit_ms_between_irq: dd 0
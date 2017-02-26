; macro.incl.asm
;
; Various inclusion macros to make stuff bit easier

; param(n) where n is the zero-based index of the parameter
; Retrieves in the current function which sets up a stack the specified parameter. Returns the memory address
; of the parameter retrieved via ebp (since the stack is assumed to be setup for the current frame and ebp assigned)
%define param(n) [ebp + ((2 + n) * 4)]

; param(n, stack) where n is the zero-based index of the parameter and stack the number of items pushed on the stack in this fn
; Retrieves in the current function which doesn't set-up a stack. Returns the memory address
; of the parameter retrieved via esp (since the stack isn't setup for the current frame)
%define param_ns(n, stack) [esp + ((1 + stack + n) * 4)]

; param(n) where n is the zero-based index of the parameter
; Retrieves in the current function which doesn't set-up a stack. Returns the memory address
; of the parameter retrieved via esp (since the stack isn't setup for the current frame)
%define param_ns(n) [esp + ((1 + n) * 4)]

; clear_stack_ns(n) where n is the number of pushed objects
; Clears earlier pushed items on the stakc
%define clear_stack_ns(n) add esp, (n * 4)

; io_wait()
; Forces the CPU to wait for an I/O operation to complete
%define io_wait out 0x80, al

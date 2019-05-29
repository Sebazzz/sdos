define hook-stop_
	# Translate the segment:offset into a physical address 
	printf "[%4x:%4x] ", $cs, $rip
	x/i $cs*16+$rip
	refresh
end

define exit
	quit
end

set directories bootloader:os

set disassembly-flavor intel

define dbg-bootloader
	symbol-file build/bootloader/bootloader.o.elf
	layout asm
	layout reg
	set architecture i8086
	
	# Bootloader start
	b *0x7c00
	
	# Just before reading kernel
	b *0x7cde
	
	# Just before executing kernel, enable protected mode
	b *0x7d08
	
	# 32-bit protected mode kernel jump
	b exec_kernel_32
end

define dbg-os
	set architecture i386:x86-64:intel
	symbol-file build/os/os
	layout split
	#b kinit
	#b kmain
	b kexec_done
	b kexec_done.done
	
	# Set-up breakpoints in the respective handlers
	#b init_interrupt
	b divide_by_zero_handler
	b segment_np_handler
	b double_fault_handler
	b segment_overflow_handler
	b gp_fault_handler
	b security_exception_handler
	
	b irq_rtc_handler
	b ktime_ontick
	b setup_pic
	#b kinit_init_timer
	#b kexec_verify_architecture
	#b sleep
end

define connect
	target remote localhost:26000
end

define kern_tick_count
	# Known location of tick_timer_count (is there a better way?)
	x/1dw &tick_timer_count
end

set write on
#dbg-bootloader
dbg-os
connect




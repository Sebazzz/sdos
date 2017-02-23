define hook-stop
	# Translate the segment:offset into a physical address 
	printf "[%4x:%4x] ", $cs, $eip
	x/i $cs*16+$eip
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
end

define dbg-os
	set architecture i386:intel
	symbol-file build/os/imm/asm/vid.o
	symbol-file build/os/os
	layout split
	b kinit
	b kmain
	b kexec_done
	b kexec_done.done
	b vid_print_string
end

define connect
	target remote localhost:26000
end

set write on
#dbg-bootloader
dbg-os
connect




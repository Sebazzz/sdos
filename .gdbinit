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
	
	# Just before executing kernel, enable protected mode
	b *0x7cf4
end

define dbg-os
	set architecture i386:intel
	symbol-file build/os/os
	layout split
	b kinit
	b *0x625
	b kmain
end

define connect
	target remote localhost:26000
end

dbg-bootloader
#dbg-os
connect




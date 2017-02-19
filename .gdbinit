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
end

define dbg-os
	symbol-file build/os/os
	layout split
	b kmain
end

define connect
	target remote localhost:26000
end

dbg-bootloader
set architecture i8086
connect

b *0x7c00
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
end

dbg-bootloader
set architecture i8086
target remote localhost:26000

b *0x7c00
b kmain
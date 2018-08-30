ENTRY(kinit);
OUTPUT_FORMAT(elf32-i386);

PHDRS { 
	headers PT_PHDR PHDRS; 
	code PT_LOAD FILEHDR PHDRS;
}

SECTIONS {
	.text 0x600: ALIGN(0x100) { *(.text) } :code
	.rdata : { *(rdata) }
	.data : { *(data) }
	.bss : { *(bss) }
	/DISCARD/ : { *(.eh_frame) }
}
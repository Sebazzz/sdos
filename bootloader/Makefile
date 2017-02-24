CFLAGS= -f elf -F dwarf -g
LDFLAGS= -m elf_i386 -T bootloader.lds
BUILD_DIR=../build/bootloader

BOOTLOADER_SRCS := bootloader.asm
BOOTLOADER_OBJS := $(patsubst %.asm, $(BUILD_DIR)/%.o, $(BOOTLOADER_SRCS))

all: $(BOOTLOADER_OBJS)

$(BUILD_DIR)/%.o: %.asm
	mkdir -p $(BUILD_DIR)
	nasm $(CFLAGS) $< -o $@
	ld $(LDFLAGS) $@ -o $@.elf
	objcopy -O binary $(BUILD_DIR)/bootloader.o.elf $@

clean:
	rm -f $(BUILD_DIR)/*
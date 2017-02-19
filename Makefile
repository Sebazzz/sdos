CFLAGS= -f bin
BUILD_DIR=build
BOOTLOADER=$(BUILD_DIR)/bootloader/bootloader.o
OS=$(BUILD_DIR)/os/os
DISK_IMG=$(BUILD_DIR)/disk.img

all: bootdisk

.PHONY: bootdisk bootloader os

bootloader:
	make -C bootloader

os:
	make -C os

build: bootloader os

bootdisk: build
	rm -f $(DISK_IMG)
	dd if=/dev/zero of=$(DISK_IMG) bs=512 count=2880
	dd conv=notrunc if=$(BOOTLOADER) of=$(DISK_IMG) bs=512 count=1 seek=0
	dd conv=notrunc if=$(OS) of=$(DISK_IMG) bs=512 count=$$(($(shell stat --printf="%s" $(OS))/512)) seek=1

debug: bootdisk
	qemu-system-i386 -machine q35 -fda $(DISK_IMG) -gdb tcp::26000 -S

run: bootdisk
	qemu-system-i386 -machine q35 -fda $(DISK_IMG) -gdb tcp::26000

clean:
	make -C bootloader clean
	make -C os clean
	rm -f $(DISK_IMG)

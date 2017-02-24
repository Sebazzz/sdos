CFLAGS= -ffreestanding -nostdlib -gdwarf-4 -m32 -ggdb3 -Wall -Werror
ASMCFLAGS= -f elf32 -F dwarf -g -w+all
LDFLAGS= --nmagic -m elf_i386 --script=os.lds

BUILD_DIR=../build/os
BUILD_DIR_IMM=$(BUILD_DIR)/imm
BUILD_DIR_IMM_ASM=$(BUILD_DIR_IMM)/asm
BUILD_DIR_IMM_C=$(BUILD_DIR_IMM)/c
BUILD_OUTPUT=$(BUILD_DIR)/os

OS_C_SRCS := $(wildcard *.c)
OS_C_OBJS := $(patsubst %.c, $(BUILD_DIR_IMM_C)/%.o, $(OS_C_SRCS))

OS_ASM_SRCS := $(wildcard *.asm)
OS_ASM_OBJS := $(patsubst %.asm, $(BUILD_DIR_IMM_ASM)/%.o, $(OS_ASM_SRCS))

OS_SRCS := $(OS_C_SRCS) $(OS_ASM_SRCS)
OS_OBJS := $(OS_ASM_OBJS) $(OS_C_OBJS)

all: $(BUILD_OUTPUT)

prepdir:
	mkdir -p $(BUILD_DIR_IMM_C)
	mkdir -p $(BUILD_DIR_IMM_ASM)

$(OS_C_OBJS): $(OS_C_SRCS) $(OS_ASM_OBJS) prepdir
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR_IMM_ASM)/kinit.o: kinit.asm prepdir
	nasm $(ASMCFLAGS) kinit.asm -o $@
	
$(BUILD_DIR_IMM_ASM)/vid.o: vid.asm prepdir
	nasm $(ASMCFLAGS) vid.asm -o $@
	
$(BUILD_OUTPUT): $(OS_C_OBJS) $(OS_ASM_OBJS)
	ld $(LDFLAGS) $(OS_OBJS) -o $@

clean:
	rm -rf $(BUILD_DIR)
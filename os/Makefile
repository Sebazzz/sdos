CFLAGS= -ffreestanding -nostdlib -gdwarf-4 -m32 -ggdb3
LDFLAGS= -m elf_i386 -nmagic -Tos.lds
BUILD_DIR=../build/os
BUILD_DIR_IMM=$(BUILD_DIR)/imm
BUILD_OUTPUT=$(BUILD_DIR)/os

OS_SRCS := $(wildcard *.c)
OS_OBJS := $(patsubst %.c, $(BUILD_DIR_IMM)/%.o, $(OS_SRCS))

all: $(BUILD_OUTPUT)

$(BUILD_DIR_IMM)/%.o: %.c
	mkdir -p $(BUILD_DIR_IMM)
	gcc $(CFLAGS) -c $< -o $@
	
$(BUILD_OUTPUT): $(OS_OBJS)
	ld $(LDFLAGS) $(OS_OBJS) -o $@

clean:
	rm -rf $(BUILD_DIR)
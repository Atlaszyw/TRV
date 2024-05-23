# Makefile for RISC-V assembly project

# 工具链
CC = riscv32-unknown-elf-gcc
OBJDUMP = riscv32-unknown-elf-objdump
OBJCOPY = riscv32-unknown-elf-objcopy
GDB = riscv32-unknown-elf-gdb

# 编译选项
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -Wall -Wextra
LDFLAGS = -T link.ld

# 目标文件
TARGET = test
SRC = test.s

# 编译和链接目标
all: $(TARGET).mif $(TARGET).disasm

$(TARGET).elf: $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

# 生成反汇编文件
$(TARGET).disasm: $(TARGET).elf
	$(OBJDUMP) -d $(TARGET).elf > $(TARGET).disasm

# 生成二进制文件
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $(TARGET).elf $(TARGET).bin

$(TARGET).mif: $(TARGET).bin
	python ./convert.py --byte_swap --bytes_per_address 4 --address_per_line 8 --fill 0x00 $(TARGET).bin $(TARGET).mif
# 清理生成的文件
clean:
	rm -f $(TARGET).elf $(TARGET).disasm $(TARGET).bin $(TARGET).mif

.PHONY: all disasm bin clean


RISCV_PATH := /home/main/Tools/riscv_llvm/

RISCV_GCC     := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-gcc)
RISCV_AS      := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-as)
RISCV_GXX     := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-g++)
RISCV_OBJDUMP := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-objdump)
RISCV_GDB     := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-gdb)
RISCV_AR      := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-ar)
RISCV_OBJCOPY := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-objcopy)
RISCV_READELF := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-readelf)

TARGET = boot
.PHONY: all
all: $(TARGET)

ASM_SRCS += ./src/boot.s
C_SRCS +=   ./src/main.c


LINKER_SCRIPT := ./link.ld
RISCV_ARCH := rv32im
RISCV_ABI := ilp32
RISCV_MCMODEL := medlow


INCLUDES += -I./inc

LDFLAGS += -T $(LINKER_SCRIPT) -nostartfiles -Wl,--gc-sections -Wl,--check-sections

ASM_OBJS := $(ASM_SRCS:.s=.o)
C_OBJS := $(C_SRCS:.c=.o)

LINK_OBJS += $(ASM_OBJS) $(C_OBJS)
LINK_DEPS += $(LINKER_SCRIPT)

CLEAN_OBJS += $(TARGET) $(LINK_OBJS) $(TARGET).dump $(TARGET).bin

CFLAGS += -march=$(RISCV_ARCH)
CFLAGS += -mabi=$(RISCV_ABI)
CFLAGS += -mcmodel=$(RISCV_MCMODEL) -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc

$(TARGET): $(LINK_OBJS) $(LINK_DEPS) makefile
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	$(RISCV_OBJCOPY) -O binary $@ $@.bin
	python /home/main/Projects/tinyriscv/script/src/convert.py --byte_swap --offset 0x00000000 --bytes_per_address 4 --address_per_line 8 $@.bin $@.mif
	$(RISCV_OBJDUMP) --disassemble-all $@ > $@.dump


$(ASM_OBJS): %.o: %.s
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	rm -f $(CLEAN_OBJS)

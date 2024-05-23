

SHELL=cmd

export RISCV_TARGET       ?= tinyriscv
export RISCV_PREFIX       ?= /home/main/Tools/riscv_llvm/bin/riscv32-unknown-elf-

CURDIR = $(shell echo %cd%)

export ROOTDIR    = $(subst \,/,$(CURDIR))
export TARGETDIR ?= $(ROOTDIR)/riscv-target


default: all


all:
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32i RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32i run -C $(ROOTDIR)/riscv-test-suite/rv32i
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32im RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32im run -C $(ROOTDIR)/riscv-test-suite/rv32im
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32Zicsr RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32Zicsr run -C $(ROOTDIR)/riscv-test-suite/rv32Zicsr
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32Zifencei RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32Zifencei run -C $(ROOTDIR)/riscv-test-suite/rv32Zifencei

clean:
	clean -C $(ROOTDIR)/riscv-test-suite/rv32i
	clean -C $(ROOTDIR)/riscv-test-suite/rv32im
	clean -C $(ROOTDIR)/riscv-test-suite/rv32Zicsr
	clean -C $(ROOTDIR)/riscv-test-suite/rv32Zifencei

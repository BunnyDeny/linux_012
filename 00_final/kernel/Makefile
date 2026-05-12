BUILD_DIR ?= $(CURDIR)/build/kernel

GCC := gcc
USE_DEBUG :=
CCFLAG := -I../include -nostdinc -ffreestanding -Wall -fomit-frame-pointer -fno-pic -fno-stack-protector -Wno-incompatible-pointer-types -fcommon -c -m32 $(USE_DEBUG)
LDFLAG := -Ttext 0x0 -s --oformat binary -m elf_i386

OBJS := $(addprefix $(BUILD_DIR)/, \
	head.o main.o sched.o fork.o printk.o sys_call.o vsprintf.o \
	traps.o asm.o sys.o panic.o segment.o mktime.o signal.o exit.o sys_table.o)

# 外部依赖统一在 build 目录下
FS_OBJ    := $(BUILD_DIR)/../fs/fs.o
MM_OBJ    := $(BUILD_DIR)/../mm/mm.o
LIB_A     := $(BUILD_DIR)/../lib/lib.a
CHR_DRV_A := $(BUILD_DIR)/chr_drv/chr_drv.a
BLK_DRV_A := $(BUILD_DIR)/blk_drv/blk_drv.a

SYSTEM := $(BUILD_DIR)/system

.PHONY: system clean

system: $(SYSTEM)

$(SYSTEM): $(OBJS) $(FS_OBJ) $(CHR_DRV_A) $(BLK_DRV_A) $(MM_OBJ) $(LIB_A)
	@mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAG) -e startup_32 -o $@ $^ -M > $(BUILD_DIR)/System.map

# 汇编文件显式规则
$(BUILD_DIR)/head.o: head.S
	@mkdir -p $(BUILD_DIR)
	$(GCC) -m32 -traditional -c -o $@ $<

$(BUILD_DIR)/sys_call.o: sys_call.S
	@mkdir -p $(BUILD_DIR)
	$(GCC) -m32 -traditional -c -o $@ $<

$(BUILD_DIR)/asm.o: asm.S
	@mkdir -p $(BUILD_DIR)
	$(GCC) -m32 -traditional -c -o $@ $<

# C 文件模式规则
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(GCC) $(CCFLAG) -o $@ $<

# 外部子目录编译
$(FS_OBJ):
	$(MAKE) BUILD_DIR=$(BUILD_DIR)/../fs -C ../fs fs.o

$(MM_OBJ):
	$(MAKE) BUILD_DIR=$(BUILD_DIR)/../mm -C ../mm mm.o

$(LIB_A):
	$(MAKE) BUILD_DIR=$(BUILD_DIR)/../lib -C ../lib lib.a

$(CHR_DRV_A):
	$(MAKE) BUILD_DIR=$(BUILD_DIR)/chr_drv -C chr_drv chr_drv.a

$(BLK_DRV_A):
	$(MAKE) BUILD_DIR=$(BUILD_DIR)/blk_drv -C blk_drv blk_drv.a

clean:
	rm -rf $(BUILD_DIR)

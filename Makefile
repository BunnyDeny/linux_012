# 参考现代 Linux 内核的 out-of-tree 构建风格
# 所有编译产物统一输出到 build/ 目录，与源码树完全分离
BUILD_DIR := $(CURDIR)/build

AS  := as
LD  := ld -m elf_x86_64
LDFLAG := -Ttext 0x0 -s --oformat binary

# 最终产物路径
IMAGE         := $(BUILD_DIR)/linux.img
BOOTSECT      := $(BUILD_DIR)/bootsect
SETUP         := $(BUILD_DIR)/setup
TOOLS_BUILD   := $(BUILD_DIR)/tools/build
KERNEL_SYSTEM := $(BUILD_DIR)/kernel/system

# 传递给子目录的构建目录变量
MAKE_FLAGS = BUILD_DIR=$(BUILD_DIR)

.PHONY: all image clean

all: image

image: $(IMAGE)

$(IMAGE): $(TOOLS_BUILD) $(BOOTSECT) $(SETUP) $(KERNEL_SYSTEM)
	@mkdir -p $(BUILD_DIR)
	$(TOOLS_BUILD) $(BOOTSECT) $(SETUP) $(KERNEL_SYSTEM) > $@

$(TOOLS_BUILD): tools/build.c
	@mkdir -p $(BUILD_DIR)/tools
	gcc -o $@ $<

$(KERNEL_SYSTEM): kernel/head.S kernel/*.c
	$(MAKE) $(MAKE_FLAGS)/kernel -C kernel system

$(BOOTSECT): bootsect.S
	@mkdir -p $(BUILD_DIR)
	$(AS) -o $(BUILD_DIR)/bootsect.o $<
	$(LD) $(LDFLAG) -o $@ $(BUILD_DIR)/bootsect.o

$(SETUP): setup.S
	@mkdir -p $(BUILD_DIR)
	$(AS) -o $(BUILD_DIR)/setup.o $<
	$(LD) $(LDFLAG) -e _start_setup -o $@ $(BUILD_DIR)/setup.o

clean:
	rm -rf $(BUILD_DIR)

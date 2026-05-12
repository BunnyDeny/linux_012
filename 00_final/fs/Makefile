BUILD_DIR ?= $(CURDIR)/build/fs

GCC := gcc
LD  := ld
CCFLAG := -I../include -nostdinc -ffreestanding -Wall -fomit-frame-pointer -c -fno-stack-protector -fno-pie -fno-pic -Wno-incompatible-pointer-types -fcommon -m32

OBJS := $(addprefix $(BUILD_DIR)/, \
	read_write.o ioctl.o buffer.o super.o file_table.o inode.o open.o \
	namei.o bitmap.o fcntl.o char_dev.o truncate.o exec.o file_dev.o pipe.o stat.o)

FS_OBJ := $(BUILD_DIR)/fs.o

.PHONY: fs.o clean

fs.o: $(FS_OBJ)

$(FS_OBJ): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(LD) -m elf_i386 -r -o $@ $^

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(GCC) $(CCFLAG) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)

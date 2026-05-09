BUILD_DIR ?= $(CURDIR)/build/mm

GCC := gcc
LD  := ld
CCFLAG := -I../include -ffreestanding -fno-pic -Wall -fomit-frame-pointer -fno-stack-protector -Wno-incompatible-pointer-types -fcommon -c -m32

OBJS := $(addprefix $(BUILD_DIR)/, memory.o swap.o page.o)

MM_OBJ := $(BUILD_DIR)/mm.o

.PHONY: mm.o clean

mm.o: $(MM_OBJ)

$(MM_OBJ): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(LD) -m elf_i386 -r -o $@ $^

$(BUILD_DIR)/page.o: page.S
	@mkdir -p $(BUILD_DIR)
	$(GCC) -m32 -traditional -c -o $@ $<

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(GCC) $(CCFLAG) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)

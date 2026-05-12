BUILD_DIR ?= $(CURDIR)/build/kernel/chr_drv

AR  := ar
LD  := ld
GCC := gcc
CCFLAG := -m32 -I../../include -nostdinc -ffreestanding -fno-pic -Wall -fomit-frame-pointer -fno-stack-protector -Wno-incompatible-pointer-types -fcommon -c

OBJS := $(addprefix $(BUILD_DIR)/, tty_io.o console.o keyboard.o kboard.o tty_ioctl.o)

CHR_DRV_A := $(BUILD_DIR)/chr_drv.a

.PHONY: chr_drv.a clean

chr_drv.a: $(CHR_DRV_A)

$(CHR_DRV_A): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(AR) rcs $@ $^
	sync

$(BUILD_DIR)/keyboard.o: keyboard.S
	@mkdir -p $(BUILD_DIR)
	$(GCC) -m32 -traditional -c -o $@ $<

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(GCC) $(CCFLAG) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)

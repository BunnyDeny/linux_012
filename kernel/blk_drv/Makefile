BUILD_DIR ?= $(CURDIR)/build/kernel/blk_drv

AR  := ar
LD  := ld
GCC := gcc
CCFLAG := -I../../include -nostdinc -ffreestanding -Wall -fomit-frame-pointer -c -fno-stack-protector -fno-pie -fno-pic -Wno-incompatible-pointer-types -fcommon -m32

OBJS := $(addprefix $(BUILD_DIR)/, hd.o ll_rw_blk.o floppy.o)

BLK_DRV_A := $(BUILD_DIR)/blk_drv.a

.PHONY: blk_drv.a clean

blk_drv.a: $(BLK_DRV_A)

$(BLK_DRV_A): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(AR) rcs $@ $^
	sync

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(GCC) $(CCFLAG) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)

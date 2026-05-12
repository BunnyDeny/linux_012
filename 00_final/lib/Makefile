BUILD_DIR ?= $(CURDIR)/build/lib

AR  := ar
LD  := ld
GCC := gcc
CCFLAG := -m32 -I../include -nostdinc -ffreestanding -fno-pic -Wall -fomit-frame-pointer -fno-stack-protector -Wno-incompatible-pointer-types -fcommon -c

OBJS := $(addprefix $(BUILD_DIR)/, \
	string.o ctype.o file.o open.o dup.o execve.o close.o wait.o _exit.o setsid.o)

LIB_A := $(BUILD_DIR)/lib.a

.PHONY: lib.a clean

lib.a: $(LIB_A)

$(LIB_A): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(AR) rcs $@ $^
	sync

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(GCC) $(CCFLAG) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)

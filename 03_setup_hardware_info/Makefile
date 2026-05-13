AS := as
LD := ld

LDFLAGS := -m elf_i386 -Ttext 0x0 -s --oformat binary

image: linux.img

linux.img: tools/build bootsect setup
	./tools/build bootsect setup

tools/build: tools/build.c
	gcc -o $@ $<

bootsect: bootsect.o
	$(LD) $(LDFLAGS) -o $@ $<

bootsect.o: bootsect.S
	$(AS) --32 -o $@ $<

setup: setup.o
	$(LD) $(LDFLAGS) -e _start_setup -o $@ $<

setup.o: setup.S
	$(AS) --32 -o $@ $<

clean:
	rm -f *.o
	rm -f bootsect
	rm -f setup
	rm -f tools/build
	rm -f linux.img


default:
	make -r build/mikan.img

build:
	mkdir build

util/hankaku.nim: util/hankaku.txt Makefile
	nim c -r util/hankaku2nim.nim

build/ipl.bin: src/asm/ipl.nasm Makefile build
	nasm -f bin src/asm/ipl.nasm -o build/ipl.bin -l build/ipl.lst

build/asmhead.bin: src/asm/asmhead.nasm Makefile build
	nasm -f bin src/asm/asmhead.nasm -o build/asmhead.bin -l build/asmhead.lst

build/nasmfunc.o: src/asm/nasmfunc.nasm Makefile
	nasm -f elf src/asm/nasmfunc.nasm -o build/nasmfunc.o -l build/nasmfunc.lst

build/bootpack.bin: src/nim/*.nim util/hankaku.nim src/nim/bootpack.nim.cfg Makefile build
	nim c -d:release src/nim/bootpack.nim
	i686-linux-gnu-ld -m elf_i386 -e MikanMain -o build/bootpack.bin -T src/mikan.ld build/srccache/*.c.o

build/mikan.sys: build/asmhead.bin build/bootpack.bin Makefile
	cat build/asmhead.bin build/bootpack.bin > build/mikan.sys

build/mikan.img: build/ipl.bin build/mikan.sys Makefile
	mformat -f 1440 -C -B build/ipl.bin -i build/mikan.img ::
	mcopy build/mikan.sys -i build/mikan.img ::

run: build/mikan.img
	qemu-system-i386 -m 32 -vga std -monitor stdio -drive format=raw,file=build/mikan.img,if=floppy # -gdb tcp::10000 -S

clean:
	rm build/* -rf
	rm util/hankaku2nim
	rm util/hankaku.nim

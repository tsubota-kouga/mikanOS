
default:
	make -r build/mikan.img

util/hankaku.nim: util/hankaku.txt Makefile
	nim c -r util/hankaku2nim.nim

build/ipl.bin: src/asm/ipl.asm Makefile
	nasm -f bin src/asm/ipl.asm -o build/ipl.bin -l build/ipl.lst -g

build/asmhead.bin: src/asm/asmhead.asm Makefile
	nasm -f bin src/asm/asmhead.asm -o build/asmhead.bin -l build/asmhead.lst -g

build/nasmfunc.o: src/asm/nasmfunc.asm Makefile
	nasm -f elf src/asm/nasmfunc.asm -o build/nasmfunc.o -l build/nasmfunc.lst -g

build/bootpack.bin: src/nim/*.nim util/hankaku.nim src/nim/bootpack.nim.cfg build/nasmfunc.o Makefile
	nim c src/nim/bootpack.nim
	i686-linux-gnu-ld -m elf_i386 -e MikanMain -o build/bootpack.bin -T src/mikan.ld build/srccache/bootpack.c.o build/nasmfunc.o build/srccache/stdlib_system.c.o

build/mikan.sys: build/asmhead.bin build/bootpack.bin Makefile
	cat build/asmhead.bin build/bootpack.bin > build/mikan.sys

build/mikan.img: build/ipl.bin build/mikan.sys Makefile
	mformat -f 1440 -C -B build/ipl.bin -i build/mikan.img ::
	mcopy build/mikan.sys -i build/mikan.img ::

run: build/mikan.img
	qemu-system-i386 -m 32 -vga std -monitor stdio -drive format=raw,file=build/mikan.img,if=floppy # -gdb tcp::10000 -S

clean:
	rm -f build/* -rf

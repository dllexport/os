all: boot.bin loader.bin

loader.bin:
	nasm loader.asm -o loader.bin

boot.bin:
	nasm boot.asm -o boot.bin

burn:
	dd if=boot.bin of=hd64.img bs=512 count=1 conv=notrunc 
	dd if=loader.bin of=hd64.img bs=512 count=4 seek=2 conv=notrunc

run:
	/usr/local/bin/bochs -qf bochsrc.floppy

clean:
	rm -rf *.bin *.asm~ Makefile~ loader.bin boot.bin

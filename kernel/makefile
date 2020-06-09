all: system
	objcopy -I elf64-x86-64 -S -R ".note.gnu.property" -R ".eh_frame" -R ".comment" -O binary system kernel.bin

system:	head.o main.o 
	ld -b elf64-x86-64 -o system head.o main.o -T Kernel.lds 

main.o:	main.c
	gcc -fno-builtin -m64 -c main.c

head.o:	head.asm
	nasm -f elf64 -o head.o head.asm

clean:
	rm -rf *.o *.s~ *.s *.S~ *.c~ *.h~ system  Makefile~ Kernel.lds~ kernel.bin 
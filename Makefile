hello: hello.o
	gcc -o hello hello.o resolve_hostname.c -no-pie -lc
hello.o: hello.asm utils.asm
	nasm -g -F dwarf -f elf64 hello.asm -l hello.lst

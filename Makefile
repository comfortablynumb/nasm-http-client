http_client: http_client.o
	gcc -o http_client http_client.o resolve_hostname.c -no-pie -lc
http_client.o: http_client.asm utils.asm
	nasm -g -F dwarf -f elf64 http_client.asm -l http_client.lst

CC = gcc
CFLAGS = -Wall -m64

all: main.o encode.o decode.o
	$(CC) $(CFLAGS)  -o Huffman main.o encode.o decode.o

encode.o: encode.s
	nasm -f elf64 -o encode.o encode.s

decode.o: decode.s
	nasm -f elf64 -o decode.o decode.s

main.o: main.c
	$(CC) $(CFLAGS) -c -o main.o main.c

clean:
	rm -f *.o


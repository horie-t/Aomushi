CC = gcc

TARGET = aomushi.img

all : $(TARGET)

$(TARGET) : ipl.bin aomushi.sys
	mformat -i $(TARGET) -f 1440 -C -B ipl.bin ::
	mcopy -i $(TARGET) aomushi.sys ::

ipl.bin : ipl10.s ./binary.ld
	$(CC) -nostdlib ipl10.s -o ipl.bin -T binary.ld

aomushi.sys : asmhead.bin ./bootpack.hrb
	cat asmhead.bin ./bootpack.hrb > aomushi.sys

asmhead.bin : asmhead.s
	$(CC) -nostdlib asmhead.s -o asmhead.bin -T binary.ld

bootpack.hrb : bootpack.c
	$(CC) -march=i486 -m32 -nostdlib bootpack.c -o bootpack.hrb -T hrb.ld

run : $(TARGET)
	qemu-system-i386 -fda $(TARGET) -boot a

.PHONY : clean
clean :
	-rm -f $(TARGET) *.bin *.sys *.hrb *~


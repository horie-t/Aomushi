CC = gcc

TARGET = aomushi.img

all : $(TARGET)

$(TARGET) : ipl.bin
	mformat -f 1440 -C -B ipl.bin -i $(TARGET)

ipl.bin : ipl.s
	$(CC) -nostdlib ipl.s -o ipl.bin -T binary.ld

run :
	qemu-system-i386 -fda $(TARGET) -boot a

.PHONY : clean
clean :
	-rm -f $(TARGET) ipl.bin *~


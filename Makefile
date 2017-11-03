CC = gcc

TARGET = helloos.img

all : $(TARGET)

$(TARGET) : ipl.bin
	mformat -f 1440 -C -B ipl.bin -i helloos.img

ipl.bin : helloos.s
	$(CC) -nostdlib helloos.s -o ipl.bin -T binary.ld

run :
	qemu-system-i386 -fda helloos.img -boot a

.PHONY : clean
clean :
	-rm -f $(TARGET) ipl.bin *~


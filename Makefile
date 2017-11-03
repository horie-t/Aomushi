CC = gcc

TARGET = aomushi.img

all : $(TARGET)

$(TARGET) : ipl.bin aomushi.sys
	mformat -f 1440 -C -B ipl.bin -i $(TARGET)
	mount $(TARGET) /mnt -t msdos -o loop,fat=12,check=strict,uid=1000,gid=1000,debug
	cp aomushi.sys /mnt
	umount /mnt

ipl.bin : ipl.s
	$(CC) -nostdlib ipl.s -o ipl.bin -T binary.ld

aomushi.sys : aomushi.s
	$(CC) -nostdlib aomushi.s -o aomushi.sys -T binary.ld

run :
	qemu-system-i386 -fda $(TARGET) -boot a

.PHONY : clean
clean :
	-rm -f $(TARGET) ipl.bin aomushi.sys *~


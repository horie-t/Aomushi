CC = gcc

TARGET = aomushi.img

all : $(TARGET)

$(TARGET) : ipl.bin aomushi.sys hello.hrb hello2.hrb hello3.hrb bug1.hrb bug2.hrb
	mformat -i $(TARGET) -f 1440 -C -B ipl.bin ::
	mcopy -i $(TARGET) aomushi.sys ::
	mcopy -i $(TARGET) ipl10.s ::
	mcopy -i $(TARGET) Makefile ::
	mcopy -i $(TARGET) hello.hrb ::
	mcopy -i $(TARGET) hello2.hrb ::
	mcopy -i $(TARGET) hello3.hrb ::
	mcopy -i $(TARGET) bug1.hrb ::
	mcopy -i $(TARGET) bug2.hrb ::

ipl.bin : ipl10.s ./binary.ld
	$(CC) -nostdlib ipl10.s -o ipl.bin -T binary.ld

aomushi.sys : asmhead.bin bootpack.hrb
	cat asmhead.bin bootpack.hrb > aomushi.sys

asmhead.bin : asmhead.s
	$(CC) -nostdlib -T head.ld -o $@ $^

bootpack.hrb : bootpack.c naskfunc.s fifo.c hankaku.c dsctbl.c int.c memory.c timer.c mtask.c graphic.c window.c keyboard.c mouse.c sheet.c file.c console.c lib/aolib.c
	$(CC) -march=i486 -m32 -nostdlib -T hrb.ld -o $@ $^

hello.hrb : hello.s
	$(CC) -nostdlib -T app.ld -o $@ $^

hello2.hrb : hello2.s
	$(CC) -nostdlib -T app.ld -o $@ $^

hello3.hrb : hello3.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb.ld -o $@ $^

bug1.hrb : bug1.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb.ld -o $@ $^

bug2.hrb : bug2.c
	$(CC) -march=i486 -m32 -nostdlib -T hrb.ld -o $@ $^

run : $(TARGET)
	qemu-system-i386 -m 32 -fda $(TARGET) -boot a

.PHONY : clean
clean :
	-rm -f $(TARGET) *.bin *.sys *.hrb *~


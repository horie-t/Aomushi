CC = gcc

TARGET = aomushi.img

all : $(TARGET)

$(TARGET) : ipl.bin aomushi.sys hello.hrb hello2.hrb hello3.hrb hello4.hrb hello5.hrb \
		winhelo.hrb winhelo2.hrb winhelo3.hrb star1.hrb stars.hrb stars2.hrb lines.hrb walk.hrb \
		noodle.hrb beepdown.hrb color.hrb color2.hrb \
		crack7.hrb
	mformat -i $(TARGET) -f 1440 -C -B ipl.bin ::
	mcopy -i $(TARGET) aomushi.sys ::
	mcopy -i $(TARGET) ipl10.s ::
	mcopy -i $(TARGET) Makefile ::
	mcopy -i $(TARGET) hello.hrb ::
	mcopy -i $(TARGET) hello2.hrb ::
	mcopy -i $(TARGET) hello3.hrb ::
	mcopy -i $(TARGET) hello4.hrb ::
	mcopy -i $(TARGET) hello5.hrb ::
	mcopy -i $(TARGET) winhelo.hrb ::
	mcopy -i $(TARGET) winhelo2.hrb ::
	mcopy -i $(TARGET) winhelo3.hrb ::
	mcopy -i $(TARGET) star1.hrb ::
	mcopy -i $(TARGET) stars.hrb ::
	mcopy -i $(TARGET) stars2.hrb ::
	mcopy -i $(TARGET) lines.hrb ::
	mcopy -i $(TARGET) walk.hrb ::
	mcopy -i $(TARGET) noodle.hrb ::
	mcopy -i $(TARGET) beepdown.hrb ::
	mcopy -i $(TARGET) color.hrb ::
	mcopy -i $(TARGET) color2.hrb ::
	mcopy -i $(TARGET) crack7.hrb ::

ipl.bin : ipl10.s ./binary.ld
	$(CC) -nostdlib ipl10.s -o ipl.bin -T binary.ld

aomushi.sys : asmhead.bin bootpack.hrb
	cat asmhead.bin bootpack.hrb > aomushi.sys

asmhead.bin : asmhead.s
	$(CC) -nostdlib -T head.ld -o $@ $^

bootpack.hrb : bootpack.c naskfunc.s fifo.c hankaku.c dsctbl.c int.c memory.c timer.c \
		mtask.c graphic.c window.c keyboard.c mouse.c sheet.c file.c console.c lib/aolib.c
	$(CC) -march=i486 -m32 -nostdlib -T hrb_os.ld -o $@ $^

hello.hrb : hello.s
	$(CC) -nostdlib -T app.ld -o $@ $^

hello2.hrb : hello2.s
	$(CC) -nostdlib -T app.ld -o $@ $^

hello3.hrb : hello3.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

hello4.hrb : hello4.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

hello5.hrb : hello5.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

winhelo.hrb : winhelo.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

winhelo2.hrb : winhelo2.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

winhelo3.hrb : winhelo3.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

star1.hrb : star1.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

stars.hrb : stars.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

stars2.hrb : stars2.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

lines.hrb : lines.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

walk.hrb : walk.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

noodle.hrb : noodle.c a_nask.s lib/aolib.c
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

beepdown.hrb : beepdown.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

color.hrb : color.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

color2.hrb : color2.c a_nask.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

crack7.hrb : crack7.s
	$(CC) -march=i486 -m32 -nostdlib -T hrb_app.ld -o $@ $^

run : $(TARGET)
	qemu-system-i386 -m 32 -fda $(TARGET) -boot a

.PHONY : clean
clean :
	-rm -f $(TARGET) *.bin *.sys *.hrb *~

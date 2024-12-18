/* bootpackのメイン */

#include "bootpack.h"
#include <stdio.h>

extern struct FIFO8 keyfifo, mousefifo;
void enable_mouse(void);
void init_keyboard(void);

void HariMain(void)
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	char s[40], mcursor[256], keybuf[32], mousebuf[128];
	int mx, my, i;

	init_gdtidt();
	init_pic();
	io_sti(); /* IDT/PIC的初始化已经完成，于是开放CPU的中断 */

	fifo8_init(&keyfifo, 32, keybuf);
	fifo8_init(&mousefifo, 128, mousebuf);
	io_out8(PIC0_IMR, 0xf9); /* 开放PIC1和键盘中断(11111001) */
	io_out8(PIC1_IMR, 0xef); /* 开放鼠标中断(11101111) */

	init_keyboard();

	init_palette();
	init_screen8(binfo->vram, binfo->scrnx, binfo->scrny);
	mx = (binfo->scrnx - 16) / 2; /* 计算画面中心坐标 */
	my = (binfo->scrny - 28 - 16) / 2;
	init_mouse_cursor8(mcursor, COL8_008484);
	putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
	sprintf(s, "(%d, %d)", mx, my);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, s);

	enable_mouse();

	for (;;) {
		io_cli();
		if (fifo8_status(&keyfifo) + fifo8_status(&mousefifo) == 0) {
			io_stihlt();
		} else {
			if (fifo8_status(&keyfifo) != 0) {
				i = fifo8_get(&keyfifo);
				io_sti();
				sprintf(s, "%02X", i);
				boxfill8(binfo->vram, binfo->scrnx, COL8_008484,  0, 16, 15, 31);
				putfonts8_asc(binfo->vram, binfo->scrnx, 0, 16, COL8_FFFFFF, s);
			} else if (fifo8_status(&mousefifo) != 0) {
				i = fifo8_get(&mousefifo);
				io_sti();
				sprintf(s, "%02X", i);
				boxfill8(binfo->vram, binfo->scrnx, COL8_008484, 32, 16, 47, 31);
				putfonts8_asc(binfo->vram, binfo->scrnx, 32, 16, COL8_FFFFFF, s);
			}
		}
	}
}

#define PORT_KEYDAT				0x0060
#define PORT_KEYSTA				0x0064
#define PORT_KEYCMD				0x0064
#define KEYSTA_SEND_NOTREADY	0x02
#define KEYCMD_WRITE_MODE		0x60
#define KBC_MODE				0x47  //用于启用键盘的中断功能，并使用默认的扫描码集

/*
首先我们来看函数wait_KBC_sendready。它的作用是，让键盘控制电路(keyboard controller,KBC)做好准备动作，等待控制指令的到来。
为什么要做这个工作呢?是因为虽然CPU的电路很快，但键盘控制电路却没有那么快。如果CPU不顾设备接收数据的能力，只是一个劲儿地发指令的话，
有些指令会得不到执行，从而导致错误的结果。如果键盘控制电路可以接受CPU指令了，
CPU从设备号码0x0064处所读取的数据的倒数第二位(从低位开始数的第二位)应该是0。在确认到这一位是0之前，程序一直通过for语句循环查询。
 */
void wait_KBC_sendready(void)
{
	/* 让键盘控制电路( keyboard controller，KBC)做好准备动作，等待控制指令到来。等待键盘控制电路准备完毕 */
	for (;;) {
		if ((io_in8(PORT_KEYSTA) & KEYSTA_SEND_NOTREADY) == 0) {
			break;
		}
	}
	return;
}
/*
下面看函数init_keyboard。它所要完成的工作很简单，也就是一边确认可否往键盘控制电路传送信息，
一边发送模式设定指令，指令中包含着要设定为何种模式。模式设定的指令是0x60，利用鼠标模式的模式号码是0x47，
当然这些数值必须通过调查才能知道。我们可以从老地方得到这些数据。
 */
void init_keyboard(void)
{
	/* 初始化键盘控制电路 */
	wait_KBC_sendready();
	io_out8(PORT_KEYCMD, KEYCMD_WRITE_MODE);// 设置键盘工作模式为写模式
	wait_KBC_sendready();//再次调用 wait_KBC_sendready 函数，确保键盘控制器已经准备好接收下一个数据。
	io_out8(PORT_KEYDAT, KBC_MODE);
	return;
}

  /*
  现在，我们开始发送激活鼠标的指令。所谓发送鼠标激活指令，归根到底还是要向键盘控制器发送指令。

  这个函数与init_keyboard函数非常相似。不同点仅在于写入的数据不同。如果在键盘控制电路发送指令0xd4，下一个数据就会自动发送给鼠标。我们根据这一特性来发送激活鼠标的指令。
  另一方面，一直等着机会露脸的鼠标先生，收到激活指令以后，马上就给CPU发送答复信息：“OK，从现在开始就要不停地发送鼠标信息了，拜托了。”这个答复信息就是0xfa。
  因为这个数据马上就跟着来了，即使我们保持鼠标完全不动，也一定会产生一个鼠标中断。
   */
#define KEYCMD_SENDTO_MOUSE		0xd4
#define MOUSECMD_ENABLE			0xf4

void enable_mouse(void)
{
	/* 激活鼠标 */
	wait_KBC_sendready();
	io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE);
	wait_KBC_sendready();
	io_out8(PORT_KEYDAT, MOUSECMD_ENABLE);
	return; /* 顺利的话，键盘控制器会返回ACK(0xfa) */
}
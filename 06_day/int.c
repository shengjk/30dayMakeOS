/*初始化关系 */

#include "bootpack.h"

void init_pic(void)
/* PIC初始化  programmable interrupt controller

在设计上，CPU单独只能处理一个中断，这不够用，所以IBM的大叔们在设计电脑时，就在主板上增设了几个辅助芯片。现如今它们已经被集成在一个芯片组里了。
PIC是将8个中断信号组合成一个中断信号的装置。PIC监视着输入管脚的8个中断信号，只要有一个中断信号进来，就将唯一的输出管脚信号变成ON，并通知给CPU。
IBM的大叔们想要通过增加PIC来处理更多的中断信号，他们认为电脑会有8个以上的外部设备，所以就把中断信号设计成了15个，并为此增设了2个PIC。

PIC0 是 主PIC
PIC1 是 从PIC

IRQ interrupt request
PIC的寄存器 8位， IMR :interrupte mask register “中断屏蔽寄存器”。
8位分别对应8路IRQ信号。如果某一位的值是1，则该位所对应的中断信号被屏蔽，PIC就忽视该路信号。
这主要是因为，正在对中断设定进行更改时，如果再接受别的中断会引起混乱，为了防止这种情况的发生，就必须屏蔽中断。
还有，如果某个IRQ没有连接任何设备的话，静电干扰等也可能会引起反应，导致操作系统混乱，所以也要屏蔽掉这类干扰。

ICW: initial contrl word 初始化控制数据

只有在电脑的CPU里，word这个词才是16位的意思，在别的设备上，有时指8位，有时也会指32位。PIC不是仅为电脑的CPU而设计的控制芯片，其他种类的CPU也能使用，所以这里word的意思也并不是我们觉得理所当然的16位。

ICW有4个，分别编号为1~4，共有4个字节的数据。ICW1和ICW4与PIC主板配线方式、中断信号的电气特性等有关，所以就不详细说明了。
电脑上设定的是上述程序所示的固定值，不会设定其他的值。如果故意改成别的什么值的话，早期的电脑说不定会烧断保险丝，或者冒烟；
最近的电脑，对这种设定起反应的电路本身被省略了，所以不会有任何反应。
ICW3是有关主-从连接的设定，对主PIC而言，第几号IRQ与从PIC相连，是用8位来设定的。如果把这些位全部设为1，那么主PIC就能驱动8个从PIC(那样的话，最大就可能有64个IRQ)，
但我们所用的电脑并不是这样的，所以就设定成00000100。另外，对从PIC来说，该从PIC与主PIC的第几号相连，用3位来设定。因为硬件上已经不可能更改了，如果软件上设定不一致的话，只会发生错误，
所以只能维持现有设定不变。


因此不同的操作系统可以进行独特设定的就只有ICW2了。这个ICW2，决定了IRQ以哪一号中断通知CPU，利用它就可以由PIC来设定中断号了。


这次是以 INT 0x20~0x2f 接收中断信号 IRQ0~15 而设定的。这里大家可能又会有疑问了。“直接用 INT 0x00~0x0f 就不行吗？
这样与 IRQ 的号码不就一样了吗？为什么非要加上 0x20？”不要着急，先等笔者说完再问嘛。
是这样的，INT 0x00~0x1f 不能用于 IRQ，仅此而已。
之所以不能用，是因为应用程序想要对操作系统干坏事的时候，CPU 内部会自动产生 INT 0x00~0x1f，
如果 IRQ 与这些号码重复了，CPU 就分不清它到底是 IRQ，还是 CPU 的系统保护通知。

鼠标是IRQ12 键盘是IRQ1


具体来说，PIC0_OCW2 是指第一个PIC（通常称为主PIC，Master PIC）的操作控制字2（Operation Control Word 2）。OCW2 用于控制中断处理过程中的一些特定操作，如中断结束（Interrupt End，EOI）命令、旋转优先级、特殊屏蔽等。
*/

{
	io_out8(PIC0_IMR,  0xff  ); /* 禁止所有中断 */
	io_out8(PIC1_IMR,  0xff  ); /* 禁止所有中断 */

	io_out8(PIC0_ICW1, 0x11  ); /* 边缘触发模式（edge trigger mode） */
	io_out8(PIC0_ICW2, 0x20  ); /* IRQ0-7由INT20-27接收 */
	io_out8(PIC0_ICW3, 1 << 2); /* PIC1由IRQ2相连 */
	io_out8(PIC0_ICW4, 0x01  ); /* 无缓冲区模式 */

	io_out8(PIC1_ICW1, 0x11  ); /* 边缘触发模式（edge trigger mode） */
	io_out8(PIC1_ICW2, 0x28  ); /* IRQ8-15由INT28-2f接收 */
	io_out8(PIC1_ICW3, 2     ); /* PIC1由IRQ2连接 */
	io_out8(PIC1_ICW4, 0x01  ); /* 无缓冲区模式 */

	io_out8(PIC0_IMR,  0xfb  ); /* 11111011 PIC1以外全部禁止 */
	io_out8(PIC1_IMR,  0xff  ); /* 11111111 禁止所有中断 */

	return;
}

void inthandler21(int *esp)
/* 来自PS/2键盘的中断 */
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 21 (IRQ-1) : PS/2 keyboard");
	for (;;) {
		io_hlt();
	}
}

void inthandler2c(int *esp)
/* 来自PS/2鼠标的中断 */
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 2C (IRQ-12) : PS/2 mouse");
	for (;;) {
		io_hlt();
	}
}

void inthandler27(int *esp)
/* PIC0中断的不完整策略 */
/* 这个中断在Athlon64X2上通过芯片组提供的便利，只需执行一次 */
/* 这个中断只是接收，不执行任何操作 */
/* 为什么不处理？
	→  因为这个中断可能是电气噪声引发的、只是处理一些重要的情况。*/
{
	io_out8(PIC0_OCW2, 0x67); /* 通知PIC的IRQ-07（参考7-1） */
	return;
}

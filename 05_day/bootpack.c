#include <stdio.h>

void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1);
void init_screen(char *vram, int x, int y);
void putfont8(char *vram, int xsize, int x, int y, char c, char *font);
void putfonts8_asc(char *vram, int xsize, int x, int y, char c, unsigned char *s);
void init_mouse_cursor8(char *mouse, char bc);
void putblock8_8(char *vram, int vxsize, int pxsize, int pysize, int px0, int py0, char *buf, int bxsize);

#define COL8_000000		0
#define COL8_FF0000		1
#define COL8_00FF00		2
#define COL8_FFFF00		3
#define COL8_0000FF		4
#define COL8_FF00FF		5
#define COL8_00FFFF		6
#define COL8_FFFFFF		7
#define COL8_C6C6C6		8
#define COL8_840000		9
#define COL8_008400		10
#define COL8_848400		11
#define COL8_000084		12
#define COL8_840084		13
#define COL8_008484		14
#define COL8_848484		15

struct BOOTINFO {
	char cyls, leds, vmode, reserve;
	short scrnx, scrny;
	char *vram;
};
/*
按这种分段方法，为了表示一个段，需要有以信息。
□段的大小是多少
□段的起始地址在哪里
□段的管理属性（禁止写入，禁止执行，系统专用等）

在x86架构中，CPU通过8个字节来管理段信息。具体来说，每个段描述符（Segment Descriptor）占用8个字节，
其中包含了段的基地址、段限长、访问权限等信息。
这些段描述符被组织在全局描述符表（Global Descriptor Table，GDT）或局部描述符表（Local Descriptor Table，LDT）中，
CPU通过这些表来访问内存中的不同段。

以CPU资料为基础写成 结构体形式


CPU用8个字节（=64位）的数据来表示这些信息。但是，用于指定段的寄存器只有16位。
或许有人会猜想在32位模式下，段寄存器会扩展到64位，但事实上段寄存器仍然是16位。

本来应该能够处理0~65535范围的数，但由于CPU设计上的原因，段寄存器的低3位不能使用。因此能够使用的段号只有13位，能够处理的就只有位于0~8191的区域了。

GDT是“global（segment）descriptor table”的缩写，意思是全局段号记录表。将这些数据整齐地排列在内存的某个地方，
然后将内存的起始地址和有效设定个数放在CPU内被称作GDTR的特殊寄存器中，设定就完成了。


在x86架构中，全局描述符表（Global Descriptor Table, GDT）是一个非常重要的概念，
它用于定义内存中不同段（如代码段、数据段、堆栈段等）的访问权限和基地址。GDT的主要目的是提供内存保护和安全机制，确保不同的程序或任务只能访问它们被授权的内存区域。
以下是GDT在x86架构中的几个主要作用：

内存保护：GDT允许操作系统为不同的段设置不同的访问权限，例如只读、只写、可执行等。这样可以防止一个程序意外地修改另一个程序的数据或代码，从而提高系统的稳定性和安全性。
段基地址和界限：GDT中的每个描述符都包含了一个段的基地址和界限值。这些信息用于在内存中定位和访问特定的段。通过GDT，CPU可以快速地确定一个内存地址是否属于某个特定的段，以及该段是否允许访问。
任务切换：在多任务环境中，GDT还用于支持任务切换。每个任务可以有自己的GDT，当任务切换时，CPU会加载新任务的GDT，从而确保新任务能够正确地访问其所需的内存段。
特权级检查：GDT中的描述符还包含了特权级信息，这对于操作系统的特权级保护机制至关重要。不同的特权级对应不同的操作权限，例如内核态（Ring 0）可以执行所有指令，而用户态（Ring 3）则受到更多限制。
虚拟内存管理：虽然GDT本身并不直接参与虚拟内存管理，但它与分页机制（通过页目录和页表）一起工作，确保虚拟地址到物理地址的正确映射。
总之，GDT是x86架构中实现内存管理和保护的基础，它使得操作系统能够有效地管理和控制内存访问，从而提高系统的安全性和稳定性。
*/
/* GDT
□段的大小是多少
□段的起始地址在哪里
□段的管理属性（禁止写入，禁止执行，系统专用等）

base地址分三段：主要是为了与80286时代的程序兼容。有了这样的规格，80286用的操作系统，也可以不用修改就在386以后的CPU上运行了。
* */

struct SEGMENT_DESCRIPTOR {
	short limit_low, base_low;
	char base_mid, access_right;
	char limit_high, base_high;
};
/* IDT
其实总结来说就是：要使用鼠标，就必须要使用中断。所以，我们必须设定IDT。 IDT记录了0~255的中断号码与调用函数的对应关系，
比如说发生了123号中断，就调用〇×函数，其设定方法与GDT很相似（或许是因为使用同样的方法能简化CPU的电路）
*/

struct GATE_DESCRIPTOR {
	short offset_low, selector;
	char dw_count, access_right;
	short offset_high;
};

void init_gdtidt(void);
void set_segmdesc(struct SEGMENT_DESCRIPTOR *sd, unsigned int limit, int base, int ar);
void set_gatedesc(struct GATE_DESCRIPTOR *gd, int offset, int selector, int ar);
void load_gdtr(int limit, int addr);
void load_idtr(int limit, int addr);

void HariMain(void)
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) 0x0ff0;
	char s[40], mcursor[256];
	int mx, my;

	init_palette();
 /* 使用箭头，可以将“xsize=(*binfo).scmx;”写成“xsize=binfo->scmx;”，简单又方便。*/
	init_screen(binfo->vram, binfo->scrnx, binfo->scrny);

	/* 显示鼠标 */
	mx = (binfo->scrnx - 16) / 2; /* 计算画面的中心坐标*/
	my = (binfo->scrny - 28 - 16) / 2;
	init_mouse_cursor8(mcursor, COL8_008484);
	putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);

	putfonts8_asc(binfo->vram, binfo->scrnx,  8,  8, COL8_FFFFFF, "ABC 123");
	putfonts8_asc(binfo->vram, binfo->scrnx, 31, 31, COL8_000000, "Haribote OS.");
	putfonts8_asc(binfo->vram, binfo->scrnx, 30, 30, COL8_FFFFFF, "Haribote OS.");

	/*sprintf函数的使用方法是：$sprintf(地址，格式，值，值，值，......) $。这里的地址指定所生成字符串的存放地址。格式基本上只是单纯的字符串，如果有%d这类记号，就置换成后面的值的内容。除了%d，还有%s，%x等符号，它们用于指定数值以什么方式变换为字符串。%d将数值作为十进制数转化为字符串，%x将数值作为十六进制数转化为字符串。*/
	sprintf(s, "scrnx = %d", binfo->scrnx);
	putfonts8_asc(binfo->vram, binfo->scrnx, 16, 64, COL8_FFFFFF, s);

	for (;;) {
		io_hlt();
	}
}

void init_palette(void)
{
	static unsigned char table_rgb[16 * 3] = {
		0x00, 0x00, 0x00,	/*  0:黑 */
		0xff, 0x00, 0x00,	/*  1:梁红 */
		0x00, 0xff, 0x00,	/*  2:亮绿 */
		0xff, 0xff, 0x00,	/*  3:亮黄 */
		0x00, 0x00, 0xff,	/*  4:亮蓝 */
		0xff, 0x00, 0xff,	/*  5:亮紫 */
		0x00, 0xff, 0xff,	/*  6:浅亮蓝 */
		0xff, 0xff, 0xff,	/*  7:白 */
		0xc6, 0xc6, 0xc6,	/*  8:亮灰 */
		0x84, 0x00, 0x00,	/*  9:暗红 */
		0x00, 0x84, 0x00,	/* 10:暗绿 */
		0x84, 0x84, 0x00,	/* 11:暗黄 */
		0x00, 0x00, 0x84,	/* 12:暗青 */
		0x84, 0x00, 0x84,	/* 13:暗紫 */
		0x00, 0x84, 0x84,	/* 14:浅暗蓝 */
		0x84, 0x84, 0x84	/* 15:暗灰 */
	};
	set_palette(0, 15, table_rgb);
	return;

	/* C语言中的static char语句只能用于数据，相当于汇编中的DB指令 */
}

void set_palette(int start, int end, unsigned char *rgb)
{
	int i, eflags;
	eflags = io_load_eflags();	/* 记录中断许可标志的值 */
	io_cli(); 					/* 将中断许可标志置为0,禁止中断 */
	io_out8(0x03c8, start);
	for (i = start; i <= end; i++) {
		io_out8(0x03c9, rgb[0] / 4);
		io_out8(0x03c9, rgb[1] / 4);
		io_out8(0x03c9, rgb[2] / 4);
		rgb += 3;
	}
	io_store_eflags(eflags);	/* 复原中断许可标志 */
	return;
}

void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1)
{
	int x, y;
	for (y = y0; y <= y1; y++) {
		for (x = x0; x <= x1; x++)
			vram[y * xsize + x] = c;
	}
	return;
}

void init_screen(char *vram, int x, int y)
{
	boxfill8(vram, x, COL8_008484,  0,     0,      x -  1, y - 29);
	boxfill8(vram, x, COL8_C6C6C6,  0,     y - 28, x -  1, y - 28);
	boxfill8(vram, x, COL8_FFFFFF,  0,     y - 27, x -  1, y - 27);
	boxfill8(vram, x, COL8_C6C6C6,  0,     y - 26, x -  1, y -  1);

	boxfill8(vram, x, COL8_FFFFFF,  3,     y - 24, 59,     y - 24);
	boxfill8(vram, x, COL8_FFFFFF,  2,     y - 24,  2,     y -  4);
	boxfill8(vram, x, COL8_848484,  3,     y -  4, 59,     y -  4);
	boxfill8(vram, x, COL8_848484, 59,     y - 23, 59,     y -  5);
	boxfill8(vram, x, COL8_000000,  2,     y -  3, 59,     y -  3);
	boxfill8(vram, x, COL8_000000, 60,     y - 24, 60,     y -  3);

	boxfill8(vram, x, COL8_848484, x - 47, y - 24, x -  4, y - 24);
	boxfill8(vram, x, COL8_848484, x - 47, y - 23, x - 47, y -  4);
	boxfill8(vram, x, COL8_FFFFFF, x - 47, y -  3, x -  4, y -  3);
	boxfill8(vram, x, COL8_FFFFFF, x -  3, y - 24, x -  3, y -  3);
	return;
}

/* 字符用 8*16 的长方形像素点阵来表示
这样的话，8 bit 是一个字节，而一个字符是 16 个字节
*/
void putfont8(char *vram, int xsize, int x, int y, char c, char *font)
{
	int i;
	char *p, d /* data */;
	for (i = 0; i < 16; i++) {
		p = vram + (y + i) * xsize + x;
		d = font[i];
		if ((d & 0x80) != 0) { p[0] = c; }
		if ((d & 0x40) != 0) { p[1] = c; }
		if ((d & 0x20) != 0) { p[2] = c; }
		if ((d & 0x10) != 0) { p[3] = c; }
		if ((d & 0x08) != 0) { p[4] = c; }
		if ((d & 0x04) != 0) { p[5] = c; }
		if ((d & 0x02) != 0) { p[6] = c; }
		if ((d & 0x01) != 0) { p[7] = c; }
	}
	return;
}

void putfonts8_asc(char *vram, int xsize, int x, int y, char c, unsigned char *s)
{
	extern char hankaku[4096];   /* 使用外部字体 hankaku 总共256字符，依照一般的ASCII字符编码，每个字符16个字节*/
	/* C语言中，字符串都是以0x00结尾 */
	for (; *s != 0x00; s++) {
		putfont8(vram, xsize, x, y, c, hankaku + *s * 16);
		x += 8;
	}
	return;
}

void init_mouse_cursor8(char *mouse, char bc)
/* 准备鼠标指针，其大小为（16x16） */
{
	static char cursor[16][16] = {
		"**************..",
		"*OOOOOOOOOOO*...",
		"*OOOOOOOOOO*....",
		"*OOOOOOOOO*.....",
		"*OOOOOOOO*......",
		"*OOOOOOO*.......",
		"*OOOOOOO*.......",
		"*OOOOOOOO*......",
		"*OOOO**OOO*.....",
		"*OOO*..*OOO*....",
		"*OO*....*OOO*...",
		"*O*......*OOO*..",
		"**........*OOO*.",
		"*..........*OOO*",
		"............*OO*",
		".............***"
	};
	int x, y;

	for (y = 0; y < 16; y++) {
		for (x = 0; x < 16; x++) {
			if (cursor[y][x] == '*') {
				mouse[y * 16 + x] = COL8_000000;
			}
			if (cursor[y][x] == 'O') {
				mouse[y * 16 + x] = COL8_FFFFFF;
			}
			if (cursor[y][x] == '.') {
				mouse[y * 16 + x] = bc; // bc 指 back-color 背景色
			}
		}
	}
	return;
}

//要将背景色显示出来，还需要作成下面这个函数。其实很简单，只要将buf中的数据复制到vram中去就可以了
     /*
里面的变量有很多，其中vram和vxsize是关于VRAM的信息。
他们的值分别是0xa0000和320。pxsize和 pysize是想要显示的图形（picture）的大小，鼠标指针的大小是16x16，
所以这两个值都是16。px0和py0指定图形在画面上的显示位置。最后的out和bxsize分别指定图形的存放地址和每一行含有的像素数。
bxsize和pxsize大体相同，但也有时候想放入不同的值，所以还是要分别指定这两个值。
*/
void putblock8_8(char *vram, int vxsize, int pxsize,
	int pysize, int px0, int py0, char *buf, int bxsize)
{
	int x, y;
	for (y = 0; y < pysize; y++) {
		for (x = 0; x < pxsize; x++) {
			vram[(py0 + y) * vxsize + (px0 + x)] = buf[y * bxsize + x];
		}
	}
	return;
}
/*
GDT是“global (segment) descriptor table”的缩写，意思是全局段号记录表。将这些数据整齐地排列在内存的某个地方，
然后将内存的起始地址和有效设定个数放在CPU内被称作GDTR的特殊寄存器中，设定就完成了。

另外，IDT是“interrupt descriptor table”的缩写，直译过来就是“中断记录表”。
当CPU遇到外部状况变化，或是内部偶然发生某些错误时，会临时切换过去处理这种突发事件。这就是中断功能。

各个设备有变化时就产生中断，中断发生后，CPU暂时停止正在处理的任务，并做好接下来能够继续处理的准备，转而执行中断程序。
中断程序执行完以后，再调用事先设定好的函数，返回处理中的任务。正是得益于中断机制，
CPU可以不用一直查询键盘，鼠标，网卡等设备的状态，将精力集中在处理任务上。

其实总结来说就是：要使用鼠标，就必须要使用中断。所以，我们必须设定IDT。IDT记录了0~255的中断号码与调用函数的对应关系，
比如说发生了123号中断，就调用OX函数，其设定方法与GDT很相似（或许是因为使用同样的方法能简化CPU的电路）。
如果段的设定还没顺利完成就设定IDT的话，会比较麻烦，所以必须先进行GDT的设定。


在计算机系统中，GDT（Global Descriptor Table，全局描述符表）和IDT（Interrupt Descriptor Table，中断描述符表）是非常重要的组成部分，它们分别用于管理内存段和中断处理。
GDT是一个数据结构，用于定义系统中所有段的属性，如代码段、数据段、堆栈段等。每个段都有一个描述符，包含了段的基地址、段限长、访问权限等信息。在保护模式下，CPU通过GDT来访问内存中的不同段。
IDT则是一个中断向量表，用于存储不同中断类型的处理程序的入口地址。当CPU接收到一个中断信号时，它会根据中断类型查找IDT，然后跳转到相应的处理程序执行。

在操作系统启动时，通常需要先设置GDT，然后再设置IDT。这是因为IDT中的中断处理程序可能需要访问内存中的不同段，
如果GDT没有正确设置，那么中断处理程序可能无法正确地访问内存，从而导致系统错误。
因此，在设置IDT之前，必须确保GDT已经正确设置，这样才能保证中断处理程序能够正确地访问内存，从而避免系统错误

IDT（中断描述符表）在计算机系统中用于管理中断处理。当CPU接收到一个中断信号时，它会根据中断类型查找IDT，
然后跳转到相应的中断处理程序执行。中断处理程序通常需要访问内存中的不同段，例如代码段、数据段、堆栈段等，以便执行相应的操作。
*/

void init_gdtidt(void)
{
/*变量gdt被赋值0x00270000，就是说要将0x270000~0x27ffff设为GDT。
在x86架构中，每个段描述符通常是8字节（64位）长。段描述符包含了关于内存段的信息，比如段的基址、段的界限、段的访问权限和其他属性。
所以 8192个段，总共 8192*8=65536 字节
至于为什么用这个地址，其实那只是笔者随便作出的决定，并没有特殊的意义。从内存分布图可以看出这一块地方并没有被使用。
*/

	struct SEGMENT_DESCRIPTOR *gdt = (struct SEGMENT_DESCRIPTOR *) 0x00270000;
/* IDT 也是一样的，0x26f800 ~ 0x26ffff
      IDT记录了0~255的中断号码与调用函数的对应关系
*/
	struct GATE_DESCRIPTOR    *idt = (struct GATE_DESCRIPTOR    *) 0x0026f800;
	int i;

	/* GDT初始化
	*/
	for (i = 0; i < 8192; i++) {
		set_segmdesc(gdt + i, 0, 0, 0); // 地址加1，内存不一定加1，取决于 gdt 本身大小
	}
	/*
段号为1和2的两个段进行的设定。段号为1的段，上限值为0xffffffff(即大小正好是4GB)，地址是0。它表示的是CPU所能管理的全部内存本身。段的属性设为0x4092，它的含义我们留待明天再说。
下面来看看段号为2的段，它的大小是512KB，地址是0x280000。这正好是为bootpack.hrb而准备的。用这个段，就可以执行bootpack.hrb。因为bootpack.hrb是以ORG 0为前提翻译成的机器语言。

段的属性 0x409
*/

	set_segmdesc(gdt + 1, 0xffffffff, 0x00000000, 0x4092);
	set_segmdesc(gdt + 2, 0x0007ffff, 0x00280000, 0x409a);
	//这是因为依照常规，C语言里不能给GDTR赋值，所以要借助汇编语言的力量，仅此而已。”
	load_gdtr(0xffff, 0x00270000);

	/* IDT初始化 */
	for (i = 0; i < 256; i++) {
		set_gatedesc(idt + i, 0, 0, 0);
	}
	load_idtr(0x7ff, 0x0026f800);

	return;
}

void set_segmdesc(struct SEGMENT_DESCRIPTOR *sd, unsigned int limit, int base, int ar)
{
	if (limit > 0xfffff) {
		ar |= 0x8000; /* G_bit = 1 */
		limit /= 0x1000;
	}
	sd->limit_low    = limit & 0xffff;
	sd->base_low     = base & 0xffff;
	sd->base_mid     = (base >> 16) & 0xff;
	sd->access_right = ar & 0xff;
	sd->limit_high   = ((limit >> 16) & 0x0f) | ((ar >> 8) & 0xf0);
	sd->base_high    = (base >> 24) & 0xff;
	return;
}

void set_gatedesc(struct GATE_DESCRIPTOR *gd, int offset, int selector, int ar)
{
	gd->offset_low   = offset & 0xffff;
	gd->selector     = selector;
	gd->dw_count     = (ar >> 8) & 0xff;
	gd->access_right = ar & 0xff;
	gd->offset_high  = (offset >> 16) & 0xffff;
	return;
}

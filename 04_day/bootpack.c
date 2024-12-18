/*
既然说到这里，那我们再介绍点相关知识，“chari;” 是类似AL的1字节变量，“short i;”是类似AX的2字节变量，“int i;”是类似EAX的4字节变量。
而不管是“char *p”，还是“short *p”，还是“int *p”，变量p都是4字节。这是因为p是用于记录地址的变量。 p 是地址变量，4个字节
在汇编语言中，地址也像ECX一样，用4字节的寄存器来指定，所以也是4字节。

指针是表示内存地址的数值。在 C语言中，普通的数值和表示内存地址的数值被认为是两种不同的东西

在C语言中，*(p+i) 和 p[i] 是等价的，它们都表示访问指针 p 所指向的内存地址偏移 i 个位置后的内存单元的值。这种用法在汇编语言中可以理解为使用基址加偏移量的寻址方式。
p[0] 等价于 *p


char a[3];
C语言中，如果这样写，那么a就成了常数，以汇编的语言来讲就是标志符。标志符的值当然就意味着地址。并且还准备了“RESB 3”。总结一下，上面的叙述就相当于汇编里的这个语句：
a:
	RESB 3
nask中RESB的内容能够保证是0，但C语言中不能保证，所以里面说不定含有某种垃圾数据。


未指定型是指没有特别指定时，可由编译器决定是unsigned还是signed。


在汇编语言中，DB 是一个指令，它是 “Define Byte” 的缩写。DB 指令用于在数据段中定义一个或多个字节的存储空间，并且可以初始化这些字节为特定的值。 DB 指令常用于初始化变量、常量、字符串等数据。
在汇编语言中，RESB 是一个指令，它是 “Reserve Byte” 的缩写，用于在汇编程序中分配存储空间。RESB 指令告诉汇编器在数据段中保留一定数量的字节，并且将这些字节初始化为0。

 */

void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1);

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

void HariMain(void)
{
	char *vram;/* 声明变量vram、用于BYTE [...]地址 */
	int xsize, ysize;

	init_palette();/* 设定调色板 */
	vram = (char *) 0xa0000;/* 地址变量赋值 */
	xsize = 320;
	ysize = 200;

	/* 根据 0xa0000 + x + y * 320 计算坐标 8*/
	boxfill8(vram, xsize, COL8_008484,  0,         0,          xsize -  1, ysize - 29);
	boxfill8(vram, xsize, COL8_C6C6C6,  0,         ysize - 28, xsize -  1, ysize - 28);
	boxfill8(vram, xsize, COL8_FFFFFF,  0,         ysize - 27, xsize -  1, ysize - 27);
	boxfill8(vram, xsize, COL8_C6C6C6,  0,         ysize - 26, xsize -  1, ysize -  1);

	boxfill8(vram, xsize, COL8_FFFFFF,  3,         ysize - 24, 59,         ysize - 24);
	boxfill8(vram, xsize, COL8_FFFFFF,  2,         ysize - 24,  2,         ysize -  4);
	boxfill8(vram, xsize, COL8_848484,  3,         ysize -  4, 59,         ysize -  4);
	boxfill8(vram, xsize, COL8_848484, 59,         ysize - 23, 59,         ysize -  5);
	boxfill8(vram, xsize, COL8_000000,  2,         ysize -  3, 59,         ysize -  3);
	boxfill8(vram, xsize, COL8_000000, 60,         ysize - 24, 60,         ysize -  3);

	boxfill8(vram, xsize, COL8_848484, xsize - 47, ysize - 24, xsize -  4, ysize - 24);
	boxfill8(vram, xsize, COL8_848484, xsize - 47, ysize - 23, xsize - 47, ysize -  4);
	boxfill8(vram, xsize, COL8_FFFFFF, xsize - 47, ysize -  3, xsize -  4, ysize -  3);
	boxfill8(vram, xsize, COL8_FFFFFF, xsize -  3, ysize - 24, xsize -  3, ysize -  3);

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

  /*
  调色板的访问步骤。
  首先在一连串的访问中屏蔽中断(比如CLI)。
  将想要设定的调色板号码写入0x03c8，紧接着，按R，G，B的顺序写人0x03c9。如果还想继续设定下一个调色板，则省略调色板号码，再按照RGB的顺序写人0x03c9就行了。
  如果想要读出当前调色板的状态，首先要将调色板的号码写入0x03c7，再从0x03c9读取3次。读出的顺序就是R，G，B。如果要继续读出下一个调色板，同样也是省略调色板号码的设定，按RGB的顺序读出。
  如果最初执行了CLI，那么最后要执行STI。
  我们的程序在很大程度上参考了以上内容。

x86 汇编中，CLI，是将中断标志（interrupt flag）置为0的指令（clear interrupt flag）。
STI是要将这个中断标志置为1的指令（set interrupt flag）。
而标志，是指像以前曾出现过的进位标志一样的各种标志，也就是说在CPU中有多种多样的标志。更改中断标志有什么好处呢？正如其名所示，它与CPU的中断处理有关系。
当CPU遇到中断请求时，是立即处理中断请求（中断标志为1），还是忽略中断请求（中断标志为0），就由这个中断标志位来设定。



但根据C语言的规约，执行RET语句时，EAX中的值就被看作是函数的返回值


我们前面已经说过，CPU的管脚与内存相连。如果仅仅是与内存相连，CPU就只能完成计算和存储的功能。但实际上，CPU还要对键盘的输入有响应，要通过网卡从网络取得信息，通过声卡发送音乐数据，向软盘写入信息等。这些都是设备（device），它们当然也都要连接到CPU上。
既然CPU与设备相连，那么就有向这些设备发送电信号，或者从这些设备取得信息的指令。向设备发送电信号的是OUT指令；从设备取得电气信号的是IN指令。正如为了区别不同的内存要使用内存地址一样，在OUT指令和IN指令中，为了区别不同的设备，也要使用设备号码。设备号码在英文中称为port(端口)。port原意为“港口”，这里形象地将CPU与各个设备交换电信号的行为比作了船舶的出港和进港。


在计算机中，DAC 是 Digital-to-Analog Converter 的缩写，即数字模拟转换器。它是一种电子设备，用于将数字信号转换为模拟信号。在计算机中，数字信号通常是二进制编码的，而模拟信号则是连续的电压或电流信号。DAC 的作用是将数字信号的每个离散值转换为相应的模拟电压或电流值，以便可以被模拟设备（如扬声器、显示器等）处理和使用。
在音频处理中，DAC 用于将数字音频信号转换为模拟音频信号，以便可以通过扬声器播放。在视频处理中，DAC 用于将数字视频信号转换为模拟视频信号，以便可以在显示器上显示。DAC 的性能通常由其分辨率（即可以表示的离散值的数量）和转换速度（即每秒可以转换的次数）来衡量。

*/

void set_palette(int start, int end, unsigned char *rgb)
{
	int i, eflags;
	eflags = io_load_eflags();	/* 记录中断许可标志的值 */
	io_cli(); 					/* 将中断许可标志置为0,禁止中断 */
	io_out8(0x03c8, start);     /* Port 0x3C8, 0x3C9 and 0x3C7 control the DAC */
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
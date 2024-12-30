; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; 加载bootpack
DSKCAC	EQU		0x00100000		; 磁盘缓存的位置
DSKCAC0	EQU		0x00008000		; 磁盘缓存的位置（实模式）

; BOOT_INFO 相关
CYLS	EQU		0x0ff0			; 引导扇区设置
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 关于颜色的信息
SCRNX	EQU		0x0ff4			; 分辨率X
SCRNY	EQU		0x0ff6			; 分辨率Y
VRAM	EQU		0x0ff8			; 图像缓冲区的起始地址

		ORG		0xc200			;  这个的程序要被装载的内存地址

;	画面设置

		MOV		AL,0x13			; VGA显卡，320x200x8bit
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 屏幕的模式（参考C语言的引用）
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

;	通过 BIOS 获取指示灯状态

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

;	PIC关闭一切中断
;	根据AT兼容机的规格，如果要初始化PIC，
;	必须在CLI之前进行，否则有时会挂起。
;	随后进行PIC的初始化。
;	这段程序等同于以下内容的C程序。
;	io_out(PIC0_IMR, 0xff); /* 禁止主PIC的全部中断 */
;	io_out(PIC1_IMR, 0xff); /* 禁止从PIC的全部中断 */
;	io_cli(); /* 禁止CPU级别的中断 */
		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; 如果连续执行OUT指令，有些机种会无法正常运行。   不做什么操作，让CPU休息一个时钟长的时间
		OUT		0xa1,AL

		CLI						; 禁止CPU级别的中断
;   162 页
;	为了让CPU能够访问1MB以上的内存空间，设定A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

;	切换到保护模式

[INSTRSET "i486p"]				; 说明使用486指令

		LGDT	[GDTR0]			; 设置临时GDT   把随意准备的GDT给读进来，后面还要重新设置
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 设bit31为0（禁用分页）  最高位置为0
		OR		EAX,0x00000001	; bit0到1转换（保护模式过渡）最低位置为1
		MOV		CR0,EAX         ; 这样就完成了模式转换  CR0==control register 0,是一个非常重要的寄存器，只有操作系统才能操作它
		JMP		pipelineflush
;	讲解CPU的书上会写到，通过代入CR0而切换到保护模式时，要马上执行JMP指令。所以我们也要执行这一指令。为什么要执行JMP指令呢？因为变成保护模式后，机器语言的解释要发生变化。CPU为了加快指令的执行速度而使用了管道(pipeline)这一机制，就是说，前一条指令还在执行的时候，就开始解释下一条甚至是再下一条指令。因为模式变了，就要重新解释一遍，所以加入了JMP指令。
;	而且在程序中，进入保护模式以后，段寄存器的意思也变了(不再是乘以16后再加算的意思了)，除了CS以外所有段寄存器的值都从0x0000变成了0x0008.CS保持原状是因为如果CS也变了，会造成混乱，所以只有CS要放到后面再处理。0x0008，相当于“gdt+1”的段。
pipelineflush:
		MOV		AX,1*8			;  可读写的段 32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack传递

		MOV		ESI,bootpack	; 转送源
		MOV		EDI,BOTPAK		; 转送目标
		MOV		ECX,512*1024/4
		CALL	memcpy          ; 复制内存的函数

; 磁盘数据最终转送到它本来的位置去
; 首先从启动扇区开始

		MOV		ESI,0x7c00		; 转送源
		MOV		EDI,DSKCAC		; 转送目标  DSKCAC==0x00100000
		MOV		ECX,512/4
		CALL	memcpy

; 剩余的全部

		MOV		ESI,DSKCAC0+512	; 转送源
		MOV		EDI,DSKCAC+512	; 转送源目标
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; 从柱面数变换为字节数/4  乘法
		SUB		ECX,512/4		; 减去 IPL 偏移量
		CALL	memcpy

; 必须由asmhead来完成的工作，至此全部完毕
; 以后就交由bootpack来完成

; bootpack启动

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4; 右移指令
		JZ		skip			; 没有要转送的东西时  jump if zero
		MOV		ESI,[EBX+20]	; 转送源
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; 转送目标
		CALL	memcpy          ; 它会将 bootpack.hrb 第 0x1008 字节开始的 0x11a8 字节复制到 0x00310000 号地址去
skip:
		MOV		ESP,[EBX+12]	; 堆栈的初始化
		JMP		DWORD 2*8:0x0000001b
; 最后将0x310000代入到ESP里，然后用一个特别的JMP指令，将2*8代入到CS里，同时移动到0x1b号地址。这里的0x1b号地址是指第2个段的0x1b号地址。第2个段的基地址是0x280000，所以实际上是从0x28001b开始执行的。这也就是bootpack.hrb的0x1b号地址。
; 这样就开始执行bootpack.hrb了。

waitkbdout:  ; 跟 wait_KBC_sendready 相同
		IN		AL,0x64
		AND		AL,0x02
		IN		AL,0x60			; 空读（为了清空数据接收缓冲区中的垃圾数据） 从 0x60号设备进行 IN 处理  也就是说，如果控制器里有键盘代码，或者是已经累积了鼠标数据，就顺便把它们读取出来。
		JNZ		waitkbdout	; AND的结果如果不是0，就跳到waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; 减法运算的结果如果不是0，就跳转到memcpy
		RET
; memcpy地址前缀大小

		ALIGNB	16
; 如果标签GDT0的地址不是8的整数倍，向段寄存器复制的MOV指令就会慢一些。所以我们插入了ALIGNB指令。但是如果这样，“ALIGNB 8”就够了，用“ALIGNB 16”有点过头了。最后的“bootpack”之前，也是“时机合适”的状态，所以笔者就适当加了一句“ALIGNB 16”。
; GDT0也是一种特定的GDT。0号是空区域(null sector)，不能够在那里定义段。1号和2号分别由下式设定。
GDT0:
		RESB	8				; 初始值
		DW		0xffff,0x0000,0x9200,0x00cf	; 可以读写的段（segment）32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; 可执行的文件的32bit寄存器（bootpack用）

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
; bootpack是asmhead.nas的最后一个标签。haribote.sys是通过asmhead.bin和bootpack.hrb连接起来而生成的（可以通过Makefile确认），所以asmhead结束的地方，紧接着串连着bootpack.hrb最前面的部分。

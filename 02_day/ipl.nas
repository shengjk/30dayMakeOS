; hello-os
; TAB=4
; bootloader  code
; 这段代码不读取启动扇区的内容，因为它的主要目的是显示一条简单的消息 "hello, world" 而不是执行从磁盘读取数据的操作。它假设代码已经在内存中，并且直接从内存执行，而不是从磁盘中加载额外的内容。

; 真实的操作系统 bootloader 通常确实需要从磁盘读取数据，这是启动操作系统的关键部分。典型的 bootloader 过程包括以下几个步骤：
; 加载 Bootloader：
	; 在计算机启动时，BIOS 或 UEFI 会将第一个扇区（即启动扇区）的内容加载到内存的一个特定位置（如 0x7C00），并将控制权交给这个位置的代码。
; 读取操作系统内核：
	; Bootloader 的首要任务是读取更多的磁盘内容，这通常包括操作系统内核和其他必要的启动文件。这些文件可能位于磁盘的特定位置或通过文件系统查找。
; 初始化系统：
	; Bootloader 需要初始化一些基本的系统状态，包括设置内存、处理器模式（实模式、保护模式或长模式）、加载设备驱动等。
; 将控制权交给操作系统：
	; 最后，Bootloader 将读取到的操作系统内核加载到内存并将控制权交给操作系统内核，使其开始执行。



		ORG		0x7c00			; 指明程序装载地址  出厂的时候BIOS就被组装在电脑主板上的ROM单元里。电脑厂家在BIOS中预先写入了操作系统开发人员经常使用的一些程序。  bootloader code is loaded and running in memory at physical addresses 0x7C00 through 0x7DFF

; 标准FAT12格式软盘专用的代码 Stand FAT12 format floppy code

		JMP		entry
		DB		0x90
		DB		"HELLOIPL"		; 启动扇区名称（8字节）
		DW		512				; 每个扇区（sector）大小（必须512字节）
		DB		1				; 簇（cluster）大小（必须为1个扇区）
		DW		1				; FAT起始位置（一般为第一个扇区）
		DB		2				; FAT个数（必须为2）
		DW		224				; 根目录大小（一般为224项）
		DW		2880			; 该磁盘大小（必须为2880扇区1440*1024/512）
		DB		0xf0			; 磁盘类型（必须为0xf0）
		DW		9				; FAT的长度（必??9扇区）
		DW		18				; 一个磁道（track）有几个扇区（必须为18）
		DW		2				; 磁头数（必??2）
		DD		0				; 不使用分区，必须是0
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明（固定）
		DD		0xffffffff		; （可能是）卷标号码
		DB		"HELLO-OS   "	; 磁盘的名称（必须为11字?，不足填空格）
		DB		"FAT12   "		; 磁盘格式名称（必??8字?，不足填空格）
		RESB	18				; 先空出18字节

; 程序主体

entry:  ;0x7c50
		MOV		AX,0			; 初始化寄存器    MOV:赋值
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX
		MOV		ES,AX

		MOV		SI,msg
putloop:
		MOV		AL,[SI]         ; [] 表示内存，表示把 SI对应的内存地址上数据的1个字节的内容读入到 AL 中。 MOV的数据传送源和传送目的地不仅可以是寄存器或常数，也可以是内存地址。 MOV会自动要求源数据和目标数据位数一致
		ADD		SI,1			; 给SI加1
		CMP		AL,0
		JE		fin				; 如果结果相等则跳转到指定地址，如果不等则不跳转
		MOV		AH,0x0e			; 显示一个字符    INT 0x10, AH = 0xE -- display char，这是调用 BIOS 的 “Teletype Output” 功能，用于在屏幕上显示一个字符，并推进光标
		MOV		BX,15			; 没啥用
		INT		0x10			; 调用显卡显示文字,INT 0x10 = Video display functions (including VESA/VBE)   INT软件中断指令
		JMP		putloop
fin:
		HLT						; 让CPU停止，等待指令
		JMP		fin				; 无限循环

msg:  							;0x7c74
		DB		0x0a, 0x0a		; 换行两次
		DB		"hello, world"
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; 填写0x00填充到0x7def, 有了 ORG，$代表将要读入的内存地址

		DB		0x55, 0xaa


; AX —— accumulator，累加寄存器          0-7位的低8位成为AL,8-15位的高8位称为 AH
; CX —— counter，计数寄存器
; DX —— data，数据寄存器
; BX —— base，基址寄存器                 通常在内存寻址中用来存放基地址。它与源索引SI和目的索引DI寄存器结合，可以用于访问数组或其他数据结构。
; SP —— stack pointer，栈指针寄存器      SP寄存器指向当前栈的顶部。在执行函数调用、参数传递、局部变量分配和函数返回时，栈指针会相应地增加或减少。
; BP —— base pointer，基地址指针寄存器    通常用于访问堆栈中的局部变量和函数参数。在栈帧中，BP通常指向帧的起始位置。
; SI —— source index，源变址寄存器       通常用于字符串操作和数组处理中，指向源数据的位置
; DI —— destination index，目的变址寄存器  同样用于字符串操作和数组处理，但它指向目标数据的位置
; 这些都是 16 位寄存器，所以可以存储16位的二进制. 按照机器语言中寄存器的编号顺序排列的
; 指令编码：操作码 opcode 和 操作数 operand 构成



; CPU中的8个8位寄存器，具体为：
; AL——累加寄存器低位（accumulator low）
; CL——计数寄存器低位（counter low）
; DL——数据寄存器低位（data low）
; BL——基址寄存器低位（base low）
; AH——累加寄存器高位（accumulator high）
; CH——计数寄存器高位（counter high）
; DH——数据寄存器高位（data high）
; BH——基址寄存器高位（base high）


; 段寄存器
; 这些段寄存器都是16位寄存器。
; ES——附加段寄存器（extra segment）
; CS——代码段寄存器（code segment）
; SS——栈段寄存器（stack segment）
; DS——数据段寄存器（data segment）
; FS——没有名称（segment part 2）
; GS——没有名称（segment part 3）
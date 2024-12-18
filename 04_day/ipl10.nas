; haribote-ipl
; TAB=4

CYLS	EQU		10				; 声明CYLS=10

		ORG		0x7c00			; 指明程序装载地址

; 标准FAT12格式软盘专用的代码 Stand FAT12 format floppy code

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; 启动扇区名称（8字节）
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
		DB		"HARIBOTEOS "	; 磁盘的名称（必须为11字?，不足填空格）
		DB		"FAT12   "		; 磁盘格式名称（必??8字?，不足填空格）
		RESB	18				; 先空出18字节

; 程序主体

entry:
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; 读取磁盘

		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0
		MOV		CL,2			; 扇区2

readloop:
		MOV		SI,0			; 记录失败次数寄存器

retry:
		MOV		AH,0x02			; AH=0x02 : 读入磁盘
		MOV		AL,1			; 1个扇区
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用磁盘BIOS
		JNC		next			; 没出错则跳转到fin
		ADD		SI,1			; 往SI加1
		CMP		SI,5			; 比较SI与5
		JAE		error			; SI >= 5 跳转到error
		MOV		AH,0x00
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 重置驱动器
		JMP		retry
next:
		MOV		AX,ES			; 把内存地址后移0x200（512/16十六进制转换）
		ADD		AX,0x0020
		MOV		ES,AX			; ADD ES,0x020因为没有ADD ES，只能通过AX进行
		ADD		CL,1			; 往CL里面加1
		CMP		CL,18			; 比较CL与18
		JBE		readloop		; CL <= 18 跳转到readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; DH < 2 跳转到readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; CH < CYLS 跳转到readloop

; 读取完毕，跳转到haribote.sys执行！
		MOV		[0x0ff0],CH		; IPLがどこまで読んだのかをメモ
		JMP		0xc200

error:
		MOV		SI,msg

putloop:
		MOV		AL,[SI]
		ADD		SI,1			; 给SI加1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示一个文字
		MOV		BX,15			; 指定字符颜色
		INT		0x10			; 调用显卡BIOS
		JMP		putloop

fin:
		HLT						; 让CPU停止，等待指令
		JMP		fin				; 无限循环

msg:
		DB		0x0a, 0x0a		; 换行两次
		DB		"load error"
		DB		0x0a			; 换行   在汇编语言中，DB 是一个指令，它是 “Define Byte” 的缩写。DB 指令用于在数据段中定义一个或多个字节的存储空间，并且可以初始化这些字节为特定的值。 DB 指令常用于初始化变量、常量、字符串等数据。
		DB		0

		RESB	0x7dfe-$		; 填写0x00直到0x001fe 在汇编语言中，RESB 是一个指令，它是 “Reserve Byte” 的缩写，用于在汇编程序中分配存储空间。RESB 指令告诉汇编器在数据段中保留一定数量的字节，并且将这些字节初始化为0。

		DB		0x55, 0xaa

; 如果与C语言联合使用的话,有的寄存器能自由使用,有的寄存器不能自由使用,能自由使用的只有EAX、ECX、EDX这3个。至于其他寄存器,只能使用其值,而不能改变其值。因为这些寄存器在C语言编译后生成的机器语言中,用于记忆非常重要的值。因此这次我们只用EAX和ECX。





; 这些都是 16 位寄存器，所以可以存储16位的二进制. 按照机器语言中寄存器的编号顺序排列的
; AX —— accumulator，累加寄存器          0-7位的低8位成为AL,8-15位的高8位称为 AH
; CX —— counter，计数寄存器
; DX —— data，数据寄存器
; BX —— base，基址寄存器                 通常在内存寻址中用来存放基地址。它与源索引SI和目的索引DI寄存器结合，可以用于访问数组或其他数据结构。
; SP —— stack pointer，栈指针寄存器      SP寄存器指向当前栈的顶部。在执行函数调用、参数传递、局部变量分配和函数返回时，栈指针会相应地增加或减少。
; BP —— base pointer，基地址指针寄存器    通常用于访问堆栈中的局部变量和函数参数。在栈帧中，BP通常指向帧的起始位置。
; SI —— source index，源变址寄存器       通常用于字符串操作和数组处理中，指向源数据的位置
; DI —— destination index，目的变址寄存器  同样用于字符串操作和数组处理，但它指向目标数据的位置
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

; 标志寄存器  进位标志 在 第0位，中断标志 第9位
; FLAGS 寄存器 16 bit
; EFLAGS 寄存器 32 bit
; 能够用来读写EFLAGS寄存器的只有 PUSHFD 和 POPFD 指令
; PUSHFD: push flags double-word   将标志位的值桉双字长压入栈
; POPFD: pop flags double-word     桉双字长将标志位的值弹出栈

; JC   jump if carry,如果进位标志 1 则跳转.
; JNC jump if not carry 进位标志是0就跳转.
; JAE  jump if above or equal 大于或等于时跳转
; JBE  jump if below or equal 小于或等于时跳转
; JB   jump if below 小于时跳转
; haribote-ipl
; TAB=4
; Boot Sector 启动区：
				; 引导加载程序 Boot Loader（ 负责初始化硬件、设置必要的寄存器和内存，并加载操作系统的内核或引导加载器到内存中。）
				; 关于存储设备和文件系统的重要信息，如磁盘分区表（在主引导记录MBR中）、文件系统类型、扇区大小等。这些信息对于操作系统正确识别和访问存储设备至关重要。
				;
; 在计算机的启动过程中，BIOS（基本输入输出系统）负责初始化硬件并加载引导程序。引导程序通常存储在引导扇区中，这个扇区的内容在计算机开机时被加载到特定的内存地址（通常是 0x7C00）并执行

CYLS	EQU		10				; 声明CYLS=10，EQU 指令用于定义常量或符号（符号常量）

		ORG		0x7c00			; 指定汇编源代码在内存中的起始地址，指明程序装载地址  bootloader code is loaded and running in memory at physical addresses 0x7C00 through 0x7DFF（BIOS 负责的）

; 标准FAT12格式软盘专用的代码 Stand FAT12 format floppy code

		JMP		entry           ; entry 标签是程序的入口点,而程序被加载的起始地址为 0x7c00
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

entry:  ; 7C50
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00       ; 设置 SP 为 0x7C00 是为了初始化堆栈，使进一步的堆栈操作不与引导程序的代码发生冲突，而是为代码运行时提供一个干净、可用的堆栈区域。在 x86 架构中，堆栈是向下生长的，即堆栈指针（SP）的值会递减。 默认情况下，堆栈指针（SP）在程序开始时可能指向任意位置，因此需要显式地初始化。
		MOV		DS,AX

; 读取磁盘

		MOV		AX,0x0820       ; 作者随便设置的地址( 没有其他用途的 )
		MOV		ES,AX
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0
		MOV		CL,2			; 扇区2  ; 启动扇区C0-H0-S1 下一个扇区是 C0-H0-S2

readloop:                       ; 汇编代码的执行顺序通常是按顺序执行，但可以被跳转和条件分支指令所改变。这些指令使得程序的执行流程可以更加灵活和复杂，以实现各种控制逻辑。
		MOV		SI,0			; 记录失败次数寄存器

retry:
		MOV		AH,0x02			; AH=0x02 : 读入磁盘
		MOV		AL,1			; 设置 AL 寄存器为 1，表示每次读取一个扇区
		MOV		BX,0			; 设置偏移地址为0，用 ES:BX 指针设置数据读取后存放的内存地址，偏移地址 0x0000 表示从段的起始位置开始，没有偏移。
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用磁盘BIOS
		JNC		next			; 没出错则跳转到next
		ADD		SI,1			; 往SI加1
		CMP		SI,5			; 比较SI与5
		JAE		error			; SI >= 5 跳转到error
		MOV		AH,0x00
		MOV		DL,0x00			; A驱动器   现在电脑基本上只有一个软盘驱动
		INT		0x13			; 重置驱动器
		JMP		retry
next:
		MOV		AX,ES			; 获取当前 ES 寄存器的值
		ADD		AX,0x0020       ; 把内存地址后移0x200（512/16十六进制转换）
		MOV		ES,AX			; ADD ES,0x020因为没有ADD ES，只能通过AX进行.0x0020（十六进制）等于 32（十进制）。将段地址增加 0x0020 相当于将段地址增加 32 × 16 = 512（十进制）。
		ADD		CL,1			; 往CL里面加1
		CMP		CL,18			; 比较CL与18
		JBE		readloop		; CL <= 18 跳转到readloop  0柱面0磁头2-18扇区
		MOV		CL,1            ; 扇区1
		ADD		DH,1            ; 0+1=磁头1
		CMP		DH,2            ;
		JB		readloop		; DH < 2 跳转到readloop 0柱面1磁头1-18扇区
		MOV		DH,0			; 磁头0
		ADD		CH,1			; 柱面+1
		CMP		CH,CYLS
		JB		readloop		; CH < CYLS 跳转到readloop  10个柱面，正面2-18个扇区，反面就是1-18个扇区
; 0x08200 - 0x34fff
; 读取完毕，跳转到haribote.sys执行！
		MOV		[0x0ff0],CH		; 记录IPL（初始程序加载）读到了哪里
		JMP		0xc200          ; 在 img 镜像中，文件名会写在 0x002600以后得地方，文件的内容会写在 0x004200 以后的地方。 0x8000+0x4200=0xc200。现在的程序是从启动区开始，把磁盘上的内容装载到内存0x8000号地址，所以磁盘0x4200处的内容就应该位于内存0x8000+0x4200=0xc200号地址。


error:
		MOV		SI,msg

putloop:
		MOV		AL,[SI]         ;[] 表示内存，表示把 SI对应的内存地址上数据的1个字节的内容读入到 AL 中。 MOV的数据传送源和传送目的地不仅可以是寄存器或常数，也可以是内存地址。 MOV会自动要求源数据和目标数据位数一致
								; MOV [0x1234]， 0x56 会出错，这是因为指定内存时，不知道到底是BYTE，还是WORD，还是DWORD。只有在另一方也是寄存器的时候才能省略，其他情况都不能省略。
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
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; 填写0x00直到0x001fe   在汇编语言中，RESB 是一个指令，它是 “Reserve Byte” 的缩写，用于在汇编程序中分配存储空间。RESB 指令告诉汇编器在数据段中保留一定数量的字节，并且将这些字节初始化为0。

		DB		0x55, 0xaa



; INT 0x13, AH = 0 -- reset floppy/hard disk

; 当 INT 0x13 中的 AH 寄存器设置为 2 时，这确实是 BIOS 用于读取磁盘的操作。
; 具体来说，AH = 02 表示 BIOS 请求从指定的驱动器中读取一个扇区的数据。这个调用可以用来从软盘、硬盘等存储介质中读取数据。调用这个中断时，需要设置其他相关寄存器，例如：
; - AL：要处理的扇区数量，只能同时处理连续的扇区
; - CH：柱面号。
; - CL：扇区号（Sector）
; - DH：磁头号（Head）。
; - DL：驱动器号（通常是 0x00 表示第一个软盘驱动器，0x80 表示第一个硬盘驱动器）。
; 如果操作成功，标志寄存器中的进位标志 (Carry Flag, CF) 会被清除 0。如果操作失败，进位标志会被置位 1，且 AH 中将包含错误代码。例如，AH = 0x04 表示找不到扇区。

;标志寄存器（Flags Register）在 x86 架构中被称为 EFLAGS（Extended Flags）寄存器，在更老的 8086 处理器中被称为 FLAGS 寄存器。这个寄存器存储了处理器当前的状态和控制信息，包括：
;1. **进位标志 (Carry Flag, CF)**：当运算产生进位或者借位时设置。  JC   jump if carry,如果进位标志 1 则跳转.  JNC jump if not carry 进位标志是0就跳转
;2. **零标志 (Zero Flag, ZF)**：当运算结果为零时设置。
;3. **符号标志 (Sign Flag, SF)**：当运算结果为负数时设置。
;4. **溢出标志 (Overflow Flag, OF)**：当算术运算产生溢出时设置。
;5. **方向标志 (Direction Flag, DF)**：控制字符串操作的方向。
;6. **中断允许标志 (Interrupt Enable Flag, IF)**：控制中断的响应。
;这些标志位用于决定程序的执行路径以及控制处理器的某些操作。每个标志都有特定的意义和用途，在各种条件判断、运算操作和控制流中都扮演着重要角色。

; ES:BX 作用  ES*16+BX
; 在 x86 汇编语言中，ES:BX 用于指向内存中的一个地址，并指定数据缓冲区。ES (Extra Segment) 是段寄存器，BX (Base Register) 是基址寄存器。组合在一起时，ES:BX 指向内存中的一个具体地址，用于数据传输操作，例如在读写磁盘时指定数据的存放位置。
; 不管我们要指定的内存是什么地址，都必须同时指定段寄存器，这是规定。一般如果省略的话，就会把 DS: 作为默认的段寄存器

; 在 x86 汇编语言中，`ES:BX` 用于指向内存中的一个地址，这是因为 `ES` 和 `BX` 寄存器的组合提供了一种灵活且强大的方式来访问内存中的特定位置。
; 以下是为什么使用 `ES:BX` 的几个关键原因：
; 1. **段寄存器和偏移寄存器的组合**：x86 架构采用分段存储管理方式，内存地址由段地址和偏移地址两部分组成。段地址存储在段寄存器中，而偏移地址存储在通用寄存器中。通过 `ES:BX`，可以方便地指定内存中的特定位置，其中 `ES` 是段寄存器，`BX` 是偏移寄存器。
; 2. **数据传输的灵活性**：许多数据传输和字符串操作指令，例如 `MOVSB`、`MOVSW`、`STOSB` 和 `STOSW`，都会使用 `ES:DI` 或 `DS:SI` 寄存器对。这些指令允许快速且高效地移动数据，而不必每次都显式地指定地址。这种机制提高了指令的执行效率。
; 3. **专用段寄存器**：在 x86 体系结构中，不同的段寄存器有特定的用途。例如，`DS`（数据段）通常用于数据访问，`CS`（代码段）用于指令访问，`SS`（堆栈段）用于堆栈操作，而 `ES`（额外段）则通常作为附加的段寄存器，用于涉及额外数据的操作。这种设计使得程序可以更灵活地管理和使用内存。
; 4. **历史和兼容性**：x86 架构及其段寄存器使用方法已经有很长的历史，许多软件和硬件设计都依赖于这些传统和约定。因此，使用 `ES:BX` 和类似组合是一种标准的、兼容性强的做法。
; 例如，在 BIOS 调用中，`ES:BX` 常用于指定数据缓冲区的位置。在执行读写磁盘操作时，BIOS 会将数据读入或写出到 `ES:BX` 指向的内存地址。
; 通过这种方式，x86 汇编语言可以高效且灵活地管理和操作内存，从而实现各种复杂的任务和功能。

; 内存分段 是指将内存地址空间划分成多个段（segment），每个段都有一个段地址和一个偏移地址。程序和数据存储在这些段中，通过段寄存器和偏移寄存器的组合来访问内存。例如，代码段（CS）、数据段（DS）、堆栈段（SS）和额外段（ES）分别用于存储不同类型的程序和数据。


; 在计算机系统中，内存地址通常以字节（byte）为单位，而不是位（bit）。这是因为内存的基本存储单元是字节，而一个字节包含 8 个比特（bit）。因此，当我们讨论内存地址和容量时，通常使用字节作为度量单位


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



; JC   jump if carry,如果进位标志 1 则跳转.
; JNC jump if not carry 进位标志是0就跳转.
; JAE  jump if above or equal 大于或等于时跳转
; JBE  jump if below or equal 小于或等于时跳转
; JB   jump if below 小于时跳转
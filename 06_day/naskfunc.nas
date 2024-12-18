; naskfunc
; TAB=4

[FORMAT "WCOFF"]				; 制作目标文件的模式
[INSTRSET "i486p"]				; 使用到486为止的指令
[BITS 32]						; 3制作32位模式用的机器语言
[FILE "naskfunc.nas"]			; 文件名

		GLOBAL	_io_hlt, _io_cli, _io_sti, _io_stihlt
		GLOBAL	_io_in8,  _io_in16,  _io_in32
		GLOBAL	_io_out8, _io_out16, _io_out32
		GLOBAL	_io_load_eflags, _io_store_eflags
		GLOBAL	_load_gdtr, _load_idtr
		GLOBAL	_asm_inthandler21, _asm_inthandler27, _asm_inthandler2c
		EXTERN	_inthandler21, _inthandler27, _inthandler2c ; 马上要使用这个名字的标号了，它在别的源文件里，可不要搞错了

[SECTION .text]

_io_hlt:	; void io_hlt(void);
		HLT
		RET

_io_cli:	; void io_cli(void);
		CLI
		RET

_io_sti:	; void io_sti(void);
		STI
		RET

_io_stihlt:	; void io_stihlt(void);
		STI
		HLT
		RET

_io_in8:	; int io_in8(int port);
		MOV		EDX,[ESP+4]		; port
		MOV		EAX,0
		IN		AL,DX
		RET

_io_in16:	; int io_in16(int port);
		MOV		EDX,[ESP+4]		; port
		MOV		EAX,0
		IN		AX,DX
		RET

_io_in32:	; int io_in32(int port);
		MOV		EDX,[ESP+4]		; port
		IN		EAX,DX
		RET

_io_out8:	; void io_out8(int port, int data);
		MOV		EDX,[ESP+4]		; port
		MOV		AL,[ESP+8]		; data
		OUT		DX,AL
		RET

_io_out16:	; void io_out16(int port, int data);
		MOV		EDX,[ESP+4]		; port
		MOV		EAX,[ESP+8]		; data
		OUT		DX,AX
		RET

_io_out32:	; void io_out32(int port, int data);
		MOV		EDX,[ESP+4]		; port
		MOV		EAX,[ESP+8]		; data
		OUT		DX,EAX
		RET

_io_load_eflags:	; int io_load_eflags(void);
		PUSHFD		; PUSH EFLAGS
		POP		EAX
		RET

_io_store_eflags:	; void io_store_eflags(int eflags);
		MOV		EAX,[ESP+4]
		PUSH	EAX
		POPFD		; POP EFLAGS
		RET
; 这个函数用来将指定的段上限（limit）和地址值赋值给名为GDTR的48位寄存器。这是一个很特别的48位寄存器，并不能用我们常用的MOV指令来赋值。
; 给它赋值的时候，唯一的方法就是指定一个内存地址，从指定的地址读取6个字节（也就是48位），然后赋值给GDTR寄存器。完成这一任务的指令就是LGDT

; 该寄存器的低16位（即内存的最初2个字节）是段上限，它等于“GDT的有效字节数-1”。
; 今后我们还会偶尔用到上限这个词，意思都是表示量的大小，一般为“字节数-1”。
; 剩下的高32位（即剩余的4个字节），代表GDT的开始地址。
; GDTR是一个48位的寄存器，其中高32位存储GDT的基地址，低16位存储GDT的界限（即表的大小）

; 在x86架构中，全局描述符表（GDT）的基地址是由CPU的GDTR（Global Descriptor Table Register）寄存器设定的。
; GDTR是一个48位的寄存器，其中高32位存储GDT的基地址，低16位存储GDT的界限（即表的大小）。
; 当计算机启动时，BIOS会初始化GDTR寄存器，将GDT的基地址和界限加载到其中。
; 在操作系统启动后，它会接管对GDTR的管理，并根据需要更新GDT的内容和基地址。
; 在你提供的代码片段中，init_gdtidt 函数用于初始化GDT和IDT（Interrupt Descriptor Table）。
; 这个函数通常会在操作系统启动时被调用，以设置GDT和IDT的初始状态。在这个函数中，会通过特定的指令（如lgdt）将GDT的基地址和界限加载到GDTR寄存器中。

_load_gdtr:		; void load_gdtr(int limit, int addr);
		MOV		AX,[ESP+4]		; limit
		MOV		[ESP+6],AX
		LGDT	[ESP+6]
		RET

_load_idtr:		; void load_idtr(int limit, int addr);
		MOV		AX,[ESP+4]		; limit
		MOV		[ESP+6],AX
		LIDT	[ESP+6]
		RET


; PUSHAD
; PUSH EAX
; PUSH ECX
; PUSH EDX
; PUSH EBX
; PUSH ESP
; PUSH EBP
; PUSH ESI
; PUSH EDI
; 这些指令都是将寄存器的内容压入栈中。每个 PUSH 指令将指定的寄存器值推送到栈顶。这些寄存器是 x86 架构中的通用寄存器，用于在程序中存储数据。
; 反过来，POPAD指令相当于按以上相反的顺序，把它们全都POP出来


; 在汇编语言中，PUSHAD 指令用于将所有32位通用寄存器（EAX、ECX、EDX、EBX、ESP、EBP、ESI、EDI）的值压入堆栈，而 PUSH EAX 指令仅用于将寄存器 EAX 的值压入堆栈。这两条指令的使用场景和目的不同。
; PUSHAD 指令通常在需要保存所有通用寄存器状态的情况下使用，例如在进入中断处理程序或函数调用时。它可以确保在执行关键代码段之前，所有寄存器的值都被安全地保存起来，以便在需要时恢复。
; 而 PUSH EAX 指令则用于在特定情况下保存 EAX 寄存器的值。例如，在调用函数时，可能需要将 EAX 寄存器的值作为参数传递给函数。在这种情况下，PUSH EAX 指令可以将 EAX 寄存器的值压入堆栈，以便在函数内部使用。
; 在你提供的代码片段中，PUSHAD 指令用于在进入中断处理程序时保存所有通用寄存器的状态。而 PUSH EAX 指令则用于在调用 _inthandler21 函数之前，将 EAX 寄存器的值（即当前堆栈指针）压入堆栈，这可能是为了在 _inthandler21 函数内部使用这个值，或者是为了在函数返回时恢复 EAX 寄存器的值。
; 因此，PUSHAD 和 PUSH EAX 指令在不同的上下文中使用，它们的目的和作用也不同。PUSHAD 用于保存所有通用寄存器的状态，而 PUSH EAX 则用于保存特定寄存器的值。在实际编程中，根据需要选择合适的指令来保存和恢复寄存器的值是非常重要的。

_asm_inthandler21:
		PUSH	ES
		PUSH	DS
		PUSHAD
		MOV		EAX,ESP
		PUSH	EAX
		MOV		AX,SS
		MOV		DS,AX
		MOV		ES,AX
		CALL	_inthandler21
		POP		EAX
		POPAD
		POP		DS
		POP		ES
		IRETD  ; 中断处理完成后，不能执行 return 必须执行 IRETD

_asm_inthandler27:
		PUSH	ES
		PUSH	DS
		PUSHAD
		MOV		EAX,ESP
		PUSH	EAX
		MOV		AX,SS
		MOV		DS,AX
		MOV		ES,AX
		CALL	_inthandler27
		POP		EAX
		POPAD
		POP		DS
		POP		ES
		IRETD

_asm_inthandler2c:
		PUSH	ES
		PUSH	DS
		PUSHAD
		MOV		EAX,ESP
		PUSH	EAX
		MOV		AX,SS
		MOV		DS,AX
		MOV		ES,AX
		CALL	_inthandler2c
		POP		EAX
		POPAD
		POP		DS
		POP		ES
		IRETD

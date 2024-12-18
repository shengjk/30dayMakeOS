; naskfunc
; TAB=4

; 在nask目标文件的模式下，必须设定文件名信息，然后再写明下面程序的函数名。注意要在函数名的前面加上“_”，否则就不能很好地与C语言函数链接。需要链接的函数名，都要用GLOBAL指令声明。
; 用汇编写的函数，之后还要与bootpack.obj链接，所以也需要编译成目标文件。因此将输出格式设定为WCOFF模式。另外，还要设定成32位机器语言模式。

; 简单介绍一下电脑的CPU（英特尔系列）家谱。8086→80186→286→386→486→Pentium→PentiumPro→PentiumII→PentiumIII→Pentium4→……
; 从上面的家谱来看，386已经是非常古老的CPU了。到286为止CPU是16位，而386以后CPU是32位。

; 对于图形数据应该进行什么样的运算呢？可以将某些特定的位变为1，某些特定的位变为0，或者是反转00特定的位等，做这样的运算。

[FORMAT "WCOFF"]				; 制作目标文件的模式
[INSTRSET "i486p"]				; 使用到486为止的指令
[BITS 32]						; 3制作32位模式用的机器语言
[FILE "naskfunc.nas"]			; 文件名

		GLOBAL	_io_hlt, _io_cli, _io_sti, _io_stihlt
		GLOBAL	_io_in8,  _io_in16,  _io_in32
		GLOBAL	_io_out8, _io_out16, _io_out32
		GLOBAL	_io_load_eflags, _io_store_eflags

[SECTION .text]

_io_hlt:	; void io_hlt(void);
		HLT ; 停机（Halt） 这个指令使处理器进入停机状态，停止执行指令，直到接收到一个硬件中断信号。在停机状态下，处理器会保持低功耗模式，直到被中断唤醒。如果收到PIC通知，CPU就会被唤醒
		RET ; 相当于 C 语言的 return

_io_cli:	; void io_cli(void); io_cli(); 被用于在进入一个关键代码段之前禁用中断，以确保在这段代码执行期间不会被中断打断。这通常用于保护那些需要原子性执行的操作，例如更新共享数据结构或处理硬件设备的状态。
		CLI ; 清除中断标志。这个指令用于禁止处理器响应可屏蔽中断。当执行CLI指令后，处理器会将标志寄存器中的中断标志位清除，从而阻止新的中断请求被响应。
		RET

_io_sti:	; void io_sti(void);
		STI ;设置中断标志（Set Interrupt Flag）这个指令用于允许处理器响应可屏蔽中断。当执行STI指令后，处理器会将标志寄存器中的中断标志位置位，从而允许新的中断请求被响应
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


;  首先是CLI和STI。
; 所谓CLI,是将中断标志（interrupt flag）置为0的指令（clear interrupt flag）。
; STI是要将这个中断标志置为1的指令（set interrupt flag）。
; 而标志，是指像以前曾出现过的进位标志一样的各种标志，也就是说在CPU中有多种多样的标志。
; 更改中断标志有什么好处呢？正如其名所示，它与CPU的中断处理有关系。
; 当CPU遇到中断请求时，是立即处理中断请求（中断标志为1），还是忽略中断请求（中断标志为0），就由这个中断标志位来设定。
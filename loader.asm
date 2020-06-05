%include "bootdef.inc"

SECTION LOADER vstart=LOADER_BASE_ADDR

    jmp loader_start					; 此处的物理地址是:

; 64位gdt[0]
;0   00      0
;1   TI_GDT  RPL0
;2   TI_GDT  RPL0
;3   TI_GDT  RPL0
GDT_BASE:           dd 0x0, 0x0
CODE_DESC:          dd 0x0000FFFF,  DESC_CODE_HIGH4
DATA_STACK_DESC:    dd 0x0000FFFF,  DESC_DATA_HIGH4

;limit=(0xbffff-0xb8000)/4k=0x7 
; 此时dpl已改为0
VIDEO_DESC:         dd 0x80000007,  DESC_VIDEO_HIGH4	


    GDT_SIZE    equ $ - GDT_BASE
    GDT_LIMIT   equ GDT_BASE - 1

    ; dq 为两个quad 8bytes
    times 60 dq 0

SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0    ; 相当于(CODE_DESC - GDT_BASE)/8 + TI_GDT + RPL0

SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0	 ; 同上

SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0	 ; 同上 

    GDT_PTR dw GDT_LIMIT 
            dd GDT_BASE

    loadermsg db '2 loader in real.'

loader_start:

    mov	 sp, LOADER_BASE_ADDR
    mov	 bp, loadermsg           ; ES:BP = 字符串地址
    mov	 cx, 17			 ; CX = 字符串长度
    mov	 ax, 0x1301		 ; AH = 13,  AL = 01h
    mov	 bx, 0x001f		 ; 页号为0(BH = 0) 蓝底粉红字(BL = 1fh)
    mov	 dx, 0x1800		 ;
    int	 0x10                    ; 10h 号中断


    ; A20 low开始第一个位置设置1
    in al,0x92
    or al,00000010B
    out 0x92,al

    ;载入gdt
    lgdt [GDT_PTR]

    ;设置cr0
    mov eax, cr0
    xor eax, 0x01
    mov cr0, eax
    
    ;跳进保护模式的代码
    jmp  SELECTOR_CODE:protected_mode_start

[bits 32]
protected_mode_start:
   mov ax, SELECTOR_DATA
   mov ds, ax
   mov es, ax
   mov ss, ax
   mov esp, LOADER_BASE_ADDR
   mov ax, SELECTOR_VIDEO
   mov gs, ax

   mov byte [gs:160], 'P'

   jmp $
%include "bootdef.inc"

    org 0x7c00
SECTION MBR 
    ; 初始化寄存器为0
    mov ax, cs
    ; 段寄存器不可以直接赋值 例如 move ds, 1是错误的 只能通过寄存器赋值
    ; 段寄存器包括了ds, es, ss, fs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00

    ; ---- 打印字符串 ----
    ; 清空屏幕
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0
    mov dx, 0x184f
    int 0x10

    mov	ax,	0x4F02
    mov	bx,	0x4180
    int 	10h
    cmp	ax,	0x004F
	jnz	Label_SET_SVGA_Mode_VESA_VBE_FAIL

    ;读取磁盘的loader
    mov eax, LOADER_START_SECTOR
    mov bx, LOADER_BASE_ADDR
    ; 读取4个扇区
    mov cx, 4
    call ReadLoader
    ;now the loader is loaded at LOADER_BASE_ADDR
    jmp LOADER_BASE_ADDR

Label_SET_SVGA_Mode_VESA_VBE_FAIL:

	jmp	$

ReadLoader:

    mov esi, eax
    mov di, cx

    ;讀寫硬盤:
    ;第1步：設置要讀取的扇區數
    mov dx,0x1f2
    mov al,cl
    out dx,al            ;讀取的扇區數

    mov eax,esi       ;恢復ax

    ;第2步：將LBA地址存入0x1f3 ~ 0x1f6

    ;LBA地址7~0位寫入端口0x1f3
    mov dx,0x1f3                       
    out dx,al                          

    ;LBA地址15~8位寫入端口0x1f4
    mov cl,8
    shr eax,cl
    mov dx,0x1f4
    out dx,al

    ;LBA地址23~16位寫入端口0x1f5
    shr eax,cl
    mov dx,0x1f5
    out dx,al

    shr eax,cl
    and al,0x0f       ;lba第24~27位
    or al,0xe0       ; 設置7～4位為1110,表示lba模式
    mov dx,0x1f6
    out dx,al

    ;第3步：向0x1f7端口寫入讀命令，0x20 
    mov dx,0x1f7
    mov al,0x20                        
    out dx,al

    ;第4步：檢測硬盤狀態
.not_ready:
    ;同一端口，寫時表示寫入命令字，讀時表示讀入硬盤狀態
    nop
    in al,dx
    and al,0x88       ;第4位為1表示硬盤控制器已准備好數據傳輸，第7位為1表示硬盤忙
    cmp al,0x08
    jnz .not_ready       ;若未准備好，繼續等。

;第5步：從0x1f0端口讀數據
    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax       ; di為要讀取的扇區數，一個扇區有512字節，每次讀入一個字，
               ; 共需di*512/2次，所以di*256
    mov dx, 0x1f0
.go_on_read:
    in ax,dx
    mov [bx],ax
    add bx,2          
    loop .go_on_read
    ret

    ; 总共512bytes 后两个字节让bios识别这是mbr
    times 510 - ($ - $$) db 0
    db 0x55
    db 0xaa


%include "bootdef.inc"

%define PAGE_PRESENT    (1 << 0)
%define PAGE_WRITE      (1 << 1)
 
%define CODE_SEG     0x0008 ; gdt[1]
%define DATA_SEG     0x0010 ; gdt[2] (kernel data)
 
SECTION LOADER vstart=LOADER_BASE_ADDR

    jmp SwitchToLongMode

ALIGN 4
IDT:
    .Length       dw 0
    .Base         dd 0
 
; Function to switch directly to long mode from real mode.
; Identity maps the first 2MiB.
; Uses Intel syntax.
 
; es:edi    Should point to a valid page-aligned 16KiB buffer, for the PML4, PDPT, PD and a PT.
; ss:esp    Should point to memory that can be used as a small (1 uint32_t) stack
 
SwitchToLongMode:
    mov edi, FREE_SPACE
    ; Zero out the 16KiB buffer.
    ; Since we are doing a rep stosd, count should be bytes/4.   
    push di                           ; REP STOSD alters DI.
    mov ecx, 0x1000
    xor eax, eax
    cld
    rep stosd
    pop di                            ; Get DI back.
 
 
    ; Build the Page Map Level 4.
    ; es:di points to the Page Map Level 4 table.
    lea eax, [es:di + 0x1000]         ; Put the address of the Page Directory Pointer Table in to EAX.
    or eax, 0x7 ; Or EAX with the flags - present flag, writable flag.
    mov [es:di], eax                  ; Store the value of EAX as the first PML4E.
 
    mov [es:di + 0x800], eax                  ; Store the value of EAX as the first PML4E.

    ; Build the Page Directory Pointer Table.
    lea eax, [es:di + 0x2000]         ; Put the address of the Page Directory in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writable flag.
    mov [es:di + 0x1000], eax         ; Store the value of EAX as the first PDPTE.
 
 
    ; Build the Page Directory.
    lea eax, [es:di + 0x3000]         ; Put the address of the Page Table in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writeable flag.
    mov [es:di + 0x2000], eax         ; Store to value of EAX as the first PDE.
 
 
    push di                           ; Save DI for the time being.
    lea di, [di + 0x3000]             ; Point DI to the page table.
    mov eax, PAGE_PRESENT | PAGE_WRITE    ; Move the flags into EAX - and point it to 0x0000.
 
 
    ; Build the Page Table.
.LoopPageTable:
    mov [es:di], eax
    add eax, 0x1000
    add di, 8
    cmp eax, 0x200000                 ; If we did all 2MiB, end.
    jb .LoopPageTable
 
    pop di                            ; Restore DI.
 
    ; Disable IRQs
    mov al, 0xFF                      ; Out 0xFF to 0xA1 and 0x21 to disable all IRQs.
    out 0xA1, al
    out 0x21, al
 
    nop
    nop
 
    lidt [IDT]                        ; Load a zero length IDT so that any NMI causes a triple fault.
 
    ; Enter long mode.
    mov eax, 10100000b                ; Set the PAE and PGE bit.
    mov cr4, eax
 
    mov edx, edi                      ; Point CR3 at the PML4.
    mov cr3, edx
 
    mov ecx, 0xC0000080               ; Read from the EFER MSR. 
    rdmsr    
 
    or eax, 0x00000100                ; Set the LME bit.
    wrmsr
 
    mov ebx, cr0                      ; Activate long mode -
    or ebx,0x80000001                 ; - by enabling paging and protection simultaneously.
    mov cr0, ebx                    
 
    lgdt [GDT.Pointer]                ; Load GDT.Pointer defined below.
 
    jmp CODE_SEG:LongMode             ; Load CS with 64 bit segment and flush the instruction cache
 
 
    ; Global Descriptor Table
GDT:
.Null:
    dq 0x0000000000000000             ; Null Descriptor - should be present.
 
.Code:
    dq 0x0020980000000000             ; 64-bit code descriptor (exec/read).
    dq 0x0000920000000000             ; 64-bit data descriptor (read/write).
    dq 0x0020f80000000000             ; 64-bit data descriptor (read/write).
    dq 0x0000f20000000000             ; 64-bit data descriptor (read/write).
    times 10 dq 0
ALIGN 4
    dw 0                              ; Padding to make the "address of the GDT" field aligned on a 4-byte boundary
 
.Pointer:
    dw $ - GDT - 1                    ; 16-bit Size (Limit) of GDT.
    dd GDT                            ; 32-bit Base Address of GDT. (CPU will zero extend to 64-bit)
 
 
[BITS 64]      
LongMode:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0xffff800000007E00
    mov rbp, rsp

    mov rax, 0xffff800000a00000
    mov rbx, [rax]
    mov rax, KERNEL_START_SECTOR
    mov rbx, 0xffff800000100000
    ; 读取64个扇区
    mov rcx, 64
    call ReadLoader
    jmp 0xffff800000100000

ReadLoader:

    mov esi, eax
    mov rdi, rcx

    ;讀寫硬盤:
    ;第1步：設置要讀取的扇區數
    mov rdx,0x1f2
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
    mov [rbx],ax
    add rbx,2          
    loop .go_on_read
    ret


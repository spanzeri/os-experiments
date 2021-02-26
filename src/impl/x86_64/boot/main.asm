global start
extern long_mode_start

section .text
bits 32
start:
    ; Point esp to the top of the stack
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    ; Before we can switch to long mode (64 bit), we need to setup paging
    call setup_page_tables
    call enable_paging

    ; Now we have paging enabled, but we are not yet in 64 bit mode. We are
    ; in a compatible 32 bit mode

    ; Load a mandatory global descriptor table
    lgdt [gdt64.pointer]
    ; jmp to a 64 bit code segment
    jmp gdt64.code_segment:long_mode_start

check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "M"
    jmp error

check_cpuid:
    pushfd ; push flags to the stack
    pop eax ; get the flags from the stack
    mov ecx, eax ; make a copy of the flags
    xor eax, 1 << 21 ; flip the CPUID flag (21)
    push eax
    popfd ; pop the flags
    pushfd
    pop eax
    push ecx ; restore flags register
    popfd
    cmp eax, ecx ; compare with the original value to see if the cpu prevented
                 ; us from flipping the flag
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "C"
    jmp error

check_long_mode:
    ; Check for extended processor info
    mov eax, 0x80000000
    cpuid ; will store back in eax a value bigger than the magic above if supported
    cmp eax, 0x80000001
    jb .no_long_mode

    ; Check for long mode bit (LM bit)
    mov eax, 0x80000001
    cpuid ; will store in eax 1 << 29 if long mode is supported
    test edx, 1 << 29
    jz .no_long_mode
    ret
.no_long_mode:
    mov al, "L"
    jmp error

setup_page_tables:
    ; Pages are 4096 bytes aligned, the first 12 bits of the address are 0
    ; The cpu uses those 12 bits for flags
    ; Current we setup present and writable which are the first and second bits
    ; in the flags.
    ; When we switch to long mode, the execution resumes from the address that
    ; was in the register before switching mode. However, the address will be
    ; interpreted as a virtual address. To make sure the CPU can carry on executing
    ; we make sure to map the first virtual address to the same physical address
    ; (identity-mapping)
    mov eax, page_table_l3
    or eax, 0b11 ; present writeable
    mov [page_table_l4], eax

    mov eax, page_table_l2
    or eax, 0b11
    mov [page_table_l3], eax

    ; Every entry in the l2 table can have the huge page flag enabled.
    ; That tells the CPU the 9 bits point to a 2 MB physical address in memory.
    ; We fill the entire l2 page table with huge pages which allows us to
    ; identity map 2GB (512 pages * 2MB) of physical memory

    mov ecx, 0 ; counter
.loop:
    mov eax, 0x200000 ; 2MB
    mul ecx ; multiply the counter 2MB in eax which gives us the physical address
    or eax, 0b10000011 ; present, writeable and huge page (1 << 7 bit)
    mov [page_table_l2 + ecx * 8], eax ; store the current entry (counter * 8bytes) in the l2 page table

    inc ecx ; loop update
    cmp ecx, 512
    jne .loop

    ret

enable_paging:
    ; Pass page table location to the CPU
    mov eax, page_table_l4
    mov cr3, eax ; cr3 is where the CPU looks for the location of the l4 page table

    ; enable PAE (physical address extensions)
    mov eax, cr4
    or eax, 1 << 5 ; PAE flag
    mov cr4, eax

    ; enable long mode
    mov ecx, 0xc0000080 ; magic value to enable long mode
    rdmsr ; read model specific register, copies it into eax
    or eax, 1 << 8 ; write the enable long mode flag
    wrmsr ; write model specific register

    ; enable paging
    mov eax, cr0
    or eax, 1 << 31 ; flags to enable paging on cr0 register
    mov cr0, eax

    ret

error:
    ; Print "ERR: XX" where XX is the error code
    ; 4f stands for red background(4) white foreground (f)
    ; The video memory is written as 16 bits: 4 bg color, 4 fg color, 8 character
    ; e.g. the first line below is ER (litte endian):
    ;  4f (red bg, white fg) - 52 'R' - 4f (red bg, white fg) - 45 'E'
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al ; Override the last 20 from the previous dword with
                            ; our error code
    ; Stop the CPU
    hlt

section .bss
align 4096
page_table_l4:
    resb 4096
; For the time being, we reserve a single l3 and l2 page tables
page_table_l3:
    resb 4096
page_table_l2:
    resb 4096
; No l1 page table for now

stack_bottom:
    resb 4096 * 4 ; 16KB of stack memory
stack_top:

section .rodata
gdt64:
    dq 0 ; zero entry
.code_segment: equ $ - gdt64
    dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53) ; code segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

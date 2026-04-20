// source/boot/stage1.S
// (c) stuckin2004 - BSD-3-Clause

.code16
.section .boot, "ax"
.global _start

_start:
    cli
    xorw %ax, %ax       // Zero out segments
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw $0x7C00, %sp   // Stack will grow down

    // This is the fast A20 method
    inb $0x92, %al
    orb $2, %al
    outb %al, $0x92

    // Loads the GDT
    lgdt gdt_desc

    // Setting protected mode cr0 register
    movl %cr0, %eax
    orl $1, %eax
    movl %eax, %cr0

    // Long jump has been modified into this
    .byte 0xEA
    .long protected_mode
    .word 0x08

// Once in protected mode we set some more regs and jump into C
.code32
protected_mode:
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    movl $0x90000, %esp
    call _kstart

// If we ever get here, just die and halt up until user resets
.halt:
    cli
    hlt
    jmp .halt

// GDT for flat 32-bit protected mode
.align 8
gdt_start:
    // Null descriptor (required)
    .quad 0x0000000000000000

    // 0x08 - Code segment: base=0, limit=4GB, 32-bit, ring 0, executable/readable
    .word 0xFFFF        // Limit low
    .word 0x0000        // Base low
    .byte 0x00          // Base mid
    .byte 0x9A          // Access: present, ring 0, code, executable, readable
    .byte 0xCF          // Flags: 4KB gran, 32-bit + limit high nibble (0xF)
    .byte 0x00          // Base high

    // 0x10 - Data segment: base=0, limit=4GB, 32-bit, ring 0, read/write
    .word 0xFFFF        // Limit low
    .word 0x0000        // Base low
    .byte 0x00          // Base mid
    .byte 0x92          // Access: present, ring 0, data, read/write
    .byte 0xCF          // Flags: 4KB gran, 32-bit + limit high nibble (0xF)
    .byte 0x00          // Base high

gdt_end:

gdt_desc:
    .word gdt_end - gdt_start - 1    // GDT limit (size - 1)
    .long gdt_start                  // GDT base address

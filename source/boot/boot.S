.intel_syntax noprefix
// source/boot/stage1.S
// (c) stuckin2004 - BSD-3-Clause

.code16
.section .boot, "ax"
.global _start

_start:
    cli
    xor ax, ax      // Zero out segments
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  // Stack will grow down

    // This is the fast A20 method
    in al, 0x92
    or al, 2
    out 0x92, al

    // Loads the GDT
    lgdt [gdt_desc]

    // Setting protected mode cr0 register
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    // Long jump!
    jmp 0x08:protected_mode

// Once in protected mode we set some more regs and jump into C
.code32
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    call _kstart

// If we ever get here, just die and halt up until user resets
.halt:
    cli
    hlt
    jmp .halt

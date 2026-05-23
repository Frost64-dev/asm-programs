; Load the IDT and init the internal interrupt table
; In: None
; Out: None
; Truncates: r0, r1, r2, r3
load_idt:
    push sbp
    mov sbp, scp

    lidt idt

    mov r0, interrupt_table
    mov r1, 0
    mov r2, (256 * 8)
    call memset64

    mov scp, sbp
    pop sbp
    ret

; The global interrupt handler that gets called for all interrupts so registers can be saved
; In: Stack (in reverse push order): interrupt number, error code qword upper, error code lower, STS, IP
; Out: Stack (in order to pop): STS, IP
global_interrupt_handler:
    push sbp ; get a stack frame early for easier access of stuff pushed
    mov sbp, scp
    pusha
    push stp

    mov QWORD r0, QWORD [sbp - 8] ; interrupt number
    mov QWORD [CONSOLE_DEVICE_LOCATION], r0
    mov r1, QWORD [r0 * 8 + interrupt_table]
    cmp r1, 0
    jz panic
    
    call r1

    pop stp
    popa
    pop sbp
    sub scp, 0x18 ; remove error code and interrupt number
    iret

; Panic!
; In: None
; Out: None
panic:
    cmp BYTE [.in_panic], 0
    jnz .end ; don't get stuck in an interrupt loop

    cmp BYTE [Console_Ready], 1
    jnz .end ; can't print anything

    mov r0, panic_msg
    call Console_Print

.end:
    hlt

.in_panic:
    db 0

panic_msg:
    asciiz "PANIC!!!\n"

interrupt_table:
    skip (256 * 8)

%include "idt_entries.asm"
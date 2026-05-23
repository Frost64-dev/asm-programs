; Fill a memory region with a given 8-bit value
; In: r0 = pointer to memory region, r1 = value to fill, r2 = number of bytes
; Out: r0 = pointer to memory region
; Truncates: r3
memset:
    push sbp
    mov sbp, scp
    push r0

    cmp r2, 0
    jz .end

    mov r3, 0
.l:
    mov BYTE [r3 + r0], r1
    inc r3
    cmp r3, r2
    jl .l

.end:
    pop r0
    pop sbp
    ret


; Fill a memory region with a given 32-bit value.
; In: r0 = pointer to memory region, r1 = value to fill, r2 = number of 32-bit values to fill
; Out: r0 = pointer to memory region
; Truncates: r3
memset32:
    push sbp
    mov sbp, scp
    push r0

    cmp r2, 0
    jz .end

    mov r3, 0 ; counter
.l:
    mov DWORD [r3 * 4 + r0], r1
    inc r3
    cmp r3, r2
    jl .l

.end:
    pop r0
    pop sbp
    ret

; Fill a memory region with a given 64-bit value
; In: r0 = pointer to memory region, r1 = value to fill, r2 = number of bytes
; Out: r0 = pointer to memory region
; Truncates: r3
memset64:
    push sbp
    mov sbp, scp
    push r0

    cmp r2, 0
    jz .end

    mov r3, 0
.l:
    mov QWORD [r3 + r0], r1
    add r3, 8
    cmp r3, r2
    jl .l

.end:
    pop r0
    pop sbp
    ret

; Copy 32-bit values from one buffer to another
; In: r0 = dest, r1 = src, r2 = number of 32-bit values to copy
; Out: r0 = dest
; Truncates: r3
memcpy32:
    push sbp
    mov sbp, scp
    push r0

    cmp r2, 0
    jz .end

    mov r3, 0 ; counter
.l:
    mov DWORD [r3 * 4 + r0], DWORD [r3 * 4 + r1]
    inc r3
    cmp r3, r2
    jl .l

.end:
    pop r0
    pop sbp
    ret

; Copy 64-bit values from one buffer to another
; In: r0 = dest, r1 = src, r2 = number of bytes
; Out: r0 = dest
; Truncates: r3
memcpy64:
    push sbp
    mov sbp, scp
    push r0

    cmp r2, 0
    jz .end

    mov r3, 0
.l:
    mov QWORD [r3 + r0], QWORD [r1 + r3]
    add r3, 8
    cmp r3, r2
    jl .l

.end:
    pop r0
    pop sbp
    ret
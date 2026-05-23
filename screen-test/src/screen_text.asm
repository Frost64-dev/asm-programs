; Draw a character on the screen
; In: r0 = x, r1 = y, r2 = ARGB fg colour, r3 = ARGB bg colour, r4 = character (all assumed to be zero-extended)
; Pass through: r0-r3
; Truncates: r4-r7
Screen_DrawChar:
    push sbp
    mov sbp, scp

    ; save these registers for usage
    push r15
    push r14
    push r13
    push r12

    ; start by getting the font data for the character
    ; need to check if it is in bounds
    sub BYTE r4, 32
    cmp BYTE r4, 94
    jg .end

    ; character is valid, now we get the font data, will be stored in r15:r14
    mov r14, QWORD [r4 * 16 + font]
    mov r5, font
    add r5, 8
    mov r15, QWORD [r4 * 16 + r5]

    mov r6, 0 ; r6 = cy
.ly:
    mov r5, 0 ; r5 = cx
    mov r7, 7 ; r7 = i_cx
.lx:
    mov r12, r6
    cmp r12, 7
    jg .upper
    mov r13, r14
    jmp .common
.upper:
    sub r12, 8
    mov r13, r15
.common:
    shl r12, 3
    add r12, r7 ; r12 = cy * 8 + i_cx
    shr r13, r12
    and r13, 1
    jz .printbg
.printfg:
    push r3
    push r1
    push r0
    add r0, r5 ; r5 = cx
    add r1, r6 ; r6 = cy
    call Video_DrawPixel
    pop r0
    pop r1
    pop r3
.postprint:
    inc r5
    dec r7
    cmp r5, 8
    jnz .lx
    ; end of .lx
    inc r6
    cmp r6, 16
    jnz .ly

.end:
    pop r12
    pop r13
    pop r14
    pop r15
    mov scp, sbp
    pop sbp
    ret

.printbg:
    push r2
    push r1
    push r0
    mov r2, r3
    add r0, r5 ; r5 = cx
    add r1, r6 ; r6 = cy
    call Video_DrawPixel
    mov r3, r2
    pop r0
    pop r1
    pop r2
    jmp .postprint

; Write a null-terminated string to the screen
; In: r0 = x, r1 = y, r2 = ARGB fg colour, r3 = ARGB bg colour, r4 = string
; Out: r0 = x, r1 = y
; Pass through: r2 = ARGB fg colour, r3 = ARGB bg colour
Screen_WriteString:
    push sbp
    mov sbp, scp

    push r15
    push r14

    mov r14, 0 ; use r14 as counter
.l:
    mov r15, BYTE [r4+r14]
    cmp BYTE r15, 0
    jz .end
    cmp BYTE r15, '\n'
    jz .nl
    push r4
    mov r4, r15
    call Screen_DrawChar
    pop r4
    add r0, 10 ; 8 pixels data, 2 spacing
    cmp r0, DWORD [Screen_Size + 8]
    jl .endl
.nl:
    add r1, 16
    mov r0, 0
.endl:
    inc r14
    jmp .l
.end:
    pop r14
    pop r15
    mov scp, sbp
    pop sbp
    ret

; Initialise global variables relating to the screen
; Truncates: r0, r1
Screen_Init:
    call Video_GetSize
    ; start with width and height
    mov DWORD [Screen_Size + 8], r0
    mov DWORD [Screen_Size + 12], r1

    ; do rows first as they are easier
    shr r1, 4
    mov DWORD [Screen_Size + 4], r1

    ; now for columns - we need to use div
    mov r1, 0
    div r1, r0, 10
    mov DWORD [Screen_Size], r0
    ret

Screen_Size:
    dd 0 ; columns
    dd 0 ; rows
    dd 0 ; width in pixels
    dd 0 ; height in pixels

Screen_State:
    dq 0
    dq 0
    dq 0
    dq 0

%include "../include/font.inc"
%define MOUSE_SINT 17
%define MOUSE_INT_IDX 1

%define CURSOR_COLOUR 0xFFFFFFFF

; Init the mouse device
Mouse_Init:
    push sbp
    mov sbp, scp

    ; Put the handler in the table
    mov QWORD [interrupt_table + (MOUSE_SINT * 8)], Mouse_IntHandler

    ; Map the interrupt
    mov r0, HID_DEVICE_ID
    mov r1, MOUSE_INT_IDX
    mov r2, MOUSE_SINT
    call IO_SetInterrupt
    cmp r0, 0
    jnz .error

    ; enable interrupts on the mouse device
    mov QWORD [HID_MOUSE_REG], 3 ; EN | INT
    mov r0, HID_COMMAND_SET_DEV_INFO
    call HID_Command
    cmp r0, 0
    jnz .error

    ; confirm that they are enabled
    mov r0, QWORD [HID_STATUS_REG]
    and r0, 6 ; MSE_EN | MSE_INT
    cmp r0, 6
    jnz .error

    mov r0, 0

.end:
    mov scp, sbp
    pop sbp
    ret

.error:
    mov r0, 1
    jmp .end

Mouse_IntHandler:
    push sbp
    mov sbp, scp

    ; Print a message
    ; mov r0, mouse_int_msg
    ; call Console_Print

    ; read the data
    mov r0, QWORD [HID_MOUSE_REG]
    and r0, 0xFFFFFFFF ; dx, dy
    mov r1, r0
    shr r1, 16
    and r0, 0xFFFF
    call Mouse_MoveCursor
    

    ; mov r0, QWORD [Screen_State]
    ; mov r1, QWORD [Screen_State + 8]
    ; mov r2, QWORD [Screen_State + 16]
    ; mov r3, QWORD [Screen_State + 24]
    ; mov r4, mouse_print_str
    ; call Screen_WriteString
    ; mov QWORD [Screen_State], r0
    ; mov QWORD [Screen_State + 8], r1
    ; mov QWORD [Screen_State + 16], r2
    ; mov QWORD [Screen_State + 24], r3

.end:
    ; Ack
    mov r0, HID_COMMAND_ACK_IRQ1
    call HID_Command

    mov scp, sbp
    pop sbp
    ret

; Move the mouse cursor to a new location
; Inputs: r0 = dx, r1 = dy
; Truncates: r0-r5
Mouse_MoveCursor:
    push sbp
    mov sbp, scp

    push r15
    push r14

    mov r14, QWORD [cursorLastX]
    mov r15, QWORD [cursorLastY]
    add r14, WORD r0
    add r15, WORD r1

    cmp BYTE [cursorFirstRun], 1
    jz .from

    mov r0, QWORD [cursorLastX]
    mov r1, QWORD [cursorLastY]
    mov r2, 8
    mov r3, 8
    mov r4, cursorBackgroundSave
    call Video_ToScreen

.from:
    mov r0, r14
    mov r1, r15
    mov r2, 8
    mov r3, 8
    mov r4, cursorBackgroundSave
    call Video_FromScreen

    mov r0, cursorRenderBuffer
    mov r1, cursorBackgroundSave
    mov r2, 256
    call memcpy64

    mov r1, 0

.l:
    mov r4, BYTE [cursorMask + r1]
    mov r2, 8
.l2:
    mov r3, r4
    and r3, 0x80
    movnz DWORD [r0], CURSOR_COLOUR

    add r0, 4
    shl r4, 1

    dec r2
    jnz .l2

    inc r1
    cmp r1, 8
    jl .l

    mov r0, r14
    mov r1, r15
    mov r2, 8
    mov r3, 8
    mov r4, cursorRenderBuffer
    call Video_ToScreen

    mov QWORD [cursorLastX], r14
    mov QWORD [cursorLastY], r15
    mov BYTE [cursorFirstRun], 0

    pop r14
    pop r15

.end:
    mov scp, sbp
    pop sbp
    ret

/*
r0 = cursorRenderBuffer
r1 = row = 0
.l {
    r4 = BYTE [cursorMask + r1]
    r2 = col = 8
    .l2 {
        r3 = r4
        r3 &= 0x80
        if (r3 > 0) ; use conditional move -> movnz DWORD [r0], CURSOR_COLOUR
            [r0] = CURSOR_COLOUR

        r0 += 4
        r4 <<= 1

        r2--
        if (r2 != 0)
            goto .l2
    }
    r1++
    if (r1 < 8)
        goto .l
}
*/

cursorMask:
    db 0x80
    db 0xC0
    db 0xE0
    db 0xF0
    db 0xF8
    db 0xF0
    db 0xD8
    db 0x0C

cursorBackgroundSave:
    skip 256

cursorRenderBuffer:
    skip 256

cursorLastX:
    dq 0
cursorLastY:
    dq 0
cursorFirstRun:
    db 1

mouse_print_str:
    asciiz " "

mouse_int_msg:
    asciiz "Mouse Interrupt!\n"
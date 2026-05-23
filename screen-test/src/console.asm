%define CONSOLE_DEVICE_LOCATION 0xE0000000

; Initialise the console device
; Out: r0 = 0 for success
Console_Init:
    push sbp
    mov sbp, scp

    ; find the device
    mov r0, 0
    call IO_FindDevice
    cmp r0, -1
    jz .error

    ; set the base address
    mov r0, 0
    mov r1, CONSOLE_DEVICE_LOCATION
    call IO_SetBase
    cmp r0, -1
    jz .error

    mov BYTE [Console_Ready], 1

    mov r0, 0

.end:
    mov scp, sbp
    pop sbp
    ret

.error:
    mov r0, 1
    jmp .end

; Print a null-terminated string to the console
; In: r0 = null-terminated string
Console_Print:
    mov r1, 0 ; use r1 as counter
.l:
    mov r2, BYTE [r0+r1]
    cmp BYTE r2, 0
    jz .end
    mov BYTE [CONSOLE_DEVICE_LOCATION], BYTE r2
    inc r1
    jmp .l
.end:
    ret

; set to 1 when the console is ready
Console_Ready:
    db 0
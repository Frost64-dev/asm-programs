%define KEYBOARD_SINT 16
%define KEYBOARD_INT_IDX 0

; Init the keyboard device
Keyboard_Init:
    push sbp
    mov sbp, scp

    ; Put the handler in the table
    mov QWORD [interrupt_table + (KEYBOARD_SINT * 8)], Keyboard_IntHandler

    ; Map the interrupt
    mov r0, HID_DEVICE_ID
    mov r1, KEYBOARD_INT_IDX
    mov r2, KEYBOARD_SINT
    call IO_SetInterrupt
    cmp r0, 0
    jnz .error

    ; enable interrupts on the keyboard device
    mov QWORD [HID_KEYBOARD_REG], 3 ; EN | INT
    mov r0, HID_COMMAND_SET_DEV_INFO
    call HID_Command
    cmp r0, 0
    jnz .error

    ; confirm that they are enabled
    mov r0, QWORD [HID_STATUS_REG]
    and r0, 6 ; KBD_EN | KBD_INT
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

Keyboard_IntHandler:
    push sbp
    mov sbp, scp

    ; Print a message
    ; mov r0, keyboard_int_msg
    ; call Console_Print

    ; read the data
    mov r0, QWORD [HID_KEYBOARD_REG]
    mov r1, r0 ; backup to r1

    and r0, 0x10000 ; release flag
    jz .end

    mov r0, r1
    and r1, 0xff ; isolate scancode

    and r0, 0xC00
    jz .normal

    ; left and/or right shift is pressed
    mov BYTE [keyboard_print_str], BYTE [alt_keycode_table + r1]
    jmp .print

.normal:
    mov BYTE [keyboard_print_str], BYTE [normal_keycode_table + r1]

.print:
    mov r0, keyboard_print_str
    call Console_Print

    mov r0, QWORD [Screen_State]
    mov r1, QWORD [Screen_State + 8]
    mov r2, QWORD [Screen_State + 16]
    mov r3, QWORD [Screen_State + 24]
    mov r4, keyboard_print_str
    call Screen_WriteString
    mov QWORD [Screen_State], r0
    mov QWORD [Screen_State + 8], r1
    mov QWORD [Screen_State + 16], r2
    mov QWORD [Screen_State + 24], r3

.end:
    ; Ack
    mov r0, HID_COMMAND_ACK_IRQ0
    call HID_Command

    mov scp, sbp
    pop sbp
    ret

keyboard_print_str:
    asciiz " "

keyboard_int_msg:
    asciiz "Keyboard Interrupt!\n"
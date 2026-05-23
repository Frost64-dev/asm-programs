%define HID_COMMAND_INIT 0
%define HID_COMMAND_GET_DEV_INFO 1
%define HID_COMMAND_SET_DEV_INFO 2
%define HID_COMMAND_ACK_IRQ0 3
%define HID_COMMAND_ACK_IRQ1 4

%define HID_DEVICE_ID 3

%define HID_COMMAND_REG 0xE0002000
%define HID_STATUS_REG  0xE0002008
%define HID_KEYBOARD_REG 0xE0002010
%define HID_MOUSE_REG 0xE0002018

; Find and initialise the HID device bus
; Out: r0 = 0 for success
HID_Init:
    push sbp
    mov sbp, scp

    ; find the device
    mov r0, HID_DEVICE_ID
    call IO_FindDevice
    cmp r0, -1
    jz .error

    ; set the base address
    mov r0, HID_DEVICE_ID
    mov r1, HID_COMMAND_REG
    call IO_SetBase
    cmp r0, -1
    jz .error

    ; Initialise the device, initialising the keyboard & mouse, but no interrupts
    mov QWORD [HID_KEYBOARD_REG], 1
    mov QWORD [HID_MOUSE_REG], 1
    mov r0, HID_COMMAND_INIT
    call HID_Command
    cmp r0, 0
    jnz .error

    ; ensure status.KBD_EN is set
    mov r0, QWORD [HID_STATUS_REG]
    and r0, 0x2
    jz .error

    call Keyboard_Init
    cmp r0, 1
    jz .end
    
    call Mouse_Init

.end:
    mov scp, sbp
    pop sbp
    ret

.error:
    mov r0, 1
    jmp .end


; Run a command on the HID bus, data registers should be set before calling
; In: r0 = command
; Out: r0 = 0 for success
HID_Command:
    mov QWORD [HID_COMMAND_REG], r0
    mov r0, QWORD [HID_STATUS_REG]
    and r0, 1
    ret


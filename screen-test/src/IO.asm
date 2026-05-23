%define IO_BUS_COMMAND 0xFFFFFF10
%define IO_BUS_STATUS  0xFFFFFF18
%define IO_BUS_DATA    0xFFFFFF20

%define IOB_COM_GET_BUS_INFO 0
%define IOB_COM_GET_DEV_INFO 1
%define IOB_COM_SET_DEV_INFO 2
%define IOB_COM_GET_INT_MAP  3
%define IOB_COM_SET_INT_MAP  4

; Find a device on the I/O bus from its ID
; In: r0 = device ID
; Out: r0 = index, -1 on error / not found
IO_FindDevice:
    push sbp
    mov sbp, scp

    mov r4, r0 ; save the ID to r4 for safe keeping

    ; start with getting the number of devices in the bus
    mov r0, IOB_COM_GET_BUS_INFO
    call IO_RunCommand
    cmp r0, 1
    jz .error

    mov r3, QWORD [IO_BUS_DATA] ; r3 now contains the number of devices
    cmp r3, 0
    jz .error ; no devices

    ; now scan through the devices and find one with a matching ID
    mov r2, 0 ; use r2 as a counter
.l:
    mov QWORD [IO_BUS_DATA], r2 ; set the data register to the index
    mov r0, IOB_COM_GET_DEV_INFO ; get info about the current device
    call IO_RunCommand
    cmp r0, 1
    jz .error
    cmp QWORD [IO_BUS_DATA], r4 ; check the ID
    jz .found
    
    inc r2
    cmp r2, r3
    jnz .l

    ; not found
    jmp .error

.found:
    mov r0, r2 ; get the index
    ; fall through

.end:
    mov scp, sbp
    pop sbp
    ret

.error:
    mov r0, -1
    jmp .end

; Set the base address of an I/O device
; In: r0 = ID, r1 = base address
; Out: r0 = 0 on success
IO_SetBase:
    mov QWORD [IO_BUS_DATA], r0
    mov QWORD [IO_BUS_DATA + 8], r1
    mov r0, IOB_COM_SET_DEV_INFO
    jmp IO_RunCommand

; Set the interrupt mapping of an I/O device
; In: r0 = ID, r1 = interrupt index, r2 = SINT
; Out: r0 = 0 on success
IO_SetInterrupt:
    mov QWORD [IO_BUS_DATA], r0
    mov QWORD [IO_BUS_DATA + 8], r1
    mov BYTE [IO_BUS_DATA + 16], BYTE r2
    mov r0, IOB_COM_SET_INT_MAP
    jmp IO_RunCommand

; Run a command on the I/O bus, data is assumed to already be filled
; In: r0 = command
; Out: r0 = status
; Truncates: none
IO_RunCommand:
    mov QWORD [IO_BUS_COMMAND], r0
.l: ; command is complete when bit 0 is set to one, so loop until that occurs
    mov r0, QWORD [IO_BUS_STATUS]
    and r0, 1
    cmp r0, 0
    jz .l

    mov r0, QWORD [IO_BUS_STATUS] ; get the status for the return value
    shr r0, 1 ; get rid of the command complete bit
    ret

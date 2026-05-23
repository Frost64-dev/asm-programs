%define VIDEO_DEVICE_COMMAND 0xE0001000
%define VIDEO_DEVICE_DATA 0xE0001008
%define VIDEO_DEVICE_STATUS 0xE0001010

%define FRAMEBUFFER_ADDR 0xE1000000

; Find and Initialise the video device
; Out: r0 = 0 for success
Video_Init:
    push sbp
    mov sbp, scp

    ; find the device
    mov r0, 1
    call IO_FindDevice
    cmp r0, -1
    jz .error

    ; set the base address
    mov r0, 1
    mov r1, VIDEO_DEVICE_COMMAND
    call IO_SetBase
    cmp r0, -1
    jz .error

    ; Initialise the device
    mov QWORD [VIDEO_DEVICE_COMMAND], 0
    cmp QWORD [VIDEO_DEVICE_STATUS], 0
    jnz .error

    ; Next get the native mode details from the screen details and then get the corresponding mode

    ; Start with getting the screen info
    mov QWORD [VIDEO_DEVICE_DATA], Video_Device_Buffer0
    mov QWORD [VIDEO_DEVICE_COMMAND], 1
    cmp QWORD [VIDEO_DEVICE_STATUS], 0
    jnz .error

    mov r3, QWORD [Video_Device_Buffer0] ; width & height
    mov r4, WORD [Video_Device_Buffer0+10] ; bpp
    mov r5, WORD [Video_Device_Buffer0+8] ; hz
    mov r7, WORD [Video_Device_Buffer0+12] ; number of modes

    cmp r7, 0
    jz .error

    ; now we go through the modes and find it

    mov r2, 0 ; use as counter
.l:
    mov QWORD [Video_Device_Buffer0], Video_Device_Buffer0
    mov WORD [Video_Device_Buffer0+8], r2
    mov QWORD [VIDEO_DEVICE_DATA], Video_Device_Buffer0
    mov QWORD [VIDEO_DEVICE_COMMAND], 2
    cmp QWORD [VIDEO_DEVICE_STATUS], 0
    jnz .error
    cmp QWORD [Video_Device_Buffer0], r3 ; width & height
    jnz .not_found
    cmp WORD [Video_Device_Buffer0+8], r4 ; bpp
    jnz .not_found
    cmp WORD [Video_Device_Buffer0+14], r5 ; hz
    jz .found
.not_found:
    inc r2
    cmp r2, r7
    jnz .l
    jmp .error

.found:
    mov QWORD [Video_Device_NativeMode], r2 ; index
    mov QWORD [Video_Device_NativeMode+8], r3 ; width & height
    mov QWORD [Video_Device_NativeMode+16], QWORD [Video_Device_Buffer0+8] ; bpp, pitch, hz

    ; we now have the details of the default mode, so we can set mode and create the framebuffer

    mov QWORD [Video_Device_Buffer0], FRAMEBUFFER_ADDR
    mov WORD [Video_Device_Buffer0 + 8], WORD [Video_Device_NativeMode]
    mov QWORD [VIDEO_DEVICE_DATA], Video_Device_Buffer0
    mov QWORD [VIDEO_DEVICE_COMMAND], 3
    cmp QWORD [VIDEO_DEVICE_STATUS], 0
    jnz .error

    ; mode is now set
    mov r0, 0

.end:
    mov scp, sbp
    pop sbp
    ret

.error:
    mov r0, 1
    jmp .end

; Clear the screen
; In: r0 = ARGB colour
Video_ClearScreen:
    mov r1, r0
    mov r2, DWORD [Video_Device_NativeMode + 18]
    mul r0, r2, DWORD [Video_Device_NativeMode + 12] ; r0 just gets cleared, doesn't really matter
    shr r2, 2 ; fast divide by 4
    mov r0, FRAMEBUFFER_ADDR
    jmp memset32

; Draw a pixel
; In: r0 = x, r1 = y, r2 = ARGB colour
; Truncates: r0, r1, r3
Video_DrawPixel:
    mul r3, r1, DWORD [Video_Device_NativeMode + 18] ; r3:r1 = y * pitch, r3 gets ignored
    mul r3, r0, WORD [Video_Device_NativeMode + 16] ; r3:r0 = x * bpp, once again r3 gets ignored
    shr r0, 3 ; r0 /= 8 -> r0 = x * bpp / 8
    add r0, r1 ; r0 += r1 -> r0 = y * pitch + x * bpp / 8
    mov DWORD [FRAMEBUFFER_ADDR + r0], r2
    ret

; Get the size of the device
; In: None
; Out: r0 = width, r1 = height
Video_GetSize:
    mov r0, DWORD [Video_Device_NativeMode + 8]
    mov r1, DWORD [Video_Device_NativeMode + 12]
    ret

/*
r0 <<= 2;
r0 += FRAMEBUFFER_ADDR;
r5:r1 = r1 * pitch;
r0 += r1
r1 = r3
.l {
    push r1
    r1 = r4
    memcpy32(r0, r1, r2)
    r4 = r1
    pop r1
    if (r1 == 0)
        return;
    r1--;
    r0 += pitch;
    r2 <<= 2;
    r4 += r2
    r2 >>= 2;
}
*/

; Draw a rect on the screen
; In: r0 = x, r1 = y, r2 = width, r3 = height, r4 = data
; Out: None
; Truncates: r0, r1, r3, r4, r5
Video_ToScreen:
    push sbp
    mov sbp, scp

    shl r0, 2 ; r0 = x * 4 (bpp)
    add r0, FRAMEBUFFER_ADDR ; r0 = FRAMEBUFFER_ADD + x * 4
    mul r5, r1, DWORD [Video_Device_NativeMode + 18] ; r5:r1 = y * pitch
    add r0, r1 ; r0 = FRAMEBUFFER_ADD + x * 4 + y * pitch

    mov r1, r3 ; r3 gets truncated by memcpy32

.l:
    push r1
    mov r1, r4
    call memcpy32
    pop r1
    
    cmp r1, 0
    jz .end

    dec r1
    add r0, DWORD [Video_Device_NativeMode + 18] ; r0 += pitch
    shl r2, 2
    add r4, r2 ; r4 += width * 4
    shr r2, 2
    jmp .l

.end:
    mov scp, sbp
    pop sbp
    ret

; Copy a rect from the screen
; In: r0 = x, r1 = y, r2 = width, r3 = height, r4 = data
; Out: None
; Truncates: r0, r1, r3, r4, r5
Video_FromScreen:
    push sbp
    mov sbp, scp

    shl r0, 2 ; r0 = x * 4 (bpp)
    add r0, FRAMEBUFFER_ADDR ; r0 = FRAMEBUFFER_ADDR + x * 4
    mul r5, r1, DWORD [Video_Device_NativeMode + 18] ; r5:r1 = y * pitch
    add r0, r1 ; r0 = FRAMEBUFFER_ADDR + x * 4 + y * pitch

    mov r1, r3 ; r3 gets truncated by memcpy32

.l:
    push r1
    mov r1, r0
    mov r0, r4
    call memcpy32
    mov r0, r1
    pop r1
    
    cmp r1, 0
    jz .end

    dec r1
    add r0, DWORD [Video_Device_NativeMode + 18] ; r0 += pitch
    shl r2, 2
    add r4, r2 ; r4 += width * 4
    shr r2, 2
    jmp .l

.end:
    mov scp, sbp
    pop sbp
    ret


Video_Device_Buffer0:
    dq 0
    dq 0

Video_Device_NativeMode:
    dq 0 ; index
    dd 0 ; width
    dd 0 ; height
    dw 0 ; bpp
    dd 0 ; pitch
    dw 0 ; hz

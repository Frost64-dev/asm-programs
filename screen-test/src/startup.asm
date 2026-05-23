org 0xF0000000

; This is where we first start, need to get into protected mode before we do anything
_real_mode_entry:
    ; start with the stack
    mov sbp, stack_start
    mov scp, stack_start
    mov stp, stack_end

    ; next is the IDT
    call load_idt

    ; now we are ready for protected mode
    mov cr0, 1

    ; fall through

_entry:
    ; Get the console device working
    call Console_Init
    cmp r0, 0
    jnz .error

    mov r0, message
    call Console_Print

    ; Initialise the video device
    call Video_Init
    cmp r0, 0
    jnz .video_init_error

    call Screen_Init

    ; Clear the screen blue
    ; mov r0, 0xFF0000FF
    ; call Video_ClearScreen

    mov r0, 0
    mov r1, 0
    mov r2, 0xFFFFFFFF
    mov r3, 0xFF000000
    mov r4, screen_message
    call Screen_WriteString

    mov QWORD [Screen_State], r0
    mov QWORD [Screen_State + 8], r1
    mov QWORD [Screen_State + 16], r2
    mov QWORD [Screen_State + 24], r3


    call HID_Init
    cmp r0, 0
    jnz .keyboard_init_error

    mov r0, keyboard_init_success_msg
    call Console_Print

    jmp .end
 

.video_init_error:
    mov r0, video_init_error_msg
    call Console_Print
    jmp .error

.keyboard_init_error:
    mov r0, keyboard_init_error_msg
    call Console_Print

.error:
    ; can't do much without the console device

.end:
    jmp .end
    hlt

%include "console.asm"
%include "IO.asm"
%include "screen_text.asm"
%include "util.asm"
%include "video.asm"
%include "HID/HID.asm"
%include "HID/Keyboard.asm"
%include "HID/Mouse.asm"

%include "idt.asm"
%include "stack.asm"

%include "../include/keycodes.inc"

message:
    asciiz "Hello, World!\n"

screen_message:
    asciiz "Hello from the screen!\nAnd newlines work!\n"

video_init_error_msg:
    asciiz "Failed to initialise the video device.\n"

keyboard_init_error_msg:
    asciiz "Failed to initialise the keyboard device.\n"

keyboard_init_success_msg:
    asciiz "Keyboard init success!\n"
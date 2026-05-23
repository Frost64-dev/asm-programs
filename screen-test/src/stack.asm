; align the stack to start at the beginning of a page
align 4096

; stack is 4 pages, or 16KiB
stack_start:
    ; skip 16384
    skip 1024
stack_end:
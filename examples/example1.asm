    ORG 0x8000

    CALL debug_init      ; Set up screen output (do this once)

    LD HL, msg           ; Point HL at our string
    CALL print_string    ; Prints: Hello!
    LD A, 13
    RST 0x10            ; Newline

    LD A, 42
    CALL print_number    ; Prints: 42
    LD A, 13
    RST 0x10            ; Newline

    LD A, '*'
    CALL print_char      ; Prints: *

    RET                  ; Return to BASIC

msg: DB "Hello!", 0

    INCLUDE "debug_output.asm"
    END 0x8000
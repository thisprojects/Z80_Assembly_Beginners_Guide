    ORG 0x8000

    CALL debug_init

    ; Print header
    LD HL, msg_header
    CALL print_string
    LD A, 13
    RST 0x10            ; Newline

    ; Count from 0 to 20
    LD C, 0              ; C = counter
main_loop:
    LD A, C
    CALL print_number    ; Display current value
    LD A, ' '
    CALL print_char      ; Space separator

    INC C
    LD A, C
    CP 21                ; Reached 21 yet?
    JP NZ, main_loop     ; No - keep counting

    ; Finished counting
    LD A, 13
    RST 0x10            ; Newline
    LD A, 13
    RST 0x10            ; Newline

    ; Verify: C should be 21
    LD A, C
    CP 21
    JP NZ, verify_fail

    LD HL, msg_pass
    CALL print_string
    JP done

verify_fail:
    LD HL, msg_fail
    CALL print_string
    LD A, C
    CALL print_number

done:
    LD A, 13
    RST 0x10            ; Newline
    RET                  ; Return to BASIC

msg_header: DB "Counting 0 to 20:", 0
msg_pass:   DB "Verification PASSED", 0
msg_fail:   DB "FAILED! C = ", 0

    INCLUDE "debug_output.asm"

    END 0x8000

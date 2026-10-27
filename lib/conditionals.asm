    ORG 0x8000
    CALL debug_init
    LD A, (var_a)        ; Load a
    CP 10                ; Compare with 10 (sets Z if equal)
    JP NZ, else_block    ; If not equal, jump to else

    ; If block (a == 10)
    LD A, 1
    LD (var_b), A
    LD HL, msg_equal
    CALL print_string    ; Print confirmation
    JP end_if            ; Skip the else block

else_block:
    ; Else block (a != 10)
    LD A, 0
    LD (var_b), A
    LD HL, msg_noteq
    CALL print_string    ; Print confirmation

end_if:
    LD A, 13
    RST 0x10            ; Newline
    RET

msg_equal: DB "a equals 10", 0
msg_noteq: DB "a is not 10", 0
var_a: DB 10
var_b: DB 0

    INCLUDE "debug_output.asm"
    END 0x8000

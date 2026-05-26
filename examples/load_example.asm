    ORG 0x8000

    CALL debug_init          ; Open the screen channel (do this first)

    ; --- my_byte (a single 8-bit value: 42) ---
    LD HL, label_byte
    CALL print_string        ; Print label
    LD A, (my_byte)          ; Load the byte from memory
    CALL print_number        ; Prints: 42
    LD A, 13
    RST 0x10                 ; Newline

    ; --- my_word (16-bit value: 1000, shown as two bytes) ---
    LD HL, label_word_lo
    CALL print_string        ; Print label
    LD A, (my_word)          ; Low byte of 1000 = 232 (0xE8)
    CALL print_number        ; Prints: 232
    LD A, 13
    RST 0x10                 ; Newline
    LD HL, label_word_hi
    CALL print_string        ; Print label
    LD A, (my_word + 1)      ; High byte of 1000 = 3 (0x03)
    CALL print_number        ; Prints: 3
    LD A, 13
    RST 0x10                 ; Newline

    ; --- my_string (null-terminated: "Hello") ---
    LD HL, label_str
    CALL print_string        ; Print label
    LD HL, my_string
    CALL print_string        ; Prints: Hello
    LD A, 13
    RST 0x10                 ; Newline

    ; --- my_array (5 consecutive bytes: 1 2 3 4 5) ---
    ; PUSH HL before each print_number call to protect our pointer,
    ; POP HL after to restore it, then INC HL to advance to the next element.
    LD HL, label_arr
    CALL print_string        ; Print label
    LD HL, my_array          ; Point HL at the first element
    LD A, (HL)
    PUSH HL                  ; Save HL — print_number will clobber it
    CALL print_number        ; Prints: 1
    POP HL                   ; Restore HL so we know where we are
    LD A, 32
    RST 0x10                 ; Space
    INC HL                   ; Advance to element 2
    LD A, (HL)
    PUSH HL
    CALL print_number        ; Prints: 2
    POP HL
    LD A, 32
    RST 0x10                 ; Space
    INC HL                   ; Advance to element 3
    LD A, (HL)
    PUSH HL
    CALL print_number        ; Prints: 3
    POP HL
    LD A, 32
    RST 0x10                 ; Space
    INC HL                   ; Advance to element 4
    LD A, (HL)
    PUSH HL
    CALL print_number        ; Prints: 4
    POP HL
    LD A, 32
    RST 0x10                 ; Space
    INC HL                   ; Advance to element 5
    LD A, (HL)
    CALL print_number        ; Prints: 5 (no PUSH/POP needed — we're done with HL)
    LD A, 13
    RST 0x10                 ; Newline

    RET                      ; Return to BASIC

; --- Data ---
my_byte:   DB 42
my_word:   DW 1000
my_string: DB "Hello", 0
my_array:  DB 1, 2, 3, 4, 5

; --- Output labels ---
label_byte:    DB "my_byte:    ", 0
label_word_lo: DB "my_word lo: ", 0
label_word_hi: DB "my_word hi: ", 0
label_str:     DB "my_string:  ", 0
label_arr:     DB "my_array:   ", 0

    INCLUDE "debug_output.asm"
    END 0x8000
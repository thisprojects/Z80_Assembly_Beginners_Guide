; =============================================================
; debug_output.asm - Debug Display Routines for ZX Spectrum
; =============================================================
; INCLUDE this file in your program or copy the routines below.
;
; Call debug_init once at the start of your program to set up
; the screen channel. Then use:
;
;   print_char    - Print a single character.  Input: A = char
;   print_string  - Print a null-terminated string.  Input: HL
;   print_number  - Print an 8-bit number (0-255).  Input: A
;
; For a newline, just do: LD A, 13 / RST 0x10
; =============================================================

; --- Call once at program start to open screen channel ---
debug_init:
    LD A, 2             ; Channel 2 = main screen
    CALL 0x1601         ; ROM: open channel
    RET

; --- Print a single character in A ---
print_char:
    RST 0x10            ; ROM: print character in A
    RET

; --- Print null-terminated string at HL ---
print_string:
    LD A, (HL)
    OR A                ; Check for null terminator
    RET Z               ; Return if end of string
    RST 0x10            ; ROM: print character
    INC HL
    JR print_string

; --- Print 8-bit unsigned number in A (0-255) ---
print_number:
    PUSH BC
    LD B, 0
    LD C, A             ; BC = the number
    CALL 0x2D28         ; ROM: STACK_BC - push onto calculator stack
    CALL 0x2DE3         ; ROM: PRINT_FP - print the number
    POP BC
    RET

; =============================================================
; END OF DEBUG ROUTINES
; =============================================================
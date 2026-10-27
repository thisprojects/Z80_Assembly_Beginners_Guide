ORG 0x8000

; Open channel 2 (main screen)
LD A, 2
CALL 0x1601

; Point HL at our message
LD HL, message

print_loop:
    LD A, (HL)          ; load next character
    CP 0                ; is it the null terminator?
    JP Z, done          ; if yes, we're finished
    RST 0x10            ; print it
    INC HL              ; move to next character
    JP print_loop

done:
    RET

message:
    DB "Hello from Z80!", 0

END 0x8000

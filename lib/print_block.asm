ORG 0x8000

; Open channel 2
LD A, 2
CALL 0x1601

; Print a string using the ROM block print
LD DE, message       ; DE = address of string
LD BC, msg_len       ; BC = number of bytes to print
CALL 0x203C          ; ROM routine: print BC bytes from DE

RET

message:
    DB "Printed with one CALL!"
msg_len EQU $ - message

END 0x8000

ORG 0x8000

; Open channel 2
LD A, 2
CALL 0x1601

; Print prompt
LD DE, prompt
LD BC, prompt_len
CALL 0x203C

; Wait for a keypress.  WAIT-KEY only works on the keyboard channel
; (channel 1), so switch to it first and back to the screen afterwards
LD A, 1
CALL 0x1601
CALL 0x15D4          ; WAIT-KEY: blocks until key pressed
                     ; key code returned in A
PUSH AF              ; keep the key while we switch channel
LD A, 2
CALL 0x1601          ; back to the main screen
POP AF

; Print the key that was pressed
RST 0x10             ; print it

RET

prompt:
    DB "Press a key: "
prompt_len EQU $ - prompt

END 0x8000

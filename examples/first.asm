; Save this as first.asm
    ORG 0x8000           ; Code starts at address 32768

    LD A, 2              ; Channel 2 = main screen
    CALL 0x1601          ; ROM: open channel
    LD A, 42             ; ASCII '*'
    RST 0x10             ; ROM: print character
    RET                  ; Return to BASIC

    END 0x8000           ; Entry point for BASIC loader
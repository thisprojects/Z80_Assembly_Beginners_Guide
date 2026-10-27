# lib tests

Assembles every file in `lib/` (pasmo, as the book does, and sjasmplus as a cross-check), then runs
them on an emulated Z80 with the **real 48K Spectrum ROM** and checks what ends up on screen:
printed text, attributes, border colours, key input, beeper edges, and the register results of
`divide`, `print_number` and `assert_a_equals`.

Needs `pasmo` and `sjasmplus` on the PATH, the Python `z80` package, and a 48K ROM image
(found automatically inside Fuse.app on macOS, or set `Z80_ROM=/path/to/48.rom`):

    python3 -m venv .venv && .venv/bin/pip install -r tests/requirements.txt
    .venv/bin/python tests/test_lib.py              # all tests
    .venv/bin/python tests/test_lib.py loops beep   # some tests by name

Not covered: exact timing/frequencies, tape loading, the BASIC loader produced by `--tapbas`.

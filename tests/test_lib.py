"""Tests for lib/*.asm: assemble every file, then run it on an emulated Z80 with the real
48K Spectrum ROM and check what appears on screen.  See tests/README.md."""
import os, re, subprocess, sys, tempfile
import z80

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = f'{ROOT}/lib'
TMP = tempfile.mkdtemp(prefix='z80beginners_')

ROM_CANDIDATES = [os.environ.get('Z80_ROM', ''),
                  '/Applications/Fuse.app/Contents/Resources/48.rom',
                  '/usr/share/spectrum-roms/48.rom', '/usr/share/fuse/48.rom', '/usr/local/share/fuse/48.rom']
ROM_PATH = next((p for p in ROM_CANDIDATES if p and os.path.exists(p)), None)
if not ROM_PATH:
    sys.exit('48K ROM not found: set Z80_ROM=/path/to/48.rom')
ROM = open(ROM_PATH, 'rb').read()
FONT = {bytes(ROM[0x3D00 + i * 8:0x3D00 + i * 8 + 8]): chr(32 + i) for i in range(96)}
RET_ADDR = 0x1000          # breakpoint address used as "return to BASIC"


# ---- assembling -------------------------------------------------------------
def pasmo_bin(name):
    """Assemble lib/<name>.asm exactly as the book says (pasmo); return the raw bytes."""
    out = f'{TMP}/{name}.bin'
    subprocess.run(['pasmo', f'{LIB}/{name}.asm', out], check=True, capture_output=True, cwd=LIB)
    return open(out, 'rb').read()

def sjasm(name, source=None):
    """Assemble with sjasmplus too (pasmo's END directive removed) and return (bytes, symbols)."""
    src = source if source is not None else open(f'{LIB}/{name}.asm').read()
    src = re.sub(r'(?im)^\s*END\b.*$', '', src)
    src = re.sub(r'(?m)^(?=[A-Z]{2,4}\b)', '    ', src)   # pasmo allows unindented instructions; sjasmplus does not
    path = f'{TMP}/{name}_sj.asm'
    open(path, 'w').write(src)
    r = subprocess.run(['sjasmplus', '--nologo', f'-I{LIB}', f'--sym={TMP}/{name}.sym', f'--raw={TMP}/{name}_sj.bin', path],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr
    sym = {}
    for l in open(f'{TMP}/{name}.sym'):
        m = re.match(r'(\w+):\s+EQU\s+0x([0-9A-Fa-f]+)', l)
        if m: sym[m.group(1)] = int(m.group(2), 16)
    return open(f'{TMP}/{name}_sj.bin', 'rb').read(), sym

def routine_image(name, extra=()):
    """For include-only files (no ORG): wrap as   ORG $8000 / RET / INCLUDE ...  Returns (bytes, symbols).
    The wrapper is assembled by pasmo (from a temp file next to lib/, so INCLUDE finds the files) and sjasmplus."""
    incs = ''.join(f'    INCLUDE "{e}.asm"\n' for e in (*extra, name))
    src = f'    ORG 0x8000\n    RET\n{incs}'
    path = f'{LIB}/_wrap_{name}.asm'
    open(path, 'w').write(src)
    try:
        r = subprocess.run(['pasmo', path, f'{TMP}/wrap_{name}.bin'], capture_output=True, text=True, cwd=LIB)
        assert r.returncode == 0, r.stdout + r.stderr
    finally:
        os.remove(path)
    code, sym = sjasm(f'wrap_{name}', src)
    assert code == open(f'{TMP}/wrap_{name}.bin', 'rb').read(), 'pasmo and sjasmplus disagree'
    return code, sym


# ---- the machine --------------------------------------------------------------
KEYROWS = {'1': (0xF7, 0x01), 'caps': (0xFE, 0x01)}      # half-row port high byte, bit to clear

class Spectrum:
    _boot = None                                   # machine state after the ROM's power-on init (done once)

    def __init__(self):
        self.m = z80.Z80Machine()
        self.v = self.m.get_state_view()
        self.key = None
        self.border = []
        self.ear = []
        self.m.set_input_callback(self._in)
        self.m.set_output_callback(self._out)
        if Spectrum._boot is None:
            self.m.set_memory_block(0, ROM)
            self.m.pc = 0
            for _ in range(400):                   # let the ROM finish its power-on init
                self.frame()
            Spectrum._boot = bytes(self.v)
        else:
            self.v[:] = Spectrum._boot
        self.border.clear(); self.ear.clear()

    def frame(self):
        """Run to the end of the 50Hz frame, then raise the ULA interrupt (wakes HALT, scans the keyboard)."""
        self.m.ticks_to_stop = 69888
        ev = self.m.run()
        if ev == 4:                                # ran a whole frame of ticks; this run just closes the frame
            ev = self.m.run()
        if ev & 8:                                 # end of frame (not a breakpoint hit)
            self.m.on_handle_active_int()

    def _in(self, port):
        if (port & 0xFF) == 0xFE and self.key in KEYROWS:
            hi, bit = KEYROWS[self.key]
            if (port >> 8) & 0xFF == hi: return 0xFF & ~bit
        return 0xFF

    def _out(self, port, val):
        if (port & 0xFF) == 0xFE:
            self.border.append(val & 7); self.ear.append(val)

    def rd(self, a): return self.v[44 + a]
    def put(self, a, d): self.m.set_memory_block(a, bytes(d))

    def run(self, code, org=0x8000, max_frames=3000, key_after=None, key=None, **regs):
        m = self.m
        self.put(org, code)
        sp = 0xFF00
        self.put(sp, [RET_ADDR & 255, RET_ADDR >> 8]); m.sp = sp
        for k, val in regs.items(): setattr(m, k, val)
        m.set_breakpoint(RET_ADDR)
        m.iff1 = m.iff2 = True                     # BASIC calls machine code with interrupts enabled
        m.pc = org
        frames = 0
        while m.pc != RET_ADDR:
            if key_after is not None and frames == key_after: self.key = key
            self.frame(); frames += 1
            assert frames <= max_frames, f'program did not return (pc={m.pc:#06x})'
        m.clear_breakpoint(RET_ADDR)
        assert m.sp == sp + 2, f'stack not balanced (sp={m.sp:#06x})'
        return frames

    def open_screen(self):
        self.run(bytes([0x3E, 2, 0xCD, 0x01, 0x16, 0xC9]))   # LD A,2 / CALL CHAN-OPEN / RET

    def text(self, rows=range(22)):
        out = []
        for r in rows:
            line = ''
            for c in range(32):
                g = bytes(self.rd(0x4000 + ((r & 0x18) << 8) + ((r & 7) << 5) + c + (l << 8)) for l in range(8))
                line += FONT.get(g, '?' if any(g) else ' ')
            out.append(line.rstrip())
        while out and not out[-1]: out.pop()
        return out


def run_program(name, **kw):
    s = Spectrum(); s.run(pasmo_bin(name), **kw); return s


RESULTS = []
def test(fn):
    try:
        fn(); RESULTS.append((fn.__name__, True, ''))
    except Exception as e:
        RESULTS.append((fn.__name__, False, f'{type(e).__name__}: {e}'))
    return fn

PROGRAMS = ['first', 'example1', 'variables', 'conditionals', 'bitwise', 'loops', 'counter', 'test',
            'print_a_char', 'print_hello', 'print_at', 'print_block', 'wait_key', 'beep']
ROUTINES = {'debug_output': (), 'divide': (), 'assert_a_equals': ('debug_output',)}


# ---- assembly ---------------------------------------------------------------
@test
def every_file_assembles_with_pasmo_and_sjasmplus():
    files = sorted(f[:-4] for f in os.listdir(LIB) if f.endswith('.asm'))
    assert set(files) == set(PROGRAMS) | set(ROUTINES), set(files) ^ (set(PROGRAMS) | set(ROUTINES))
    for name in PROGRAMS:
        a = pasmo_bin(name)
        b, _ = sjasm(name)
        assert a == b, f'{name}: pasmo and sjasmplus produce different machine code'
        assert 0 < len(a) < 0x7000, name
    for name, extra in ROUTINES.items():
        routine_image(name, extra)

# ---- programs ---------------------------------------------------------------
@test
def first():
    assert run_program('first').text() == ['*']

@test
def example1():
    assert run_program('example1').text() == ['Hello!', '42', '*']

@test
def variables():
    assert run_program('variables').text() == ['my_byte:   42', 'my_string: Hello', 'my_array:  1 2 3 4 5']

@test
def conditionals():
    assert run_program('conditionals').text() == ['a equals 10']
    # the else branch: change var_a and var_b is set accordingly
    code, sym = sjasm('conditionals')
    s = Spectrum(); b = bytearray(code); b[sym['var_a'] - 0x8000] = 7
    s.run(bytes(b))
    assert s.text() == ['a is not 10']
    assert s.rd(sym['var_b']) == 0
    s = Spectrum(); s.run(code)
    assert s.rd(sym['var_b']) == 1

@test
def bitwise():
    s = run_program('bitwise')
    assert s.text() == ['FLASH!']
    paper = s.rd(0x5806)                      # untouched cell = ROM's default attribute
    assert s.rd(0x5800) == paper | 0x40 and not s.rd(0x5800) & 0x80, 'F: bright, flash cleared'
    for i in range(1, 6):
        assert s.rd(0x5800 + i) == paper | 0xC0, f'cell {i}: flash+bright'
    assert s.rd(0x5800) & 0x3F == paper & 0x3F, 'colour bits disturbed'

@test
def loops():
    s = Spectrum(); frames = s.run(pasmo_bin('loops'))
    seq = [b for i, b in enumerate(s.border) if i == 0 or s.border[i - 1] != b]
    assert seq == list(range(8)), seq
    assert 8 * 25 - 5 <= frames <= 8 * 25 + 5, f'about 25 frames per colour expected, got {frames} in total'

@test
def counter():
    t = run_program('counter').text()
    assert t[0] == 'Counting 0 to 20:', t
    numbers = ' '.join(' '.join(l.split()) for l in t[1:-1]).split()   # the number line wraps at 32 columns
    assert numbers == [str(i) for i in range(21)], numbers
    assert t[-1] == 'Verification PASSED', t

@test
def test_program():
    assert run_program('test').text() == ['Debug output test', '42', 'Test PASSED']

@test
def print_a_char():
    assert run_program('print_a_char').text() == ['A']

@test
def print_hello():
    assert run_program('print_hello').text() == ['Hello from Z80!']

@test
def print_at():
    t = run_program('print_at').text()
    assert len(t) == 11 and t[10] == ' ' * 5 + 'X' and not any(t[:10]), t     # row 10, column 5

@test
def print_block():
    assert run_program('print_block').text() == ['Printed with one CALL!']

@test
def wait_key():
    s = Spectrum()
    s.run(pasmo_bin('wait_key'), key_after=10, key='1')
    assert s.text() == ['Press a key: 1'], s.text()

@test
def beep():
    s = Spectrum(); s.run(pasmo_bin('beep'))
    toggles = sum(1 for i in range(1, len(s.ear)) if (s.ear[i] ^ s.ear[i - 1]) & 0x10)
    assert abs(toggles - 2 * 0x40) <= 2, f'DE=0x40 cycles expected -> ~128 speaker edges, got {toggles}'

# ---- snippets quoted in the book's prose ----------------------------------------
_n = [0]
def snippet(src, run=True, **kw):
    """Assemble a code fragment from the book (ORG added, RET appended) and run it."""
    _n[0] += 1
    code, _ = sjasm(f'snip{_n[0]}', f'    ORG 0x8000\n{src}\n    RET\n')
    if not run: return code
    s = Spectrum(); s.run(code, **kw); return s

@test
def book_16bit_add_examples():
    s = snippet("    LD A, 200\n    ADD A, 100\n    LD C, A\n    LD A, 0\n    ADC A, 0\n    LD B, A")
    assert (s.m.b, s.m.c) == (1, 44)
    s = snippet("    LD A, 50\n    ADD A, 30\n    LD C, A\n    LD A, 0\n    ADC A, 0\n    LD B, A")
    assert (s.m.b, s.m.c) == (0, 80)
    s = snippet("    LD HL, 500\n    LD DE, 300\n    LD A, L\n    ADD A, E\n    LD L, A\n    LD A, H\n    ADC A, D\n    LD H, A")
    assert s.m.hl == 800

@test
def book_memory_fill_leaves_attributes_alone():
    s = snippet("    LD HL, 16384\n    LD DE, 16385\n    LD BC, 6143\n    LD (HL), 255\n    LDIR")
    assert all(s.rd(0x4000 + i) == 255 for i in range(6144))
    assert s.rd(0x5800) == 0x38, 'attribute byte must be untouched'

@test
def book_djnz_with_b_zero_runs_256_times():
    s = snippet("    LD B, 0\n    LD DE, 0\nl:  INC DE\n    DJNZ l")
    assert s.m.de == 256
    s = snippet("    LD B, 1\n    LD DE, 0\nl:  INC DE\n    DJNZ l")
    assert s.m.de == 1

@test
def book_memory_operand_forms():
    s = snippet("    LD HL, 0x9000\n    LD (HL), 5\n    DEC (HL)\n    LD A, 4\n    CP (HL)")
    assert s.rd(0x9000) == 4 and s.m.f & 0x40, 'DEC (HL) and CP (HL) exist'
    # an absolute address is not a memory operand for CP: it assembles as CP n (opcode 0xFE), not CP (HL) (0xBE)
    assert snippet("    CP (0x9000)", run=False)[0] == 0xFE

@test
def book_halt_resumes_after_interrupt():
    s = Spectrum(); frames = s.run(snippet("    HALT", run=False))
    assert 1 <= frames <= 3, frames

@test
def book_keyboard_snippet():
    src = "    LD A, 0xFE\n    IN A, (0xFE)\n    AND %00000001"
    assert snippet(src).m.a == 1, 'no key pressed -> 1'
    s = Spectrum(); s.key = 'caps'
    s.run(snippet(src, run=False)); assert s.m.a == 0, 'CAPS SHIFT pressed -> 0'

@test
def book_cls_addresses():
    open2 = [0x3E, 2, 0xCD, 0x01, 0x16]                      # LD A,2 / CALL CHAN-OPEN
    def prog(addr, reopen):
        return bytes(open2 + [0x3E, ord('X'), 0xD7, 0xCD, addr & 255, addr >> 8] + (open2 if reopen else [])
                     + [0x3E, ord('Y'), 0xD7, 0xC9])
    s = Spectrum(); s.run(prog(0x0DAF, False)); assert s.text() == ['Y'], s.text()       # cleared, cursor home
    s = Spectrum(); s.run(prog(0x0D6B, False)); assert s.text(range(24))[23] == 'Y'      # lower screen still selected
    s = Spectrum(); s.run(prog(0x0D6B, True)); assert s.text() == ['Y'], s.text()        # fine after reopening channel 2

# ---- reusable routines -------------------------------------------------------
def call(name, extra, label, setup=None, open_screen=True, **regs):
    """Load the routine file at $8000 and CALL <label> with the given registers."""
    code, sym = routine_image(name, extra)
    s = Spectrum()
    if open_screen: s.open_screen()
    s.put(0x8000, code)
    if setup: setup(s)
    s.run(bytes([0xCD]) + sym[label].to_bytes(2, 'little') + b'\xC9', org=0xF000, **regs)
    return s

@test
def debug_output():
    for v in (0, 1, 9, 10, 42, 99, 100, 199, 200, 255):
        s = call('debug_output', (), 'print_number', a=v)
        assert s.text() == [str(v)], (v, s.text())
    s = call('debug_output', (), 'print_string', setup=lambda s: s.put(0x9000, b'Hi there\x00'), hl=0x9000)
    assert s.text() == ['Hi there']
    s = call('debug_output', (), 'print_string', setup=lambda s: s.put(0x9000, b'\x00'), hl=0x9000)
    assert s.text() == []
    assert call('debug_output', (), 'print_char', a=ord('Z')).text() == ['Z']
    # debug_init opens channel 2, so later RST 0x10 output lands on the main screen
    s = call('debug_output', (), 'debug_init', open_screen=False)
    s.run(bytes([0x3E, ord('Q'), 0xD7, 0xC9]))
    assert s.text() == ['Q']

@test
def divide():
    for a in range(0, 256, 17):
        for b in range(0, 256, 13):
            s = call('divide', (), 'divide', a=a, b=b)
            carry = s.m.f & 1
            if b == 0:
                assert carry == 1, ('divide by zero must set carry', a)
            else:
                assert carry == 0 and s.m.a == a // b, (a, b, s.m.a, carry)
    for a, b in [(255, 1), (255, 255), (0, 5), (1, 2), (200, 3), (100, 100)]:
        s = call('divide', (), 'divide', a=a, b=b)
        assert s.m.a == a // b and not s.m.f & 1, (a, b)

@test
def assert_a_equals():
    assert call('assert_a_equals', ('debug_output',), 'assert_a_equals', a=7, b=7).text() == [], 'passing assert prints nothing'
    assert call('assert_a_equals', ('debug_output',), 'assert_a_equals', a=9, b=7).text() == ['ASSERT FAIL! A = 9']


if __name__ == '__main__':
    only = sys.argv[1:]
    bad = 0
    for name, ok, msg in RESULTS:
        if only and name not in only: continue
        print(('PASS ' if ok else 'FAIL ') + name + ('' if ok else '  -> ' + msg))
        bad += not ok
    print(f'\n{len(RESULTS) - bad}/{len(RESULTS)} passed')
    sys.exit(1 if bad else 0)

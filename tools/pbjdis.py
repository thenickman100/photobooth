"""Minimal Pixel Bender (.pbj) disassembler. Usage: python3 -I pbjdis.py file.pbj"""
import struct, sys

OPS = {
    0x00: 'nop', 0x01: 'add', 0x02: 'sub', 0x03: 'mul', 0x04: 'rcp', 0x05: 'div', 0x06: 'atan2',
    0x07: 'pow', 0x08: 'mod', 0x09: 'min', 0x0A: 'max', 0x0B: 'step', 0x0C: 'sin', 0x0D: 'cos',
    0x0E: 'tan', 0x0F: 'asin', 0x10: 'acos', 0x11: 'atan', 0x12: 'exp', 0x13: 'exp2', 0x14: 'log',
    0x15: 'log2', 0x16: 'sqrt', 0x17: 'rsqrt', 0x18: 'abs', 0x19: 'sign', 0x1A: 'floor', 0x1B: 'ceil',
    0x1C: 'fract', 0x1D: 'mov', 0x1E: 'ftoi', 0x1F: 'itof', 0x20: 'matmatmul', 0x21: 'vecmatmul',
    0x22: 'matvecmul', 0x23: 'normalize', 0x24: 'length', 0x25: 'distance', 0x26: 'dot', 0x27: 'cross',
    0x28: 'eq', 0x29: 'neq', 0x2A: 'lt', 0x2B: 'lte', 0x2C: 'not', 0x2D: 'and', 0x2E: 'or', 0x2F: 'xor',
    0x30: 'sample_nearest', 0x31: 'sample_linear', 0x32: 'load', 0x33: 'select', 0x34: 'if', 0x35: 'else',
    0x36: 'endif', 0x37: 'ftob', 0x38: 'btof', 0x39: 'itob', 0x3A: 'btoi', 0x3B: 'veq', 0x3C: 'vneq',
    0x3D: 'any', 0x3E: 'all', 
}
TYPES = {1: 'float', 2: 'float2', 3: 'float3', 4: 'float4', 5: 'float2x2', 6: 'float3x3', 7: 'float4x4',
         8: 'int', 9: 'int2', 10: 'int3', 11: 'int4', 12: 'string', 13: 'bool', 14: 'bool2', 15: 'bool3', 16: 'bool4'}
CH = 'rgba'


def reg(r):
    return ('i%d' % (r - 0x8000)) if r & 0x8000 else ('f%d' % r)


def dst_str(r, mask):
    m = mask >> 4
    sw = ''.join(CH[i] for i in range(4) if m & (8 >> i))
    return reg(r) + ('.' + sw if sw and sw != 'rgba' else '')


def src_str(v, n):
    r = v & 0xFFFF
    swz = v >> 16
    sw = ''.join(CH[(swz >> (6 - 2 * i)) & 3] for i in range(n))
    return reg(r) + ('.' + sw if sw != 'rgba'[:n] or n < 4 else '')


class R:
    def __init__(s, d): s.d, s.p = d, 0
    def u8(s): v = s.d[s.p]; s.p += 1; return v
    def u16(s): v = struct.unpack_from('<H', s.d, s.p)[0]; s.p += 2; return v
    def u24(s): v = int.from_bytes(s.d[s.p:s.p + 3], 'little'); s.p += 3; return v
    def u32(s): v = struct.unpack_from('<I', s.d, s.p)[0]; s.p += 4; return v
    def f32be(s): v = struct.unpack_from('>f', s.d, s.p)[0]; s.p += 4; return v
    def i32be(s): v = struct.unpack_from('>i', s.d, s.p)[0]; s.p += 4; return v
    def cstr(s):
        e = s.d.index(b'\0', s.p); v = s.d[s.p:e].decode('latin1'); s.p = e + 1; return v


def meta(r):
    t = r.u8(); key = r.cstr()
    if t == 12: val = r.cstr()
    elif 1 <= t <= 4: val = [round(r.f32be(), 6) for _ in range(t)]
    elif 5 <= t <= 7: n = {5: 4, 6: 9, 7: 16}[t]; val = [round(r.f32be(), 6) for _ in range(n)]
    elif 8 <= t <= 11: val = [r.u16() for _ in range(t - 7)]
    else: raise ValueError('meta type %d' % t)
    return key, TYPES.get(t, t), val


def dis(data):
    r = R(data); out = []; ind = 0
    while r.p < len(data):
        op = r.u8()
        if op == 0xA5: out.append('// version %d' % r.u32())
        elif op == 0xA4: n = r.u16(); out.append('kernel %s' % data[r.p:r.p + n].decode()); r.p += n
        elif op == 0xA0: out.append('//   meta %s (%s) = %r' % meta(r))
        elif op == 0xA2: out.append('//     param-meta %s (%s) = %r' % meta(r))
        elif op == 0xA1:
            q = r.u8(); t = r.u8(); rg = r.u16(); m = r.u8(); name = r.cstr()
            sw = ''.join(CH[i] for i in range(4) if m & (8 >> i))
            out.append('param %s %s %s -> %s.%s' % ({1: 'in', 2: 'out'}[q], TYPES.get(t, t), name, reg(rg), sw))
        elif op == 0xA3:
            idx = r.u8(); ch = r.u8(); name = r.cstr()
            out.append('texture t%d %s (channels=%d)' % (idx, name, ch))
        elif op == 0x32:
            d = r.u16(); m = r.u8()
            v = r.i32be() if d & 0x8000 else round(r.f32be(), 7)
            out.append('  ' * ind + '%s = %r' % (dst_str(d, m), v))
        elif op in (0x30, 0x31):
            d = r.u16(); m = r.u8(); s = r.u24(); t = r.u8()
            out.append('  ' * ind + '%s = %s(t%d, %s)' % (dst_str(d, m), OPS[op], t, src_str(s, 2)))
        elif op == 0x34:
            r.u24(); s = r.u24(); r.u8()
            out.append('  ' * ind + 'if (%s) {' % src_str(s, 1)); ind += 1
        elif op == 0x35:
            r.p += 7; out.append('  ' * (ind - 1) + '} else {')
        elif op == 0x36:
            r.p += 7; ind -= 1; out.append('  ' * ind + '}')
        elif op == 0x33:
            # 16 bytes: dst, mask, cond, 0, src1, 0, src2, 0 -> dst = cond ? src1 : src2
            d = r.u16(); m = r.u8(); c = r.u24(); r.u8(); s1 = r.u24(); r.u8(); s2 = r.u24(); r.u8()
            n = (m & 3) + 1
            out.append('  ' * ind + '%s = %s ? %s : %s' % (dst_str(d, m), src_str(c, 1), src_str(s1, n), src_str(s2, n)))
        else:
            d = r.u16(); m = r.u8(); s = r.u24(); pad = r.u8()
            n = (m & 3) + 1
            mat = (m >> 2) & 3
            name = OPS.get(op, 'op%02x' % op)
            extra = ' [matrix %d]' % mat if mat else ''
            out.append('  ' * ind + '%s %s, %s%s' % (name, dst_str(d, m), src_str(s, n), extra))
    return '\n'.join(out)


if __name__ == '__main__':
    print(dis(open(sys.argv[1], 'rb').read()))

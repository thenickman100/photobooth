import re, struct, zlib, sys, os
src, out = sys.argv[1], sys.argv[2]
data = open(src, 'rb').read()
for m in re.finditer(b'CWS', data):
    off = m.start(); ver = data[off+3]; ln = struct.unpack('<I', data[off+4:off+8])[0]
    d = zlib.decompressobj()
    try: body = d.decompress(data[off+8:off+8+ln*2])
    except Exception: continue
    if len(body) + 8 != ln: continue
    used = len(data[off+8:off+8+ln*2]) - len(d.unused_data) + 8
    open(f'{out}/swf_{off}.swf', 'wb').write(data[off:off+used])
    open(f'{out}/swf_{off}_raw.swf', 'wb').write(b'FWS' + bytes([ver]) + struct.pack('<I', ln) + body)
    print(off, ln, used)

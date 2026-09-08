import struct, sys, os
src, dst = sys.argv[1], sys.argv[2]
f = open(src,'rb')
hdr = f.read(28)
magic, major, minor, fhs, chs, blk, tot_blk, tot_chk, csum = struct.unpack('<IHHHHIIII', hdr)
assert magic == 0xed26ff3a, f"magic invalido: {magic:08x}"
print(f"sparse v{major}.{minor} blk={blk} blocos={tot_blk} chunks={tot_chk}")
print(f"tamanho bruto final = {tot_blk*blk} bytes ({tot_blk*blk/1024**3:.2f} GB)")
f.seek(fhs)
out = open(dst,'wb'); written = 0
for i in range(tot_chk):
    ch = f.read(chs)
    ctype, res, csz, tsz = struct.unpack('<HHII', ch)
    data = tsz - chs
    if ctype == 0xCAC1:      # RAW
        n = csz*blk; rem = n
        while rem:
            b = f.read(min(1<<22, rem))
            if not b: raise SystemExit("EOF inesperado")
            out.write(b); rem -= len(b)
        written += n
    elif ctype == 0xCAC2:    # FILL
        fill = f.read(4); n = csz*blk
        out.write(fill * (n//4)); written += n
    elif ctype == 0xCAC3:    # DONT_CARE
        n = csz*blk; out.write(b'\x00'*n); written += n
    elif ctype == 0xCAC4:    # CRC32
        f.read(4)
    else:
        raise SystemExit(f"chunk desconhecido {ctype:04x}")
out.close(); f.close()
print(f"gravado: {written} bytes -> {dst}")
print("confere:", written == tot_blk*blk)

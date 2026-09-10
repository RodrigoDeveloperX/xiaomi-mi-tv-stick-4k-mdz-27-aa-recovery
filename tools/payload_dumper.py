#!/usr/bin/env python3
"""Extrai particoes de um payload.bin de OTA Android (update_engine), direto do .zip.

Sem dependencia externa: traz um parser minimo do formato protobuf, so dos campos
que interessam. Isso evita depender do update_metadata_pb2 gerado pelo AOSP, que
nao esta nesta maquina.

Formato do payload.bin (A/B update_engine):
    "CrAU"                  4 B
    version                 8 B  big-endian
    manifest_size           8 B  big-endian
    metadata_signature_size 4 B  big-endian   (versao >= 2)
    manifest                manifest_size B   (DeltaArchiveManifest)
    metadata_signature      metadata_signature_size B
    dados                   blobs, offsets relativos ao fim do cabecalho

Numa OTA COMPLETA todas as operacoes sao REPLACE / REPLACE_BZ / REPLACE_XZ / ZERO,
ou seja, nao precisam da imagem antiga. Se aparecer qualquer operacao de delta o
script avisa e para, em vez de gravar lixo.
"""
import sys, os, zipfile, struct, bz2, lzma, hashlib, argparse

# ---------- protobuf: parser minimo ----------
def _varint(b, i):
    r = s = 0
    while True:
        x = b[i]; i += 1
        r |= (x & 0x7F) << s
        if not x & 0x80: return r, i
        s += 7

def fields(buf):
    """Devolve (numero_do_campo, valor) — valor e' int (varint/fixos) ou bytes."""
    i, n = 0, len(buf)
    while i < n:
        key, i = _varint(buf, i)
        num, wt = key >> 3, key & 7
        if wt == 0:
            v, i = _varint(buf, i)
        elif wt == 2:
            ln, i = _varint(buf, i); v = buf[i:i+ln]; i += ln
        elif wt == 5:
            v = struct.unpack_from("<I", buf, i)[0]; i += 4
        elif wt == 1:
            v = struct.unpack_from("<Q", buf, i)[0]; i += 8
        else:
            raise ValueError(f"wire type {wt} nao suportado no campo {num}")
        yield num, v

def get(buf, num, many=False):
    out = [v for k, v in fields(buf) if k == num]
    if many: return out
    return out[0] if out else None

# ---------- modelo ----------
TIPOS = {0:"REPLACE", 1:"REPLACE_BZ", 2:"MOVE", 3:"BSDIFF", 4:"SOURCE_COPY",
         5:"SOURCE_BSDIFF", 6:"ZERO", 7:"DISCARD", 8:"REPLACE_XZ",
         9:"PUFFDIFF", 10:"BROTLI_BSDIFF", 11:"ZUCCHINI"}
SEM_ORIGEM = {0, 1, 6, 8}   # operacoes que nao leem a particao antiga

class Op:
    __slots__ = ("tipo","off","tam","dst","hash")
    def __init__(self, raw):
        self.tipo = get(raw, 1) or 0
        self.off  = get(raw, 2) or 0
        self.tam  = get(raw, 3) or 0
        self.hash = get(raw, 8)
        self.dst  = []
        for ext in get(raw, 6, many=True):
            self.dst.append(((get(ext,1) or 0), (get(ext,2) or 0)))

class Part:
    __slots__ = ("nome","ops","tamanho","sha")
    def __init__(self, raw):
        self.nome = (get(raw, 1) or b"").decode()
        self.ops  = [Op(o) for o in get(raw, 8, many=True)]
        info = get(raw, 7)
        self.tamanho = get(info, 1) if info else None
        self.sha     = get(info, 2) if info else None

def offset_no_zip(caminho, alvo="payload.bin"):
    """Offset absoluto dos dados de um membro ARMAZENADO (sem compressao).

    Numa OTA o payload.bin vem com compress_type=0, entao da' para le-lo no
    lugar, com seek no proprio .zip. Evita uma copia de 1 GB em disco -- que
    nesta maquina nao caberia junto com a super montada.
    """
    z = zipfile.ZipFile(caminho)
    info = next((i for i in z.infolist() if i.filename.endswith(alvo)), None)
    if info is None:
        raise SystemExit("ERRO: nao ha %s dentro do zip" % alvo)
    if info.compress_type != 0:
        raise SystemExit("ERRO: %s esta comprimido no zip; nao da' para ler no lugar" % alvo)
    with open(caminho, "rb") as f:          # cabecalho local: nome e extra tem tamanho proprio
        f.seek(info.header_offset)
        cab = f.read(30)
        if cab[:4] != b"PK\x03\x04":
            raise SystemExit("ERRO: cabecalho local do zip invalido")
        n_nome, n_extra = struct.unpack_from("<HH", cab, 26)
    z.close()
    return info.header_offset + 30 + n_nome + n_extra, info.file_size


def abre_payload(caminho):
    """Devolve (arquivo, base_dos_dados, block_size, [Part])."""
    if caminho.lower().endswith(".zip"):
        off, _ = offset_no_zip(caminho)
        fh = open(caminho, "rb")
        fh.seek(off)
    else:
        fh = open(caminho, "rb")
    if fh.read(4) != b"CrAU": raise SystemExit("ERRO: nao e' um payload.bin (falta CrAU)")
    ver = struct.unpack(">Q", fh.read(8))[0]
    man_sz = struct.unpack(">Q", fh.read(8))[0]
    sig_sz = struct.unpack(">I", fh.read(4))[0] if ver >= 2 else 0
    manifest = fh.read(man_sz)
    fh.read(sig_sz)
    base = fh.tell()
    bs = get(manifest, 3) or 4096
    parts = [Part(p) for p in get(manifest, 13, many=True)]
    return fh, base, bs, parts

def extrai(fh, base, bs, p, destino):
    with open(destino, "wb") as out:
        for op in p.ops:
            if op.tipo not in SEM_ORIGEM:
                raise SystemExit(f"ERRO: {p.nome} tem operacao {TIPOS.get(op.tipo,op.tipo)} "
                                 f"(delta). Este payload nao e' uma OTA completa.")
            fh.seek(base + op.off)
            raw = fh.read(op.tam)
            if op.hash and hashlib.sha256(raw).digest() != op.hash:
                raise SystemExit(f"ERRO: sha256 do bloco nao confere em {p.nome}")
            if   op.tipo == 0: dados = raw
            elif op.tipo == 1: dados = bz2.decompress(raw)
            elif op.tipo == 8: dados = lzma.decompress(raw)
            else:              dados = b""      # ZERO
            ini = op.dst[0][0] if op.dst else 0
            total = sum(n for _, n in op.dst) * bs
            out.seek(ini * bs)
            out.write(dados if op.tipo != 6 else b"\0" * total)
        if p.tamanho:
            out.truncate(p.tamanho)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("payload")
    ap.add_argument("-o", "--out", default=".")
    ap.add_argument("-l", "--list", action="store_true")
    ap.add_argument("-p", "--parts", default="")
    a = ap.parse_args()

    fh, base, bs, parts = abre_payload(a.payload)
    print(f"block_size={bs}  particoes={len(parts)}")
    if a.list:
        for p in parts:
            tipos = sorted({TIPOS.get(o.tipo, o.tipo) for o in p.ops})
            delta = "" if all(o.tipo in SEM_ORIGEM for o in p.ops) else "  <-- DELTA"
            print(f"  {p.nome:<16} {p.tamanho or 0:>12} B  ops={len(p.ops):<5} {','.join(tipos)}{delta}")
        return

    alvo = [x for x in a.parts.split(",") if x] or [p.nome for p in parts]
    os.makedirs(a.out, exist_ok=True)
    for p in parts:
        if p.nome not in alvo: continue
        dest = os.path.join(a.out, p.nome + ".img")
        print(f"  extraindo {p.nome} -> {dest}", flush=True)
        extrai(fh, base, bs, p, dest)
        real = os.path.getsize(dest)
        ok = ""
        if p.sha:
            h = hashlib.sha256()
            with open(dest, "rb") as g:
                for ch in iter(lambda: g.read(1 << 20), b""): h.update(ch)
            ok = "  sha256 OK" if h.digest() == p.sha else "  sha256 DIVERGE"
        print(f"    {real} bytes{ok}", flush=True)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Monta uma super.img a partir das particoes logicas - o equivalente ao lpmake.

Por que escrever isto: o liblp do PyPI implementa so' a LEITURA. WriteToImageFile,
FlashPartitionTable e UpdatePartitionTable sao NotImplementedError. Mas o leitor
e' completo e as estruturas ctypes descrevem o formato inteiro, entao da' para
serializar usando as mesmas structs e conferir o resultado relendo com o proprio
leitor do liblp. E' isso que o --conferir faz no fim.

O molde (tamanho da super, alinhamento, nome do grupo, versao do cabecalho) e'
copiado de uma super real deste mesmo aparelho, para nao inventar valores.

Layout da super (constantes do liblp):
    0      .. 4096     reservado
    4096   .. 8192     geometry primaria
    8192   .. 12288    geometry backup
    12288  + 65536*n   metadata primaria, um por slot
    ...    + 65536*n   metadata backup, um por slot
    first_logical_sector*512  inicio dos dados das particoes
Os checksums sao SHA256, nao CRC.
"""
import os
import sys
import argparse
import ctypes
from hashlib import sha256

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "pylib"))
from liblp import reader
from liblp.include.metadata_format import (
    LpMetadataGeometry, LpMetadataHeader,
    LpMetadataPartition, LpMetadataExtent, LpMetadataPartitionGroup,
    LpMetadataBlockDevice,
    LP_METADATA_GEOMETRY_MAGIC, LP_METADATA_GEOMETRY_SIZE, LP_METADATA_HEADER_MAGIC,
    LP_PARTITION_RESERVED_BYTES, LP_PARTITION_ATTR_READONLY,
    LP_TARGET_TYPE_LINEAR,
)

# Ordem de colocacao dentro da super. As cinco primeiras sao as da 1440, na
# mesma ordem da imagem de fabrica; as tres *_dlkm so' existem no Android 14.
ORDEM = ["system", "vendor", "product", "odm", "system_ext",
         "system_dlkm", "vendor_dlkm", "odm_dlkm"]


def u8arr(b):
    a = (ctypes.c_uint8 * 32)()
    ctypes.memmove(a, b, 32)
    return a


def copia(destino_cls, origem):
    novo = destino_cls()
    ctypes.memmove(ctypes.byref(novo), ctypes.byref(origem), ctypes.sizeof(novo))
    return novo


def le_molde(caminho):
    with open(caminho, "rb") as fd:
        g = reader.ReadPrimaryGeometry(fd)
        m = reader.ReadPrimaryMetadata(fd, g, 0)
    if m is None:
        raise SystemExit("ERRO: nao consegui ler a metadata de " + caminho)
    return g, m


def monta(molde, imagens, destino, grupo_nome=None):
    g_src, m_src = molde
    bd_src = m_src.block_devices[0]
    super_size = bd_src.size
    bloco = g_src.logical_block_size
    inicio = bd_src.first_logical_sector * 512

    geo = LpMetadataGeometry()
    geo.magic = LP_METADATA_GEOMETRY_MAGIC
    geo.struct_size = ctypes.sizeof(LpMetadataGeometry)
    geo.checksum = u8arr(b"\x00" * 32)
    geo.metadata_max_size = g_src.metadata_max_size
    geo.metadata_slot_count = g_src.metadata_slot_count
    geo.logical_block_size = bloco
    geo.checksum = u8arr(sha256(bytes(geo)).digest())

    grupos = [copia(LpMetadataPartitionGroup, gr) for gr in m_src.groups]
    if grupo_nome:
        grupos[1].name = grupo_nome.encode()

    # Os extents sao alinhados ao 'alignment' do block device (1 MB neste
    # aparelho), nao ao logical_block_size. Confirmado refazendo a aritmetica
    # dos quatro extents da super 1440: 1411072, 1642496, 3024896 e 3043328
    # sao exatamente os proximos multiplos de 2048 setores.
    al_set = max(1, bd_src.alignment // 512)

    parts, extents = [], []
    setor = bd_src.first_logical_sector
    usado = 0
    for nome, caminho in imagens:
        tam = os.path.getsize(caminho)
        if tam % bloco:
            tam += bloco - (tam % bloco)
        setores = tam // 512
        if setor % al_set:
            setor += al_set - (setor % al_set)
        ext = LpMetadataExtent()
        ext.num_sectors = setores
        ext.target_type = LP_TARGET_TYPE_LINEAR
        ext.target_data = setor
        ext.target_source = 0
        p = LpMetadataPartition()
        p.name = nome.encode()
        p.attributes = LP_PARTITION_ATTR_READONLY
        p.first_extent_index = len(extents)
        p.num_extents = 1
        p.group_index = 1
        extents.append(ext)
        parts.append(p)
        setor += setores
        usado += tam
    fim = setor * 512

    if fim > super_size:
        raise SystemExit(
            "ERRO: com alinhamento as particoes terminam em %d B e nao cabem "
            "em %d B (dados uteis %d, inicio %d)."
            % (fim, super_size, usado, inicio))
    if usado > grupos[1].maximum_size:
        raise SystemExit("ERRO: %d B excede o maximo do grupo (%d B)."
                         % (usado, grupos[1].maximum_size))

    bds = [copia(LpMetadataBlockDevice, bd_src)]

    def tab(lista):
        return b"".join(bytes(x) for x in lista)

    def serializa(sufixo):
        """Uma metadata completa, com os nomes no sufixo de slot pedido.

        As duas variantes apontam para os MESMOS extents -- e' assim que a super
        de fabrica deixa os dois slots utilizaveis com uma copia so' dos dados.
        """
        ps = []
        for p_src in parts:
            p = copia(LpMetadataPartition, p_src)
            p.name = (p_src.name.decode().rsplit("_", 1)[0] + sufixo).encode()
            ps.append(p)
        gs = [copia(LpMetadataPartitionGroup, x) for x in grupos]
        gs[1].name = (grupos[1].name.decode().rsplit("_", 1)[0] + sufixo).encode()

        tabelas = tab(ps) + tab(extents) + tab(gs) + tab(bds)
        h = LpMetadataHeader()
        h.magic = LP_METADATA_HEADER_MAGIC
        h.major_version = m_src.header.major_version
        h.minor_version = m_src.header.minor_version
        h.header_size = m_src.header.header_size
        h.header_checksum = u8arr(b"\x00" * 32)
        h.tables_size = len(tabelas)
        h.tables_checksum = u8arr(sha256(tabelas).digest())
        off = 0
        for desc, lista, cls in ((h.partitions, ps, LpMetadataPartition),
                                 (h.extents, extents, LpMetadataExtent),
                                 (h.groups, gs, LpMetadataPartitionGroup),
                                 (h.block_devices, bds, LpMetadataBlockDevice)):
            desc.offset = off
            desc.num_entries = len(lista)
            desc.entry_size = ctypes.sizeof(cls)
            off += len(lista) * ctypes.sizeof(cls)
        h.flags = m_src.header.flags
        h.header_checksum = u8arr(sha256(bytes(h)[:h.header_size]).digest())
        blob = bytes(h)[:h.header_size] + tabelas
        if len(blob) > geo.metadata_max_size:
            raise SystemExit("ERRO: metadata maior que metadata_max_size")
        return blob

    md = {"_a": serializa("_a"), "_b": serializa("_b")}

    n_slots = geo.metadata_slot_count
    mms = geo.metadata_max_size
    with open(destino, "wb") as out:
        out.truncate(super_size)
        out.seek(LP_PARTITION_RESERVED_BYTES)
        out.write(bytes(geo))
        out.seek(LP_PARTITION_RESERVED_BYTES + LP_METADATA_GEOMETRY_SIZE)
        out.write(bytes(geo))
        # As seis areas de metadata alternam _a e _b em ordem de arquivo. Isso
        # nao segue a convencao do liblp (backup do slot N espelharia o primario
        # do slot N), mas e' exatamente o que a super de fabrica deste aparelho
        # faz -- conferido lendo os seis offsets. Reproduzo o de fabrica.
        base_p = LP_PARTITION_RESERVED_BYTES + LP_METADATA_GEOMETRY_SIZE * 2
        base_b = base_p + mms * n_slots
        areas = ([base_p + mms * s for s in range(n_slots)] +
                 [base_b + mms * s for s in range(n_slots)])
        for i, off_area in enumerate(sorted(areas)):
            out.seek(off_area)
            out.write(md["_a" if i % 2 == 0 else "_b"])
        for (nome, caminho), ext in zip(imagens, extents):
            out.seek(ext.target_data * 512)
            with open(caminho, "rb") as src:
                for ch in iter(lambda: src.read(1 << 22), b""):
                    out.write(ch)
        out.truncate(super_size)
    return usado, super_size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--molde", required=True, help="super.img existente, usada como referencia")
    ap.add_argument("--dir", required=True, help="pasta com as .img das particoes logicas")
    ap.add_argument("--saida", required=True)
    ap.add_argument("--sufixo", default="_a", help="sufixo de slot nos nomes (padrao _a)")
    ap.add_argument("--grupo", default=None)
    ap.add_argument("--conferir", action="store_true", help="rele a saida com o liblp")
    a = ap.parse_args()

    molde = le_molde(a.molde)
    imagens = []
    for nome in ORDEM:
        for cand in (nome + ".img", nome + a.sufixo + ".img"):
            p = os.path.join(a.dir, cand)
            if os.path.exists(p):
                imagens.append((nome + a.sufixo, p))
                break
    if not imagens:
        raise SystemExit("ERRO: nenhuma imagem logica encontrada em " + a.dir)

    print("particoes a incluir:")
    for n, p in imagens:
        print("  %-16s %12d B   %s" % (n, os.path.getsize(p), os.path.basename(p)))

    usado, total = monta(molde, imagens, a.saida, a.grupo)
    print("\nescrito: %s  (%d bytes)" % (a.saida, os.path.getsize(a.saida)))
    print("dados: %d B de %d B" % (usado, total))

    if a.conferir:
        print("\n--- relendo com o liblp ---")
        with open(a.saida, "rb") as fd:
            g = reader.ReadPrimaryGeometry(fd)
            m = reader.ReadPrimaryMetadata(fd, g, 0)
        if m is None:
            raise SystemExit("FALHOU: o liblp nao releu a metadata que eu escrevi")
        for p in m.partitions:
            tam = sum(m.extents[p.first_extent_index + i].num_sectors * 512
                      for i in range(p.num_extents))
            print("  %-16s %12d B  grupo=%s"
                  % (reader.GetPartitionName(p), tam,
                     reader.GetPartitionGroupName(m.groups[p.group_index])))
        print("OK: geometry, header e tabelas conferem (SHA256 validado pelo leitor).")


if __name__ == "__main__":
    main()

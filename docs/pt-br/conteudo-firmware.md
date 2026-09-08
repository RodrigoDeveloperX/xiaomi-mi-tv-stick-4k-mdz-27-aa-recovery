# O que existe de fato dentro do `mi-tv-stick-4k_dnl_1440_01.7z`

🇺🇸 [English version](../firmware-contents.md) · 📖 [README em português](../../README-PT-BR.md)

Tudo nesta página foi lido do próprio arquivo. Nada aqui foi copiado de post de fórum. Isto existe para que alguém que encontre uma cópia desse arquivo em algum lugar consiga dizer se é a certa, e para que as afirmações do README possam ser conferidas em vez de apenas acreditadas.

---

## O pacote

| | |
|---|---|
| Nome | `mi-tv-stick-4k_dnl_1440_01.7z` |
| Tamanho | 685.065.929 bytes |
| SHA-256 | `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b` |
| MD5 | `ffb220dd62cbff01f6e39461cd0154d1` |
| Compressão | LZMA2 |
| Entradas | 13 arquivos, 3 diretórios |
| Descompactado | 1.797.634.555 bytes |

```
mi-tv-stick-4k_dnl_1440_01/
├── go.cmd
├── bin/
│   ├── adnl.exe
│   ├── AdbWinApi.dll
│   ├── AdbWinUsbApi.dll
│   └── libwinpthread-1.dll
└── images/
    ├── boot.img
    ├── dtbo.img
    ├── odm_ext.img
    ├── oem.img
    ├── super-ab-1440-sparse.img
    ├── vbmeta.img
    ├── vbmeta_system.img
    └── vendor_boot.img
```

Os arquivos de `images/` estão datados entre 26/01/2024 e 29/01/2024 no pacote; o `adnl.exe` está datado de 20/08/2021, coincidindo com a versão que ele mesmo imprime ao rodar.

---

## Identidade do build

Lida de strings no estilo `build.prop` dentro do `oem.img` e dentro da imagem `super`:

```
ro.build.id                        = RTT0.211222.001
ro.build.display.id                = RTT0.211222.001.1440 release-keys
ro.build.version.incremental       = 1440
ro.build.version.release           = 11
ro.build.version.security_patch    = 2023-10-05
ro.build.date                      = Fri Nov 24 10:24:43 CST 2023
ro.board.platform                  = s4
ro.com.google.clientidbase         = android-xiaomi-tv
ro.com.google.gmsversion           = Android_R
```

**O `release-keys` é a parte importante.** Significa que este build foi assinado com as chaves oficiais de release da Xiaomi — é firmware stock, não uma build modificada pela comunidade. É por isso que um reset de fábrica se comporta normalmente nela, ao contrário da build modificada `1469_MOD_9` discutida no README.

O `1440` do nome do arquivo é o `ro.build.version.incremental`. A string completa de build que as pessoas procuram, `RTT0.211222.001.1440`, é o `ro.build.display.id` menos o sufixo `release-keys`.

Note a diferença entre a data codificada no build ID (`211222` → 22/12/2021, o ramo da plataforma) e a data real do build (24/11/2023), com patch de segurança de outubro de 2023. Isso é normal: o build ID nomeia o ramo de release da plataforma, não o dia em que a imagem foi compilada.

---

## Identidade do aparelho

O mesmo conjunto de propriedades aparece sob todos os prefixos de partição (`system`, `vendor`, `odm`, `product`, `system_ext`), que é como o Android 11 registra isso:

```
ro.product.brand         = Xiaomi
ro.product.device        = soul
ro.product.name          = soul
ro.product.model         = MiTV-AYFR0
ro.product.manufacturer  = Xiaomi
```

| Campo | Valor |
|---|---|
| Nome comercial | Xiaomi Mi TV Stick 4K |
| Número do modelo na caixa | MDZ-27-AA |
| Codinome interno | **`soul`** |
| String de modelo interna | **`MiTV-AYFR0`** |
| Plataforma | **`s4`** (família Amlogic S4) |

O `MiTV-AYFR0` também é o nome que o `go.cmd` original mostra no título da janela, o que é uma confirmação independente e útil de que o script e as imagens pertencem ao mesmo pacote.

> O SoC é comumente reportado como **Amlogic S905Y4**. A firmware em si comprova apenas a família de plataforma (`s4`); o número específico da peça vem de especificações públicas e não é verificável a partir destes arquivos.

---

## Imagens de partição

| Imagem | Tamanho | Formato | Gravada em |
|---|---:|---|---|
| `boot.img` | 67.108.864 | Android boot image (`ANDROID!`) | `boot_a`, `boot_b` |
| `vendor_boot.img` | 25.165.824 | Vendor boot v3 (`VNDRBOOT`) | `vendor_boot_a`, `vendor_boot_b` |
| `dtbo.img` | 2.097.152 | Tabela DTBO (magic `d7b7ab1e`) | `dtbo_a`, `dtbo_b` |
| `vbmeta.img` | 8.192 | AVB vbmeta v1.0 (`AVB0`) | `vbmeta_a`, `vbmeta_b` |
| `vbmeta_system.img` | 4.096 | AVB vbmeta v1.0 (`AVB0`) | `vbmeta_system_a`, `vbmeta_system_b` |
| `oem.img` | 33.554.432 | imagem de sistema de arquivos | `oem_a`, `oem_b` |
| `odm_ext.img` | 16.777.216 | imagem de sistema de arquivos | `odm_ext_a`, `odm_ext_b` |
| `super-ab-1440-sparse.img` | 1.650.178.104 | Android sparse | `super` |

A presença de imagens vbmeta `AVB0` confirma que o Android Verified Boot está em uso, coerente com uma build stock assinada e bootloader travado.

Todas as imagens, exceto o `super`, são gravadas nos **dois** slots `_a` e `_b` — este é um aparelho A/B (atualização sem emenda), e preencher os dois slots é o que o `go.cmd` original faz.

---

## A imagem `super`

O `super-ab-1440-sparse.img` é uma **imagem Android sparse**, não bruta. Convertê-la (veja [`tools/simg2img.ps1`](../../tools/simg2img.ps1)) resulta em:

```
sparse v1.0
tamanho do bloco    4.096 bytes
total de blocos     460.800
total de chunks     148
tamanho bruto       1.887.436.800 bytes  (1,76 GiB)
```

`1.650.178.104 → 1.887.436.800 bytes`.

A imagem bruta é um **contêiner de partições dinâmicas** do Android. A metadata LP dela informa:

```
magic da geometry     0x616C4467
tamanho máx metadata  65.536 bytes
slots de metadata     3
bloco lógico          4.096
magic do header       0x414C5030
versão do header      10.2
partições             5
extents               5
grupos                2
```

Partições lógicas dentro dela:

| Partição lógica | Tamanho | |
|---|---:|---|
| `system_a` | 721.403.904 bytes | 688,0 MiB |
| `vendor_a` | 118.063.104 bytes | 112,6 MiB |
| `product_a` | 707.317.760 bytes | 674,6 MiB |
| `odm_a` | 8.695.808 bytes | 8,3 MiB |
| `system_ext_a` | 100.495.360 bytes | 95,8 MiB |

Somente partições lógicas `_a` são declaradas. Num aparelho A/B, a partição física `super` é compartilhada entre os slots e a metadata é reescrita conforme os slots são preenchidos, então isso é o que se espera de uma imagem construída para o slot A — e o aparelho de fato dá boot depois de ser gravado assim.

> **Não** testamos o que acontece depois de uma troca de slot posterior, então "só `_a` é declarado e funciona" é uma observação sobre o nosso aparelho depois desta gravação, não uma afirmação geral sobre o comportamento A/B neste hardware.

---

## `bin/`

| Arquivo | Tamanho | Observações |
|---|---:|---|
| `adnl.exe` | 2.436.809 | Ferramenta USB DNL da Amlogic. Imprime `Amlogic USB DNL tool: V[2.6.3] at Aug 20 2021`. Sem assinatura. |
| `AdbWinApi.dll` | 97.792 | Recurso de versão: Android SDK 2.0.0.0, "Google, inc". Sem assinatura. |
| `AdbWinUsbApi.dll` | 62.976 | Recurso de versão: Android SDK 2.0.0.1, "Google, inc". Sem assinatura. |
| `libwinpthread-1.dll` | 141.538 | Runtime do MinGW-w64. Sem assinatura. |

As duas DLLs `AdbWin*` explicam o comportamento por trás do [obstáculo 2](../../README-PT-BR.md#obstáculo-2--o-guid-de-interface-incompatível): o `adnl.exe` reaproveita a camada USB do ADB do Google e, junto com ela, o GUID de interface do ADB `{F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}`, que é por onde ele enumera. O Zadig registra um GUID aleatório no lugar, então os dois nunca se encontram até você acrescentar o GUID do ADB manualmente.

Nenhum desses binários é redistribuído por este repositório. Os hashes deles estão em [`CHECKSUMS.md`](CHECKSUMS.md).

---

## Como isso foi determinado

Para quem quiser reproduzir em vez de acreditar na nossa palavra, no Windows puro:

**Hashes e tamanhos** — `Get-FileHash`, `certutil -hashfile`, `(Get-Item x).Length`.

**Listagem do pacote** — 7-Zip: botão direito → *7-Zip* → *Abrir arquivo*, ou `7z l mi-tv-stick-4k_dnl_1440_01.7z` a partir da pasta de instalação do 7-Zip.

**Propriedades de build** — as strings `ro.*` são ASCII puro dentro das imagens. O `findstr` as encontra:

```cmd
findstr /C:"ro.build.display.id" images\oem.img
```

**Cabeçalho sparse e metadata LP** — lidos com o script de conversão em [`tools/`](../../tools/), que imprime a geometria sparse enquanto roda. Os números da metadata LP acima foram interpretados diretamente das estruturas em disco da imagem bruta (geometry no offset 4096, header de metadata em 12288), seguindo o layout do `liblp` do AOSP.

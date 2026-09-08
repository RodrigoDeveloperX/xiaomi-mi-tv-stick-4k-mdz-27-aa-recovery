# Hashes de verificação

🇺🇸 [English version](../CHECKSUMS.md) · 📖 [README em português](../../README-PT-BR.md)

Todos os valores desta página foram calculados sobre os arquivos reais usados na recuperação bem-sucedida de um Xiaomi Mi TV Stick 4K (MDZ-27-AA) em 08/09/2026.

Confira pelo menos o arquivo compactado antes de gravar qualquer coisa. Um download truncado gravado num aparelho que já não dá boot é como um stick recuperável vira um irrecuperável.

---

## O arquivo de firmware

```
mi-tv-stick-4k_dnl_1440_01.7z
```

| | |
|---|---|
| **Tamanho** | **685.065.929 bytes** |
| **SHA-256** | `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b` |
| **MD5** | `ffb220dd62cbff01f6e39461cd0154d1` |
| Compressão | LZMA2 |
| Entradas | 13 arquivos + 3 diretórios |
| Total descompactado | 1.797.634.555 bytes |

### Como conferir no Windows

PowerShell:

```powershell
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm SHA256
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm MD5
(Get-Item .\mi-tv-stick-4k_dnl_1440_01.7z).Length
```

Prompt de Comando:

```cmd
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z SHA256
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z MD5
```

Maiúsculas e minúsculas não importam. Se qualquer um dos hashes for diferente, descarte o arquivo e baixe de novo, de outra fonte.

---

## Arquivos dentro do pacote

Os caminhos são relativos a `mi-tv-stick-4k_dnl_1440_01/` dentro do `.7z`. As datas são as registradas no próprio arquivo compactado.

### `images/`

| Arquivo | Tamanho (bytes) | Data no pacote |
|---|---:|---|
| `boot.img` | 67.108.864 | 26/01/2024 14:48 |
| `dtbo.img` | 2.097.152 | 26/01/2024 14:45 |
| `odm_ext.img` | 16.777.216 | 26/01/2024 14:45 |
| `oem.img` | 33.554.432 | 26/01/2024 14:45 |
| `super-ab-1440-sparse.img` | 1.650.178.104 | 29/01/2024 11:58 |
| `vbmeta.img` | 8.192 | 26/01/2024 14:48 |
| `vbmeta_system.img` | 4.096 | 26/01/2024 14:45 |
| `vendor_boot.img` | 25.165.824 | 26/01/2024 14:46 |

**SHA-256**

```
6cab51c42cf2507beb85f1ebf5bddda1bfbfb6871a63d1d6d4e671425a33f4e4  boot.img
78f1503dd8c439a98d035adfd50c2430b1fb604b7cb89c5fe4794d4d60558b00  dtbo.img
f06585e60e22a72b29bc518c005303a2644e7f907e8831aba7e6f803a826446d  odm_ext.img
858710550fc6a404b0247390962b8e8e8301cee1ee764ddbc564b50e667636a4  oem.img
6b8ecc5e5d355e4bc992a763598d1c94f82294bc068621004d3c204572f91fe0  super-ab-1440-sparse.img
084c2a5867ccd887a8ba22162000cc7f3ca8039a097e1b512676e3539f7bd0a6  vbmeta.img
3f49416f6664d37bc318e305f6dfb989afd8dd9420e473bbed38c32562e7b6c1  vbmeta_system.img
86d2fbd010772cd28b81f0c3680cd01b28aa0e0ed19e22637fb2adb639046d33  vendor_boot.img
```

**MD5**

```
4ca8a5256fddcb117dcc1bf13c98f14e  boot.img
0f6ec884a516f36231e7890eafec1119  dtbo.img
04bd6799f5985e9b19d42a104948c231  odm_ext.img
2a20523dd85a3a519d463e91ca854aa9  oem.img
d0b80c650a6c0ee5642b550169ac53be  super-ab-1440-sparse.img
47e3e0c79c2809e7d65efb5d5eadade8  vbmeta.img
e37356c6a92404234a7615bed704c35d  vbmeta_system.img
9e5b8467f91a7c1a9153058ef9a2be0d  vendor_boot.img
```

### `bin/`

| Arquivo | Tamanho (bytes) | Data no pacote | Assinado? |
|---|---:|---|---|
| `adnl.exe` | 2.436.809 | 20/08/2021 14:30 | **Não** |
| `AdbWinApi.dll` | 97.792 | 06/03/2018 16:56 | **Não** (recurso de versão: Android SDK 2.0.0.0, Google inc) |
| `AdbWinUsbApi.dll` | 62.976 | 06/03/2018 16:56 | **Não** (recurso de versão: Android SDK 2.0.0.1, Google inc) |
| `libwinpthread-1.dll` | 141.538 | 13/05/2017 00:25 | **Não** (recurso de versão: projeto MinGW-W64) |

**SHA-256**

```
74eff82e8b8f9ef8bd21e9a553e657d215562013432532b0e1322dd624a7dc50  adnl.exe
d60103a5e99bc9888f786ee916f5d6e45493c3247972cb053833803de7e95cf9  AdbWinApi.dll
25207c506d29c4e8dceb61b4bd50e8669ba26012988a43fbf26a890b1e60fc97  AdbWinUsbApi.dll
83d6e9cb6151c9ecdb330ed9ccda7cab7f27e5f1585d494954526a17ff69d02e  libwinpthread-1.dll
```

**MD5**

```
d0f476d2b4a85b83619fc97749bd21e9  adnl.exe
ed5a809dc0024d83cbab4fb9933d598d  AdbWinApi.dll
0e24119daf1909e398fa1850b6112077  AdbWinUsbApi.dll
27b901bb44c6e3417baeee03c9cdc4bf  libwinpthread-1.dll
```

> ⚠️ **Nenhum desses quatro binários tem assinatura digital**, e não conseguimos rastrear o `adnl.exe` até uma página oficial de distribuição da Amlogic. O próprio banner dele reporta `Amlogic USB DNL tool: V[2.6.3] at Aug 20 2021`. Registramos os hashes para que você possa confirmar que sua cópia é a mesma que foi usada com sucesso — isso é uma verificação de consistência, não uma garantia de segurança. Passe um antivírus se isso importar para você, e note que este repositório **não** redistribui esses arquivos.

### Raiz

| Arquivo | Tamanho (bytes) | Data no pacote |
|---|---:|---|
| `go.cmd` | 1.560 | 29/01/2024 06:33 |

```
SHA-256  b278b7e19a4439247bfed5dc8d46e7147fb74e51b6af92cef44c4e2dba817e41
MD5      c294f2f6b3681a52e258490f47a000c1
```

Arquivo de texto, codificado em CP866 (OEM russo). Transcrição e tradução: [`go.cmd-original.md`](go.cmd-original.md).

---

## Arquivo derivado — `super-raw.img`

Não faz parte do pacote. É o que o [`tools/simg2img.ps1`](../../tools/simg2img.ps1) produz a partir do `super-ab-1440-sparse.img`, e é o que foi realmente gravado no aparelho.

| | |
|---|---|
| **Tamanho** | **1.887.436.800 bytes** (1,76 GiB) |
| **SHA-256** | `a514a082631d42e6fae69dd0c4325eb69ee2054f7cebf832b77bb163390913a2` |
| **MD5** | `fb87a296fa2673635276ae3d750c0db0` |

Se a sua conversão produzir exatamente esses hashes, ela é byte a byte a mesma imagem que funcionou aqui.

A conversão é determinística, então deve bater — mas só se o seu `super-ab-1440-sparse.img` for o mesmo, que é por isso que vale conferir antes o hash da própria imagem sparse, logo acima.

---

## Ferramentas de terceiros referenciadas (não redistribuídas)

### Zadig 2.9

| | |
|---|---|
| Tamanho da cópia usada | 5.334.088 bytes |
| SHA-256 | `4ecaa95df3da3621486a043aef8b3050b8bafe7c901402871e816229ef82039b` |
| Assinatura digital | **Válida** — `CN=Akeo Consulting, O=Akeo Consulting, C=IE` |
| Versão do arquivo | 2.9.788 |
| Fonte oficial | <https://github.com/pbatard/libwdi/releases> |

**Aqui, prefira a assinatura ao hash.** Baixe o Zadig da página oficial de releases e depois clique com o botão direito → *Propriedades* → *Assinaturas Digitais*, confirmando que está assinado pela Akeo Consulting com assinatura válida. Essa verificação é mais forte do que bater um hash publicado por um desconhecido — inclusive nós.

---

## Scripts deste repositório

Os scripts em [`tools/`](../../tools/) são texto puro, escritos para este repositório e curtos o bastante para serem lidos por inteiro antes de rodar. Eles são cobertos pelo histórico do Git em vez de por hashes aqui — leia-os, são os únicos arquivos que pedimos que você execute.

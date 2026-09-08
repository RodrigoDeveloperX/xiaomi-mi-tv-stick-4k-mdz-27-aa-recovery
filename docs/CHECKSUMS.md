# Checksums

Every value here was computed on the actual files used in the successful recovery of a Xiaomi Mi TV Stick 4K (MDZ-27-AA) on 2026-09-08.

Verify at least the archive before you flash anything. A truncated download written to a device that already will not boot is how a recoverable stick becomes an unrecoverable one.

---

## The firmware archive

```
mi-tv-stick-4k_dnl_1440_01.7z
```

| | |
|---|---|
| **Size** | **685,065,929 bytes** |
| **SHA-256** | `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b` |
| **MD5** | `ffb220dd62cbff01f6e39461cd0154d1` |
| Compression | LZMA2 |
| Entries | 13 files + 3 directories |
| Uncompressed total | 1,797,634,555 bytes |

### How to check it on Windows

PowerShell:

```powershell
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm SHA256
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm MD5
(Get-Item .\mi-tv-stick-4k_dnl_1440_01.7z).Length
```

Command Prompt:

```cmd
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z SHA256
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z MD5
```

Case does not matter. If either hash differs, discard the file and download it again from a different source.

---

## Files inside the archive

Paths are relative to `mi-tv-stick-4k_dnl_1440_01/` inside the `.7z`. Timestamps are as recorded in the archive.

### `images/`

| File | Size (bytes) | Archive date |
|---|---:|---|
| `boot.img` | 67,108,864 | 2024-01-26 14:48 |
| `dtbo.img` | 2,097,152 | 2024-01-26 14:45 |
| `odm_ext.img` | 16,777,216 | 2024-01-26 14:45 |
| `oem.img` | 33,554,432 | 2024-01-26 14:45 |
| `super-ab-1440-sparse.img` | 1,650,178,104 | 2024-01-29 11:58 |
| `vbmeta.img` | 8,192 | 2024-01-26 14:48 |
| `vbmeta_system.img` | 4,096 | 2024-01-26 14:45 |
| `vendor_boot.img` | 25,165,824 | 2024-01-26 14:46 |

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

| File | Size (bytes) | Archive date | Signed? |
|---|---:|---|---|
| `adnl.exe` | 2,436,809 | 2021-08-20 14:30 | **No** |
| `AdbWinApi.dll` | 97,792 | 2018-03-06 16:56 | **No** (version resource: Android SDK 2.0.0.0, Google inc) |
| `AdbWinUsbApi.dll` | 62,976 | 2018-03-06 16:56 | **No** (version resource: Android SDK 2.0.0.1, Google inc) |
| `libwinpthread-1.dll` | 141,538 | 2017-05-13 00:25 | **No** (version resource: MinGW-W64 project) |

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

> ⚠️ **None of these four binaries carries a digital signature**, and we could not trace `adnl.exe` to an official Amlogic distribution page. Its own banner reports `Amlogic USB DNL tool: V[2.6.3] at Aug 20 2021`. We record the hashes so you can confirm your copy is the same one that was used successfully — that is a consistency check, not a safety guarantee. Scan them yourself if that matters to you, and note that this repository does **not** redistribute them.

### Root

| File | Size (bytes) | Archive date |
|---|---:|---|
| `go.cmd` | 1,560 | 2024-01-29 06:33 |

```
SHA-256  b278b7e19a4439247bfed5dc8d46e7147fb74e51b6af92cef44c4e2dba817e41
MD5      c294f2f6b3681a52e258490f47a000c1
```

Text file, CP866 (Russian OEM) encoded. Transcription and translation: [`original-go.cmd.md`](original-go.cmd.md).

---

## Derived file — `super-raw.img`

Not part of the archive. This is what [`tools/simg2img.ps1`](../tools/simg2img.ps1) produces from `super-ab-1440-sparse.img`, and it is what was actually written to the device.

| | |
|---|---|
| **Size** | **1,887,436,800 bytes** (1.76 GiB) |
| **SHA-256** | `a514a082631d42e6fae69dd0c4325eb69ee2054f7cebf832b77bb163390913a2` |
| **MD5** | `fb87a296fa2673635276ae3d750c0db0` |

If your conversion produces these exact hashes, it is byte-for-byte the image that worked here.

The conversion is deterministic, so it should match — but only if your `super-ab-1440-sparse.img` is the same one, which is why the sparse image's own hash above is worth checking first.

---

## Third-party tools referenced (not redistributed)

### Zadig 2.9

| | |
|---|---|
| Size of the copy used | 5,334,088 bytes |
| SHA-256 | `4ecaa95df3da3621486a043aef8b3050b8bafe7c901402871e816229ef82039b` |
| Digital signature | **Valid** — `CN=Akeo Consulting, O=Akeo Consulting, C=IE` |
| File version | 2.9.788 |
| Official source | <https://github.com/pbatard/libwdi/releases> |

**Prefer the signature over the hash here.** Download Zadig from the official release page, then right-click → *Properties* → *Digital Signatures* and confirm it is signed by Akeo Consulting with a valid signature. That verification is stronger than matching a hash published by a stranger — including us.

---

## Repository scripts

The scripts in [`tools/`](../tools/) are plain text, written for this repository, and short enough to read in full before running. They are covered by git history rather than by hashes here — read them, they are the only files we ask you to run.

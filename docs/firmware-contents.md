# What is actually inside `mi-tv-stick-4k_dnl_1440_01.7z`

Everything on this page was read out of the archive itself. Nothing here is copied from a forum post. It exists so that someone who finds a copy of this file somewhere can tell whether it is the right one, and so that the claims in the README can be checked rather than trusted.

---

## Archive

| | |
|---|---|
| Name | `mi-tv-stick-4k_dnl_1440_01.7z` |
| Size | 685,065,929 bytes |
| SHA-256 | `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b` |
| MD5 | `ffb220dd62cbff01f6e39461cd0154d1` |
| Compression | LZMA2 |
| Entries | 13 files, 3 directories |
| Uncompressed | 1,797,634,555 bytes |

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

The `images/` files are dated 2024-01-26 to 2024-01-29 in the archive; `adnl.exe` is dated 2021-08-20, matching the version banner it prints at runtime.

---

## Build identity

Read from `build.prop`-style strings inside `oem.img` and inside the `super` image:

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

**`release-keys` is the important part.** It means this build was signed with Xiaomi's official release keys — it is stock firmware, not a community-modified build. That is the reason a factory reset behaves normally on it, unlike on the modified `1469_MOD_9` build discussed in the README.

The `1440` in the filename is `ro.build.version.incremental`. The full build string people search for, `RTT0.211222.001.1440`, is `ro.build.display.id` minus the `release-keys` suffix.

Note the gap between the build ID date encoding (`211222` → 2021-12-22, the platform branch) and the actual build date (2023-11-24) with an October 2023 security patch. That is normal: the build ID names the platform release branch, not the day the image was compiled.

---

## Device identity

The same property set appears under every partition prefix (`system`, `vendor`, `odm`, `product`, `system_ext`), which is how Android 11 records this:

```
ro.product.brand         = Xiaomi
ro.product.device        = soul
ro.product.name          = soul
ro.product.model         = MiTV-AYFR0
ro.product.manufacturer  = Xiaomi
```

| Field | Value |
|---|---|
| Marketing name | Xiaomi Mi TV Stick 4K |
| Model number on the box | MDZ-27-AA |
| Internal codename | **`soul`** |
| Internal model string | **`MiTV-AYFR0`** |
| Platform | **`s4`** (Amlogic S4 family) |

`MiTV-AYFR0` is also the name the original `go.cmd` prints in its window title, which is a useful independent confirmation that the script and the images belong together.

> The SoC is commonly reported as the **Amlogic S905Y4**. The firmware itself only proves the platform family (`s4`); the specific part number comes from public specifications and is not verifiable from these files.

---

## Partition images

| Image | Size | Format | Written to |
|---|---:|---|---|
| `boot.img` | 67,108,864 | Android boot image (`ANDROID!`) | `boot_a`, `boot_b` |
| `vendor_boot.img` | 25,165,824 | Vendor boot v3 (`VNDRBOOT`) | `vendor_boot_a`, `vendor_boot_b` |
| `dtbo.img` | 2,097,152 | DTBO table (magic `d7b7ab1e`) | `dtbo_a`, `dtbo_b` |
| `vbmeta.img` | 8,192 | AVB vbmeta v1.0 (`AVB0`) | `vbmeta_a`, `vbmeta_b` |
| `vbmeta_system.img` | 4,096 | AVB vbmeta v1.0 (`AVB0`) | `vbmeta_system_a`, `vbmeta_system_b` |
| `oem.img` | 33,554,432 | filesystem image | `oem_a`, `oem_b` |
| `odm_ext.img` | 16,777,216 | filesystem image | `odm_ext_a`, `odm_ext_b` |
| `super-ab-1440-sparse.img` | 1,650,178,104 | Android sparse | `super` |

The presence of `AVB0` vbmeta images confirms Android Verified Boot is in use, consistent with a signed stock build and a locked bootloader.

Every image except `super` is written to **both** the `_a` and `_b` slots — this is an A/B (seamless update) device, and populating both slots is what the original `go.cmd` does.

---

## The `super` image

`super-ab-1440-sparse.img` is an **Android sparse image**, not a raw one. Converting it (see [`tools/simg2img.ps1`](../tools/simg2img.ps1)) yields:

```
sparse v1.0
block size     4,096 bytes
total blocks   460,800
total chunks   148
raw size       1,887,436,800 bytes  (1.76 GiB)
```

`1,650,178,104 → 1,887,436,800 bytes`.

The raw image is an Android **dynamic partition container**. Its LP metadata reads:

```
geometry magic        0x616C4467
metadata max size     65,536 bytes
metadata slots        3
logical block size    4,096
header magic          0x414C5030
header version        10.2
partitions            5
extents               5
groups                2
```

Logical partitions inside it:

| Logical partition | Size | |
|---|---:|---|
| `system_a` | 721,403,904 bytes | 688.0 MiB |
| `vendor_a` | 118,063,104 bytes | 112.6 MiB |
| `product_a` | 707,317,760 bytes | 674.6 MiB |
| `odm_a` | 8,695,808 bytes | 8.3 MiB |
| `system_ext_a` | 100,495,360 bytes | 95.8 MiB |

Only `_a` logical partitions are declared. On an A/B device the physical `super` partition is shared between slots and the metadata is rewritten as slots are populated, so this is what you would expect from an image built for slot A — and the device does boot after being written this way.

> We did **not** test what happens after a subsequent slot switch, so "only `_a` is declared and it works" is an observation about our device after this flash, not a general statement about A/B behaviour on this hardware.

---

## `bin/`

| File | Size | Notes |
|---|---:|---|
| `adnl.exe` | 2,436,809 | Amlogic USB DNL tool. Prints `Amlogic USB DNL tool: V[2.6.3] at Aug 20 2021`. Unsigned. |
| `AdbWinApi.dll` | 97,792 | Version resource: Android SDK 2.0.0.0, "Google, inc". Unsigned. |
| `AdbWinUsbApi.dll` | 62,976 | Version resource: Android SDK 2.0.0.1, "Google, inc". Unsigned. |
| `libwinpthread-1.dll` | 141,538 | MinGW-w64 runtime. Unsigned. |

The two `AdbWin*` DLLs explain the behaviour behind [obstacle 2](../README.md#obstacle-2--the-interface-guid-mismatch): `adnl.exe` reuses Google's ADB USB plumbing, and with it the ADB device interface GUID `{F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}`, which is what it enumerates by. Zadig registers a random GUID instead, so the two never meet until you add the ADB GUID by hand.

None of these binaries is redistributed by this repository. Their hashes are in [`CHECKSUMS.md`](CHECKSUMS.md).

---

## How this was determined

For anyone who wants to reproduce it rather than take our word for it, on plain Windows:

**Hashes and sizes** — `Get-FileHash`, `certutil -hashfile`, `(Get-Item x).Length`.

**Archive listing** — 7-Zip: right-click → *7-Zip* → *Open archive*, or `7z l mi-tv-stick-4k_dnl_1440_01.7z` from the 7-Zip install folder.

**Build properties** — the `ro.*` strings are plain ASCII inside the images. `findstr` will surface them:

```cmd
findstr /C:"ro.build.display.id" images\oem.img
```

**Sparse header and LP metadata** — read with the conversion script in [`tools/`](../tools/), which prints the sparse geometry as it runs. The LP metadata numbers above were parsed directly from the raw image's on-disk structures (geometry at offset 4096, metadata header at 12288), following the AOSP `liblp` layout.

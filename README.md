# Xiaomi Mi TV Stick 4K MDZ-27-AA — Unbrick / Recovery

Recovering a **Xiaomi Mi TV Stick 4K (MDZ-27-AA)** that was **stuck on the boot screen** by writing the stock firmware **`RTT0.211222.001.1440`** over USB, using Amlogic **DNL** mode and the `adnl` tool.

🇧🇷 **[Versão completa em português — README-PT-BR.md](README-PT-BR.md)**

---

## ⚠️ Read this before anything else

**This is a report of one real recovery that worked, not a product and not a guarantee.**

> ### 🛑 CORRECTION — 2026-09-10
>
> **The Android 11 procedure below flashed cleanly but did NOT make the device boot.**
> An earlier version of this page claimed it did. That claim was wrong: it was
> written from a green log (16/16 steps, every one `rc=0`) *before* the device was
> actually tested on a TV. It then sat on the Mi logo for 1h30, and again for a
> full hour the next day.
>
> The device was finally recovered on **2026-09-10**, with a completely different
> method — **[Android 14 recovery](docs/android-14-recovery.md)**.
>
> **Before you flash anything, find out which of the two bricks you have.**
> They need opposite fixes. See [Which brick do you have?](#which-brick-do-you-have)

- Everything here was **executed for real** on one MDZ-27-AA. The Android 11 flash log is in [`logs/flash-2026-09-08-did-not-boot.log`](logs/flash-2026-09-08-did-not-boot.log) — 16 steps, every one `rc=0`, and the device still did not boot. The recovery that worked is in [`logs/successful-flash-a14-2026-09-10.log`](logs/successful-flash-a14-2026-09-10.log) — 18 steps, 0 failures.
- It is published as **a last-resort aid for people who are already stuck and have found nothing else**. If your stick still boots, you almost certainly do not need this.
- **We take no responsibility for any failure, damage, data loss or permanently bricked device** resulting from anyone following these notes. You do this at your own risk, on your own hardware, by your own decision.
- Nobody can call a procedure like this "100% safe". It **erases the entire device**, it depends on your specific hardware revision, and a flash interrupted halfway leaves the device unbootable until you run it again successfully.

If you are not comfortable with that, stop here and use the manufacturer's warranty or service channel instead.

---

## Which brick do you have?

There are **two different bricks** on this device, they look identical on the TV
(stuck on the Mi logo), and they need **opposite** fixes. Flashing the wrong one
wastes days — it did here.

Tell them apart with two commands, before flashing anything:

```
fastboot reboot bootloader          # from the Amlogic/DNL state
fastboot getvar version-bootloader
```

| `version-bootloader` | Your bootloader is | Do this |
|---|---|---|
| `0.1`, and `getvar product` says `amlogic` | you are still in the **first** fastboot stage | see [The two fastboot stages](docs/android-14-recovery.md#the-two-fastboot-stages) |
| `01.01.25xxxx` or `01.01.26xxxx`, `product` says `soul` | **Android 14** | **[Android 14 recovery](docs/android-14-recovery.md)** — the Android 11 procedure on this page will never boot |
| no Android 14 bootloader, device was on Android 11 | Android 11 | the procedure on this page |

**Why this matters.** If your stick took the Android 11 → Android 14 OTA and it
failed partway, the bootloader is already Android 14 while the rest of the system
is not. Writing Android 11 firmware over that produces a perfectly clean flash and
a device that still does not boot — every time. The `bootloader` and `reserved`
partitions **cannot be rewritten over DNL** on this device, so you cannot bring it
back to Android 11. You have to go forward to Android 14.

The 4PDA firmware post states this outright, above the Android 11 images:
*"Не подходит для отката с 14-го андроида!"* — not suitable for rolling back from
Android 14.

---

## Table of contents

- [Is this for you?](#is-this-for-you)
- [When NOT to use this](#when-not-to-use-this)
- [What you need](#what-you-need)
- [The firmware file](#the-firmware-file)
- [Verifying your download](#verifying-your-download)
- [Step by step](#step-by-step)
- [The three obstacles we hit](#the-three-obstacles-we-hit-and-how-each-was-solved)
- [Troubleshooting](#troubleshooting)
- [What we changed compared to the original `go.cmd`](#what-we-changed-compared-to-the-original-gocmd)
- [Evidence: what is proven, what is not](#evidence-what-is-proven-and-what-is-not)
- [Alternatives](#alternatives)
- [Using an AI assistant instead](#using-an-ai-assistant-instead-claude-code-codex-etc)
- [References](#references)
- [Credits](#credits)

---

## Is this for you?

### The device

| | |
|---|---|
| Marketing name | Xiaomi Mi TV Stick 4K / Xiaomi TV Stick 4K |
| **Model number** | **MDZ-27-AA** (printed on the stick and on the box) |
| Internal codename | `soul` |
| Internal model string | `MiTV-AYFR0` |
| SoC platform | Amlogic S4 (`ro.board.platform=s4`) |
| Android | Android TV 11 |

The codename and model string above were read **directly out of the firmware images in this package** (`ro.product.device=soul`, `ro.product.model=MiTV-AYFR0`), not copied from a forum. See [`docs/firmware-contents.md`](docs/firmware-contents.md).

> The commonly cited SoC for this device is the **Amlogic S905Y4**. The firmware only proves the platform family (`s4`); the exact part number comes from public specs, not from these files.

### The symptom this addresses

- Stick powers on (LED lights up) but **hangs on the boot screen / Xiaomi or Android TV logo**, forever or in a loop.
- It does **not** reach the system, so ADB over the network is not available.
- When plugged into a PC by USB, Windows enumerates it as **`USB\VID_1B8E&PID_C004`**, usually named **`DNL`**, frequently with **Code 28 (no driver installed)**.

That last point is the real test. Run [`tools/check-dnl-device.ps1`](tools/check-dnl-device.ps1) (right-click → *Run with PowerShell*) — it only reads, changes nothing, and tells you whether the device is in DNL mode and what is missing.

> **DNL mode** is the Amlogic USB recovery mode exposed by the first-stage bootloader. It works even when nothing else on the device does, which is exactly why it is useful here. In our case the stick presented itself in DNL mode on its own when connected — **we did not have to trigger it manually, and we cannot document a reliable way to force it**, see [what is not proven](#evidence-what-is-proven-and-what-is-not).

---

## When NOT to use this

Do not use this procedure if:

- **Your stick still boots.** Update over the air instead (Settings → About → System update). Flashing gains you nothing and erases everything.
- **Your model is not MDZ-27-AA.** The Mi TV Stick 1080p/FHD (`MDZ-24-AA`) is a different device with different partitions. This firmware is not for it.
- **Windows shows the device under `VID_18D1` (Google).** That means the stick still reaches ADB or fastboot. You have easier options and DNL is the wrong tool.
- **`adnl getvar identify` does not return `06-00-00-10-00-00-00-00`.** The scripts here abort on their own in that case, and you should not override that check.
- **You only want to remove ads, sideload something, or "debloat".** This wipes the device to stock; it is a repair procedure, not a modding one.

> ### 🔴 This erases everything
> The first command in the sequence, `oem disk_initial`, **repartitions the internal storage and destroys all user data** — accounts, apps, settings. There is no backup step and nothing to undo. On a device that will not boot there is usually nothing left to lose, which is the only reason it is acceptable here.

---

## What you need

Everything below runs on **plain Windows**. No Git Bash, no Linux, no Python required (a Python variant is included for people who prefer it).

### Hardware

| Item | Notes |
|---|---|
| The stick, MDZ-27-AA | |
| **USB-A → USB-C cable, data-capable** | A charge-only cable will never enumerate. If Windows shows nothing at all, suspect the cable first. |
| A Windows PC | Windows 10/11. Administrator rights are needed twice, for the driver and the registry fix. |
| A **5V/1A wall charger** | For the first boot after flashing. See [First boot](#step-5--first-boot). |

We wrote the whole image over three different USB ports on the same PC. Port speed made no measurable difference to the failure we hit — see [obstacle 3](#obstacle-3--sparse-mode-failed-every-single-time).

### Software

| Tool | Where to get it | Redistributed here? |
|---|---|---|
| **7-Zip** | <https://www.7-zip.org/> | No — install it from the official site |
| **Zadig 2.9** | <https://github.com/pbatard/libwdi/releases> | No — download from the official release page |
| **`adnl.exe` v2.6.3** | Ships **inside the firmware `.7z`**, in `bin\` | No — you already get it with the firmware |
| The scripts in [`tools/`](tools/) | This repository | Yes — they are ours, plain text, read them before running |

> **Verify Zadig yourself.** Right-click `zadig-2.9.exe` → *Properties* → *Digital Signatures*. It must be signed by **Akeo Consulting** and Windows must report the signature as valid. The copy we used showed exactly that.
>
> `adnl.exe` and the DLLs beside it (`AdbWinApi.dll`, `AdbWinUsbApi.dll`, `libwinpthread-1.dll`) are **not digitally signed**. They come from inside a firmware archive distributed on forums, we cannot trace them to an Amlogic release page, and we deliberately do **not** mirror them here. Their SHA-256 values are recorded in [`docs/CHECKSUMS.md`](docs/CHECKSUMS.md) so you can at least confirm your copy matches the one that was actually used. Scan them if that matters to you.

---

## The firmware file

This is the file that is genuinely hard to find, and the main reason this repository exists.

```
mi-tv-stick-4k_dnl_1440_01.7z
```

| Property | Value |
|---|---|
| **Size** | **685,065,929 bytes** (653.33 MiB) |
| **SHA-256** | `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b` |
| **MD5** | `ffb220dd62cbff01f6e39461cd0154d1` |
| Contents | 13 files, 1,797,634,555 bytes uncompressed |
| Build ID | `RTT0.211222.001` |
| Incremental | `1440` |
| Display ID | `RTT0.211222.001.1440 release-keys` |
| Android | 11 |
| Build date | Fri Nov 24 10:24:43 CST 2023 |
| Security patch | 2023-10-05 |

Those build properties were **extracted from the images inside the archive**, not taken from a forum post. `release-keys` means this is an official Xiaomi-signed build, not a modified one.

### What is inside

```
mi-tv-stick-4k_dnl_1440_01/
├── go.cmd                                    1,560 bytes   original flash script (Russian)
├── bin/
│   ├── adnl.exe                          2,436,809 bytes   Amlogic USB DNL tool V2.6.3, Aug 20 2021
│   ├── AdbWinApi.dll                        97,792 bytes
│   ├── AdbWinUsbApi.dll                     62,976 bytes
│   └── libwinpthread-1.dll                 141,538 bytes
└── images/
    ├── boot.img                         67,108,864 bytes
    ├── dtbo.img                          2,097,152 bytes
    ├── odm_ext.img                      16,777,216 bytes
    ├── oem.img                          33,554,432 bytes
    ├── super-ab-1440-sparse.img      1,650,178,104 bytes   Android sparse image
    ├── vbmeta.img                            8,192 bytes
    ├── vbmeta_system.img                     4,096 bytes
    └── vendor_boot.img                  25,165,824 bytes
```

Per-file SHA-256 for every one of these: [`docs/CHECKSUMS.md`](docs/CHECKSUMS.md).

### Where to download it

> ### ⬇️ Direct download, no registration
>
> **[mi-tv-stick-4k_dnl_1440_01_MDZ-27-AA.7z](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/releases/download/v1.0-firmware-1440/mi-tv-stick-4k_dnl_1440_01_MDZ-27-AA.7z)** — mirrored in this repository's [Releases](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/releases/latest).
>
> 685,065,929 bytes · SHA-256 `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b`
>
> No account, no download limit, no waiting. This is the same archive that circulates as `mi-tv-stick-4k_dnl_1440_01.7z` — only the filename differs. **Check the hash anyway**, from here or from anywhere else.

Other sources, in case this mirror is ever removed:

| Source | Notes |
|---|---|
| **Yandex Disk** — <https://disk.yandex.ru/d/CW66IHxzsgpFHA> | The original link this file came from. **It periodically hits its download limit** and refuses new downloads; a Yandex account may be required, and account signup can fail for phone numbers in some countries (it did for ours, on a Brazilian number). This was the single hardest part of the whole recovery, and the reason this repository mirrors the file at all. |
| **GSMForum** — <https://gsmforum.ru/resources/xiaomi-mi-tv-stick-4k-mdz-27-aa.12470/> | Mirror of MDZ-27-AA material. Registration may be required. |
| **FirmwareDrive** — <https://firmwaredrive.com/index.php?a=downloads&b=folder&id=47997> | Third-party aggregator. |
| **4PDA thread** — <https://4pda.to/forum/index.php?showtopic=1041410&st=23820> | Where the file is discussed and where links surface when mirrors die. Registration required to see attachments. |

**Whatever source you use, check the SHA-256 before flashing.** That is the entire point of publishing the hash: a mirror you have never heard of becomes safe to use the moment its bytes match.

> **You may find this file under a slightly different name.** Some mirrors append the model number:
>
> ```
> mi-tv-stick-4k_dnl_1440_01.7z            ← name used by the original sources
> mi-tv-stick-4k_dnl_1440_01_MDZ-27-AA.7z  ← same file, model appended
> ```
>
> **These are the same archive.** Renaming a file does not change its contents, so both must produce the SHA-256 `6a54918c…03b60b`. The hash is what tells you the file is right; the name never does.

If you have a working mirror, please open an issue — see [`docs/mirrors.md`](docs/mirrors.md).

### About hosting the firmware here

Being straightforward about this, because it is someone else's software.

`mi-tv-stick-4k_dnl_1440_01.7z` is stock, signed Xiaomi firmware (`release-keys`). **It remains the property of Xiaomi.** We hold no redistribution rights, we claim none, and nothing in this repository grants you any. The [MIT license](LICENSE) covers our documentation and scripts — never the firmware.

It is mirrored here anyway, for one reason: the original source is a Yandex Disk link that keeps hitting its download limit, and people whose device is already dead were left with nowhere to get it. A stock recovery image is the only thing that brings an MDZ-27-AA back, and no official Xiaomi download exists for it.

- **Purpose.** Device repair and preservation. This is not a modified build, a bypass, or anything that unlocks functionality you did not pay for — it is the software the device shipped with, offered to people trying to make their own hardware work again.
- **If Xiaomi objects, it comes down.** No argument. Open an issue or contact the repository owner and the asset will be removed.
- **The documentation stands on its own.** Should the file ever be taken down, everything that makes another copy usable stays here: exact name, exact size, SHA-256, MD5, internal structure, per-file hashes, and the full working procedure. [`docs/mirrors.md`](docs/mirrors.md) exists for exactly that scenario.

**Verify the hash regardless of where you download from** — including from here. That is the part that actually protects you.

---

## Verifying your download

Do this **before** extracting. A truncated or tampered firmware written to a device that cannot boot is how a recoverable stick becomes an unrecoverable one.

### PowerShell (built into Windows)

Open the folder containing the file, hold **Shift** and right-click empty space → *Open PowerShell window here*, then:

```powershell
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm SHA256
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm MD5
(Get-Item .\mi-tv-stick-4k_dnl_1440_01.7z).Length
```

### Command Prompt (also built in)

```cmd
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z SHA256
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z MD5
```

### Expected values

```
Size    : 685065929
SHA-256 : 6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
MD5     : ffb220dd62cbff01f6e39461cd0154d1
```

Case does not matter. **If either hash differs, do not use the file** — download it again from another source.

---

## Step by step

Total hands-on time is short; the flash itself took **5 minutes 19 seconds** end to end in our run (09:38:01 → 09:43:20 in the log).

### Step 0 — Extract the firmware

Right-click the `.7z` → *7-Zip* → *Extract Here*. You get a folder named `mi-tv-stick-4k_dnl_1440_01` containing `go.cmd`, `bin\` and `images\`.

Copy the scripts from this repository's [`tools/`](tools/) folder **into that same folder**, next to `go.cmd`. That is where they expect to be.

You need roughly **4 GB free**: the archive, the extracted images, and the converted `super` image.

### Step 1 — Install the WinUSB driver (once per PC)

Only needed the first time you do this on a given computer.

1. Plug the stick into the PC. Windows will show it in Device Manager, typically as **`DNL`** with a yellow warning triangle (*Code 28 — the drivers for this device are not installed*).
2. Run **`zadig-2.9.exe` as Administrator**.
3. Menu **Options → List All Devices**.
4. In the dropdown, select the entry named **`DNL`**.
5. **Confirm that Zadig shows `USB ID  1B8E  C004`.** If it shows anything else, you have the wrong device selected — do not install, or you will replace the driver of some unrelated hardware.
6. Choose **WinUSB** as the target driver and click **Install Driver**.

Zadig installs it as an `oemNN.inf` (`oem76.inf` in our case), derived from `dnl.inf`, provider `libwdi`.

> The `android_winusb.inf` floating around in related repositories **does not work** for this. It only declares entries for VID `18D1` (Google) and has nothing for `1B8E` (Amlogic).

### Step 2 — Fix the interface GUID (once per PC)

**Do this even if the driver looks perfectly installed.** Without it, `adnl.exe` sits at `< waiting for Amlogic DNL device >` forever while Device Manager shows a healthy device. This is [obstacle 2](#obstacle-2--the-interface-guid-mismatch) and it is not obvious at all.

Right-click [`tools/fix-adnl-guid.ps1`](tools/fix-adnl-guid.ps1) → **Run with PowerShell**. It elevates itself to Administrator, finds the DNL device by its hardware ID, and adds the ADB interface GUID that `adnl.exe` searches for. It is safe to run more than once and does nothing if no DNL device is present.

Then run [`tools/check-dnl-device.ps1`](tools/check-dnl-device.ps1) to confirm everything is green.

> If PowerShell refuses to run the script, right-click it → *Properties* → tick **Unblock** → *OK*. That is Windows' mark-of-the-web protection on downloaded files, not an error in the script.

### Step 3 — Convert `super` to a raw image

The package ships `images\super-ab-1440-sparse.img` in Android sparse format. Writing it in sparse mode **failed on every attempt** here — see [obstacle 3](#obstacle-3--sparse-mode-failed-every-single-time). Converting it to a raw image and writing it normally worked first try.

Open PowerShell in the extracted firmware folder and run:

```powershell
.\simg2img.ps1 .\images\super-ab-1440-sparse.img .\images\super-raw.img
```

Expected output:

```
sparse v1.0  block=4096  blocks=460800  chunks=148
raw output will be 1,887,436,800 bytes (1.76 GiB)
...
wrote 1,887,436,800 bytes
size matches the sparse header. Conversion OK.
```

`1,650,178,104 bytes → 1,887,436,800 bytes`. It takes a few minutes and needs 1.8 GB free.

> [`tools/simg2img.ps1`](tools/simg2img.ps1) is pure PowerShell — nothing to install. It was verified to produce **byte-identical output** to the Python reference implementation ([`tools/simg2img.py`](tools/simg2img.py)) across RAW, FILL, DONT_CARE and CRC32 chunk types. Use whichever you prefer; the Python one needs Python installed.

### Step 4 — Flash

> ### 🔴 Point of no return
> The first command wipes the device. From here to the end of `super`, **do not unplug anything**. If it is interrupted, the stick will not boot until you run the whole sequence again successfully — you cannot fix it by writing `super` alone.

**The order matters more than anything else here.**

1. **Unplug the stick from the PC.** Confirm it disappeared from Device Manager.
2. Double-click **[`flash-dnl.cmd`](tools/flash-dnl.cmd)** (in the extracted firmware folder).
3. Confirm the two prompts. It will print `Waiting for an Amlogic DNL device...` and sit there.
4. **Now** plug the stick in. It starts within a couple of seconds.
5. Leave it alone until it says `DONE`.

<!-- -->

> ### ⚠️ `adnl` must be running *before* the stick is connected
> The DNL bootloader answers only during a short window right after USB enumeration. Afterwards it stays powered and visible in Device Manager but stops responding.
>
> | Order | Attempts | Result |
> |---|---|---|
> | Tool waiting first, stick plugged in after | 3 | Identity answered in **0.001 s** every time |
> | Stick already plugged in, tool started after | 3 | Timed out after 113 s, 121 s and 192 s |
>
> Six attempts, one variable, perfect correlation. The LED tells you nothing about this — it lights up identically either way.

Before writing anything, the script checks the hardware identity and aborts if it does not match:

```
DNL mode [TPL]	06-00-00-10-00-00-00-00
```

**Do not remove that check.** It is what stops you from flashing Mi TV Stick firmware onto some other Amlogic device.

#### The sequence it runs

```
oem disk_initial                    ← erases and repartitions everything
dtbo_a          / dtbo_b            ← images/dtbo.img
oem_a           / oem_b             ← images/oem.img
odm_ext_a       / odm_ext_b         ← images/odm_ext.img
vbmeta_a        / vbmeta_b          ← images/vbmeta.img
vbmeta_system_a / vbmeta_system_b   ← images/vbmeta_system.img
vendor_boot_a   / vendor_boot_b     ← images/vendor_boot.img
boot_a          / boot_b            ← images/boot.img
super                               ← images/super-raw.img   (last, ~5 min)
```

Seven images, both A and B slots, then `super`. That is the order from the original `go.cmd`, unchanged.

#### What you should see

Each step prints an `OKAY` and a total time. Observed durations from our log:

| Step | Size | Time |
|---|---|---|
| `oem disk_initial` | — | 0.14 s |
| `dtbo_a` / `dtbo_b` | 2 MB each | ~0.19 s each |
| `oem_a` / `oem_b` | 32 MB each | ~3.25 s each |
| `odm_ext_a` / `odm_ext_b` | 16 MB each | ~1.63 s each |
| `vbmeta_*`, `vbmeta_system_*` | 8 KB / 4 KB | instant |
| `vendor_boot_a` / `_b` | 24 MB each | ~2.45 s each |
| `boot_a` / `boot_b` | 64 MB each | ~6.6 s each |
| **`super`** | **1800 MB** | **287.46 s (~4 min 47 s)** |

`super` prints a percentage counter that crawls. It is working. Do not touch it.

### Step 5 — First boot

1. Unplug the stick from the PC.
2. Plug it into the TV's HDMI port, and power it from a **5V/1A wall charger**, not the TV's USB port.
3. Wait. **First boot takes 5 to 10 minutes**, much of it on a black screen or a static logo.
4. Do not cut power during this.

> **Why the wall charger matters.** The stick is specified for 5V/1A. A TV or monitor USB port often supplies only 500 mA. The first boot after a flash is the peak-draw moment — app optimisation plus heavy eMMC writes — and that is exactly when insufficient power bites. Use a proper charger at least for this first boot.

Once it is up, it will pick up official OTA updates over Wi-Fi on its own. You do not need to flash anything by cable again.

> **Factory reset is safe on this firmware.** The widely repeated warning that a factory reset locks the bootloader and forces a re-flash applies to the **modified `1469_MOD_9`** build, which requires an unlocked bootloader. This one is stock, Xiaomi-signed, locked bootloader — reset is a normal operation.

---

## The three obstacles we hit, and how each was solved

None of these are about the firmware itself. Each cost real time and none is documented in an obvious place, which is most of why this repository exists.

### Obstacle 0 — actually getting the file

Before any technical problem: the firmware existed at a single Yandex Disk link that had **hit its download limit**, and creating a Yandex account to work around it failed because the SMS verification never arrived for a Brazilian phone number. This is what the hashes in this repository are meant to solve for the next person — any mirror becomes usable once its bytes verify.

### Obstacle 1 — no driver (Code 28)

Windows saw `USB\VID_1B8E&PID_C004` named `DNL`, but with `CM_PROB_FAILED_INSTALL`.

**Solution:** Zadig → *Options → List All Devices* → select `DNL` → **WinUSB** → *Install Driver*, as Administrator. Covered in [Step 1](#step-1--install-the-winusb-driver-once-per-pc).

### Obstacle 2 — the interface GUID mismatch

With the driver installed and Device Manager showing no error whatsoever, `adnl` still printed `< waiting for Amlogic DNL device >` indefinitely.

**Cause:** Zadig registers a **randomly generated** device interface GUID. `adnl.exe` looks the device up by the **ADB** interface GUID, which is compiled into the binary. Both halves worked correctly; they simply never saw each other.

```
Zadig registered  : {915C1867-BE44-4EE1-835B-E1D764786AE1}   (random, differs per install)
adnl.exe looks for: {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}   (ADB interface GUID)
```

**Solution:** add the ADB GUID to `DeviceInterfaceGUIDs` (type `REG_MULTI_SZ`), keeping Zadig's, then restart the device so Windows re-reads it:

```
HKLM\SYSTEM\CurrentControlSet\Enum\USB\VID_1B8E&PID_C004\<serial>\Device Parameters
    DeviceInterfaceGUIDs = {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}
                           {915C1867-BE44-4EE1-835B-E1D764786AE1}
```

[`tools/fix-adnl-guid.ps1`](tools/fix-adnl-guid.ps1) does exactly this, finding your device automatically.

### Obstacle 3 — sparse mode failed every single time

The 14 small partitions wrote without a hitch. `super` failed **every time**, always identically:

```
ERR[DNL]Fail in send data at len 0x20000
FAILED (data transfer failure)
```

Four attempts, three different USB ports, always at **0x20000 (128 KB)**, always at roughly 5.3 seconds. The ports had very different throughput and it changed nothing — which ruled out the cable, the port and the host controller.

**Cause:** `super` was the only partition written with `-t sparse`. The 14 that succeeded all used normal mode.

**Solution:** convert the sparse image to raw and write it in normal mode.

```powershell
.\simg2img.ps1 .\images\super-ab-1440-sparse.img .\images\super-raw.img
```
```
adnl partition -p super -f images\super-raw.img        ← note: no -t sparse
```

1.76 GiB written in 287 seconds without a single retransmission.

---

## Troubleshooting

### Windows shows nothing at all when I plug the stick in

- Try a different **USB cable** — many USB-C cables are charge-only and carry no data lines.
- Try a different USB port, preferably one directly on the motherboard rather than a hub or front panel.
- If the stick shows up under **`VID_18D1`** instead, it is in ADB or fastboot mode, not DNL — this procedure does not apply to you.

### `DNL` appears with a yellow triangle / Code 28

Missing driver. That is [Step 1](#step-1--install-the-winusb-driver-once-per-pc).

### `< waiting for Amlogic DNL device >` never ends

In order of likelihood:

1. **The GUID fix has not been applied.** Run [`tools/fix-adnl-guid.ps1`](tools/fix-adnl-guid.ps1). This was our case and it is invisible from Device Manager.
2. **Wrong order.** The stick must be plugged in *after* the tool is already waiting. Unplug it, restart the script, plug it back in.
3. **Driver is not WinUSB.** Run [`tools/check-dnl-device.ps1`](tools/check-dnl-device.ps1) — it reports which driver is bound.
4. **The DNL window has closed.** If the stick has been sitting plugged in for a while, unplug it and start over.

### `ERR[DNL]Fail in send data at len 0x20000` / `FAILED (data transfer failure)`

Almost certainly `super` in sparse mode. Convert it to raw — [Step 3](#step-3--convert-super-to-a-raw-image). If it happens on a *small* partition instead, suspect the cable.

### `FAILED (remote failure)` in about 11 ms when writing `super` alone

`super` cannot be written on its own. `oem disk_initial` must run in the **same session**, immediately before. Re-run the whole script.

### The flash failed partway and now the stick is dead

Expected, and recoverable. `oem disk_initial` erased it, so of course it does not boot. Fix whatever failed and **run the complete sequence again from the beginning**. It is not more broken than it was.

### Identity check fails / the script aborts before writing

That is the safety net doing its job. `adnl getvar identify` returned something other than `06-00-00-10-00-00-00-00`. Either the device is not an MDZ-27-AA in DNL mode, or `adnl` never really established communication. Do not disable the check.

### Flash succeeded but the stick still will not boot

- Give it the full **10 minutes** on first boot before concluding anything.
- Power it from a **wall charger**, not a TV USB port. This is a genuinely common cause.
- Try a different HDMI port and cable to rule out the display path.

### PowerShell will not run the `.ps1` files

Right-click the file → *Properties* → tick **Unblock** → *OK*. If it still refuses, open PowerShell as Administrator and run the script explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\fix-adnl-guid.ps1
```

---

## What we changed compared to the original `go.cmd`

The `go.cmd` shipped inside the archive is in Russian and does essentially the right thing. A transcription with an English translation is in [`docs/original-go.cmd.md`](docs/original-go.cmd.md).

Our [`flash-dnl.cmd`](tools/flash-dnl.cmd) keeps the same partition order and the same identity check, and differs in exactly these ways:

| | Original `go.cmd` | This repository |
|---|---|---|
| `super` image | `super-ab-1440-sparse.img` with `-t sparse` | `super-raw.img` in normal mode — **the only functional change** |
| Error handling | Continues after a failed step | Aborts immediately and says which step failed |
| Confirmation | None — starts on double-click | Asks twice before erasing anything |
| Folder check | None | Verifies `bin\` and `images\` are present first |
| Language | Russian (CP866) | English |
| Guidance | None | Explains the plug-in order and what a failure means |

The identity check, the command sequence and the partition order are **unchanged**. We did not invent a procedure; we fixed one transfer mode and added guard rails.

---

## Evidence: what is proven, and what is not

Being explicit about this matters — following a confidently written but wrong instruction is how a recoverable device becomes scrap.

### Proven by the files in this repository

- The exact size, SHA-256 and MD5 of `mi-tv-stick-4k_dnl_1440_01.7z`, and of every file inside it.
- The archive's complete contents (13 files) and their internal structure.
- Build identity read straight out of the images: `ro.build.display.id=RTT0.211222.001.1440 release-keys`, `ro.build.id=RTT0.211222.001`, `ro.build.version.incremental=1440`, `ro.build.version.release=11`, `ro.build.version.security_patch=2023-10-05`, `ro.build.date=Fri Nov 24 10:24:43 CST 2023`.
- Device identity read straight out of the images: `ro.product.device=soul`, `ro.product.model=MiTV-AYFR0`, `ro.product.brand=Xiaomi`, `ro.board.platform=s4`.
- The `super` image is an Android dynamic-partition container, LP metadata v10.2, 4096-byte logical blocks, containing `system_a`, `vendor_a`, `product_a`, `odm_a`, `system_ext_a`.
- The full working command sequence and the exact timing of each step, from [`logs/successful-flash-2026-09-08.log`](logs/successful-flash-2026-09-08.log): 16 steps, all `rc=0`, 09:38:01 → 09:43:20.
- The identity string `06-00-00-10-00-00-00-00` and the tool version `Amlogic USB DNL tool: V[2.6.3] at Aug 20 2021`.
- `super` written from a **raw** image in normal mode completed in 287.46 s.
- [`tools/simg2img.ps1`](tools/simg2img.ps1) produces output byte-identical to the Python reference across all four sparse chunk types (verified against a synthetic image covering RAW, FILL, DONT_CARE and CRC32).

### First-hand, from the recovery session, but not in the attached log

The attached log only records the successful run. These come from the notes written during the session:

- The sparse-mode failure signature (`ERR[DNL]Fail in send data at len 0x20000`, four attempts, three ports, always at 0x20000 and ~5.3 s).
- The plug-in ordering result (3 successes waiting-first vs 3 timeouts plugged-in-first).
- The GUID mismatch and the specific Zadig-generated GUID observed.
- `FAILED (remote failure)` in ~11 ms when writing `super` without `oem disk_initial` in the same session.
- First boot taking 5–10 minutes.

### From external sources, not verified here

- The SoC being specifically the **Amlogic S905Y4** (the firmware only proves platform family `s4`).
- The 5V/1A power rating (device labelling and public specs).
- Everything about the modified `1440_MOD_8.2` and `1469_MOD_9` builds, including the claim that a factory reset on `1469_MOD_9` locks the bootloader — taken from the [yuliitezarygml/xiaomi-fimware](https://github.com/yuliitezarygml/xiaomi-fimware) README. **We did not test those builds.**

### 🟡 Not established — be careful here

- **How to force DNL mode on demand.** Our stick presented itself in DNL mode by itself when connected. We never had to trigger it, so we cannot document a button combination or pin short, and **we will not guess at one**. If your stick does not enumerate as `VID_1B8E&PID_C004`, this procedure has no entry point for you, and the 4PDA thread is the place to ask.
- **Whether sparse mode fails universally.** It failed consistently on our host across three ports, but we cannot say whether the cause is the `adnl` build, the bootloader, the host USB stack, or that specific sparse image. Raw mode is a workaround, not a diagnosis.
- **Whether writing only slot A inside `super` is sufficient in general.** The LP metadata only declares `_a` partitions, and the device boots — but we did not test the effect of a slot switch afterwards.
- **Whether this firmware suits every MDZ-27-AA hardware revision.** One device, one success. The identity check is your protection, not our testing.
- **The provenance of `adnl.exe`.** It is unsigned and we could not trace it to an official Amlogic distribution. We only know the SHA-256 of the copy that worked.

---

## Alternatives

If the stock `1440` file is genuinely unobtainable, [yuliitezarygml/xiaomi-fimware](https://github.com/yuliitezarygml/xiaomi-fimware) publishes two **modified** builds as GitHub Releases, downloadable directly without registration:

| File | Size | Method | Bootloader unlock | Data |
|---|---|---|---|---|
| `MI-TV-STICK-4K_1440_MOD_8.2.7z` | 789,395,886 bytes | DNL | Not required | Preserved (per its README) |
| `MI-TV-STICK-4K_1469_MOD_9.7z` | 662,495,411 bytes | fastboot | **Required** | Erased |

> ⚠️ Both are **modified, not stock**. Its README states that on `1469_MOD_9` a **factory reset locks the bootloader** and forces you to flash again to get the device running. We did not test either build — treat them as a fallback, not a first choice, and read that repository's own warnings.

---

## Using an AI assistant instead (Claude Code, Codex, etc.)

Everything above is written to be done by hand with nothing but Windows. If you do have an AI coding assistant with terminal access, it can drive most of it for you — hashing, converting, diagnosing the USB state, reading the output.

A ready-made prompt is in **[`docs/AI-ASSISTANT-PROMPT.md`](docs/AI-ASSISTANT-PROMPT.md)**. Paste it into the assistant, in the folder where you extracted the firmware.

The assistant still cannot plug the cable in for you, and the ordering rule in [Step 4](#step-4--flash) still applies.

---

## References

Sources consulted during this recovery. The 4PDA thread is the primary community source for this device; most of it is in Russian and registration is required to see attachments.

- 4PDA — main thread, Xiaomi Mi TV Stick 4K: <https://4pda.to/forum/index.php?showtopic=1041410>
- 4PDA — firmware reference: <https://4pda.to/forum/index.php?showtopic=1041410&st=23820>
- 4PDA — download-limit / availability discussion: <https://4pda.to/forum/index.php?showtopic=1041410&st=37200>
- 4PDA — other versions and methods: <https://4pda.to/forum/index.php?showtopic=1041410&st=32600>
- 4PDA — fastboot route: <https://4pda.to/forum/index.php?showtopic=1041410&st=19540>
- 4PDA — report related to build 1407: <https://4pda.to/forum/index.php?showtopic=1041410&st=28380>
- Yandex Disk — original firmware link: <https://disk.yandex.ru/d/CW66IHxzsgpFHA>
- GitHub — yuliitezarygml/xiaomi-fimware (modified builds): <https://github.com/yuliitezarygml/xiaomi-fimware>
- GSMForum — MDZ-27-AA dump: <https://gsmforum.ru/resources/xiaomi-mi-tv-stick-4k-mdz-27-aa.12470/>
- FirmwareDrive — folder 47997: <https://firmwaredrive.com/index.php?a=downloads&b=folder&id=47997>
- Zadig / libwdi releases: <https://github.com/pbatard/libwdi/releases>
- 7-Zip: <https://www.7-zip.org/>
- AOSP sparse image format (`sparse_format.h`): <https://android.googlesource.com/platform/system/core/+/refs/heads/main/libsparse/include/sparse/sparse.h>

---

## Credits

- The **4PDA community**, who kept this device alive and hosted the firmware for years.
- **Yandex Disk uploader** of `mi-tv-stick-4k_dnl_1440_01.7z` — including the original `go.cmd`, whose command sequence this procedure follows.
- **[yuliitezarygml](https://github.com/yuliitezarygml)** for mirroring alternative builds openly.
- **[Pete Batard / Akeo](https://github.com/pbatard/libwdi)** for Zadig, without which the driver step would be far harder.
- **Amlogic** for the `adnl` DNL tool bundled in the package.

Written up after a successful recovery on 2026-09-08.

---

## License

The **documentation and the scripts in [`tools/`](tools/)** in this repository are released under the [MIT License](LICENSE).

This repository contains **no firmware, no proprietary binaries and no redistributed third-party tools**. Xiaomi firmware, `adnl.exe` and Zadig each remain the property of their respective owners and are linked, not copied.

## Disclaimer

Provided as-is, with no warranty of any kind. **We accept no responsibility for any damage, data loss, failed flash or permanently bricked device** arising from the use of this information. Flashing firmware over USB can render hardware unusable and will void your warranty. This is a record of what worked once, on one device, offered to people who have run out of other options. You proceed entirely at your own risk.

---

<sub>Keywords for search: MDZ-27-AA, MDZ 27 AA firmware, MDZ-27-AA unbrick, MDZ-27-AA recovery, Xiaomi Mi TV Stick 4K brick, Xiaomi TV Stick 4K firmware, mi-tv-stick-4k_dnl_1440_01, mi-tv-stick-4k_dnl_1440_01.7z, RTT0.211222.001.1440, Xiaomi TV Stick 4K DNL, Xiaomi TV Stick 4K recovery, adnl, Amlogic DNL mode, MiTV-AYFR0, soul, stuck on boot logo.</sub>

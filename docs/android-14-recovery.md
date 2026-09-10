# Android 14 recovery — the method that actually worked

🇧🇷 **[Versão em português](pt-br/recuperacao-android-14.md)**

For a **Xiaomi Mi TV Stick 4K (MDZ-27-AA / `soul`)** whose Android 11 → Android 14
OTA failed partway, leaving it stuck on the Mi logo.

Executed for real on **2026-09-10**: 18 steps, 0 failures, device booted.
Full output: [`../logs/successful-flash-a14-2026-09-10.log`](../logs/successful-flash-a14-2026-09-10.log)

---

## Why the Android 11 route cannot work here

If the A14 OTA got far enough to replace the bootloader, your device is a hybrid:
an Android 14 bootloader and device tree, with an Android 11 (or half-written)
userland. Writing the stock 1440 firmware over it flashes cleanly and still does
not boot — confirmed three times here, including a full hour on a TV.

The reason is that two partitions **refuse to be written** on this device:

| Path tried | Result |
|---|---|
| fastboot, 1st stage | partition is not even in the table (`partition size: 0`) |
| FastbootD (`fastboot reboot fastboot`) | `Failed to boot into userspace fastboot` |
| `adnl partition -p bootloader` / `-p reserved` | `FAILED (remote failure)` |
| same, inside `adnl oem disk_initial` | command accepted, then `ERR[DNL]Fail in send data at len 0x20000` and `ERR[DNL]Fail in _command_end` |

`bootloader` lives in the eMMC boot hardware area; `reserved` holds the partition
table and the `_aml_dtb` device tree the running U-Boot reads from. Neither can be
replaced from DNL.

There is also a circular trap worth knowing about: **FastbootD lives in the recovery
ramdisk inside `boot`/`vendor_boot`, and needs a valid device tree to start.** The
device tree is the broken thing. So you cannot use the mode that writes `reserved`,
because `reserved` is what is wrong. Any package whose script depends on FastbootD —
including the `14-to-11` downgrade package — is a dead end on a device in this state.

**Conclusion: you cannot go back to Android 11. Go forward to Android 14.**

---

## The two fastboot stages

This is the single most useful discovery here, and it is not documented in English
anywhere we could find.

This device has **two different fastboot implementations**, and almost everything
useful lives in the second one:

| | 1st stage | 2nd stage |
|---|---|---|
| USB id | `VID_1B8E&PID_C004` (Amlogic), named `DNL` | `VID_18D1&PID_4EE7` (Google) |
| `getvar product` | `amlogic` | `soul` |
| `getvar version-bootloader` | `0.1` | e.g. `01.01.260610.084506` |
| `flashing unlock` | *unknown command* | **OKAY** |
| `flash bootloader` | partition size 0 | **OKAY** |
| `set_active` | *unknown command* | **OKAY** |
| `fastboot -w` | cannot find partitions | **OKAY**, with `mke2fs` |

You move from the first to the second with one command:

```
fastboot reboot bootloader
```

Note it is `reboot bootloader`, **not** `reboot fastboot`. `reboot fastboot` asks for
FastbootD (userspace), which does not start on a broken device — that difference cost
two days here.

### You need the Google USB driver

The 2nd stage enumerates as `VID_18D1&PID_4EE7` and Windows has no driver for it —
it appears with `CM_PROB_FAILED_INSTALL` and every command hangs or fails. Install
the **Google USB Driver**
(`https://dl.google.com/android/repository/usb_driver_r13-windows.zip`), which
contains the exact entry:

```
%CompositeAdbInterface% = USB_Install, USB\VID_18D1&PID_4EE7
```

`pnputil /add-driver android_winusb.inf /install`. This does not touch the Amlogic
DNL driver.

### Catching the device: the timing trick

A stick in this state **cycles on the USB bus by itself** — roughly 6 s present,
6 s absent, ~12 s period (measured). You do not need to unplug anything.

**The order matters and is not interchangeable:**

1. wait until the device is **absent** from the bus
2. **then** run `fastboot reboot bootloader` — it sits at `< waiting for any device >`
3. it captures the fresh session when the device reappears, ~2 s later

Starting fastboot *after* the device is already back grabs a dead session and returns
`Write to device failed (Unknown error)`. If the device has stopped cycling and the
link is dead, physically unplug and replug it — only re-enumeration revives it.

`tools/check-usb-mode.ps1` in this repository prints which stage you are in.

---

## What you need

- **`mi-tv-stick-4k_14_26.6.10_91.7z`** (~944 MB) — the official Android 14 fastboot
  package. See [Getting the files](#getting-the-files).
- The **Google USB Driver** (above).
- Windows. The package ships its own `fastboot.exe`, `mke2fs.exe` and `make_f2fs.exe`.

Prefer the build that matches your bootloader. Read yours with
`fastboot getvar version-bootloader` in the 2nd stage: `01.01.260610.084506` means
`V816.0.26.6.10`, so use the `26.6.10` package.

---

## The procedure

The package ships `go.cmd`, and it is correct — run it. Every command below is what
it does, in order, and what a successful run prints.

```
fastboot reboot bootloader                                  -> product: soul
fastboot getvar is-userspace                                 -> no
fastboot getvar version-bootloader                           -> 01.01.260610.084506

fastboot flashing unlock
fastboot flashing unlock_critical

fastboot            flash bootloader    images\bootloader.img
fastboot --slot all flash dtbo          images\dtbo.img
fastboot --slot all flash oem           images\oem.img
fastboot --slot all flash odm_ext       images\odm_ext.img
fastboot --slot all flash vbmeta        images\vbmeta.img
fastboot --slot all flash vbmeta_system images\vbmeta_system.img
fastboot --slot all flash vendor_boot   images\vendor_boot.img
fastboot --slot all flash boot          images\boot.img
fastboot            flash super         images\super.img

fastboot flashing lock
fastboot flashing lock_critical

fastboot reboot bootloader
fastboot flashing unlock
fastboot set_active other
fastboot set_active other
fastboot -w                                                  # erases userdata
fastboot flashing lock
```

**No step uses FastbootD.** That is precisely why this works where the `14-to-11`
package does not.

`flash super` is 1.8 GB; fastboot splits it into sparse chunks automatically
(11 × 128 MB here, about 2 minutes). `fastboot -w` erases and recreates userdata —
this is a factory reset, and it is intentional.

`tools/go-a14.sh` in this repository is a faithful transcription of `go.cmd` (verified
command by command, 20 of 20 identical) that adds logging and the bus-timing recipe
above, so it does not depend on plugging the stick in at exactly the right moment.

### First boot

Unplug from the PC, power it from a **wall charger**, HDMI into a TV. Allow up to
10 minutes: the first boot after replacing the bootloader, the whole `super` and the
userdata is slow.

A booted device enumerates on USB as `VID_18D1&PID_4EE1` with the friendly name
`MiTV-AYFR0` — that is Android's MTP gadget, and it is a reliable sign the system is
running even without a TV to look at. A device that did **not** boot comes back as
`VID_1B8E&PID_C004` (DNL).

### If it still hangs on the logo

Go back to the 2nd stage and switch slots — the two published reports contradict each
other about which one works, so try both:

```
fastboot reboot bootloader
fastboot flashing unlock
fastboot set_active b        # or 'a'
fastboot reboot
```

---

## Getting the files

### The fastboot package (preferred)

`mi-tv-stick-4k_14_26.6.10_91.7z` — Yandex Disk, from the 4PDA thread:
`https://disk.yandex.ru/d/9toYWX5hWET-wQ`

Older Android 14 builds, same generation, also usable:

| File | Link |
|---|---|
| `mi-tv-stick-4k_14_250303_91.7z` (fastboot) | `https://disk.yandex.ru/d/FS_mL28j84U4Lw` |
| `mi-tv-stick-4k_14_250303_01.7z` (DNL) | `https://disk.yandex.ru/d/as4J2_sLatS4ZA` |

Suffix `_91` means a fastboot package (needs the ADB driver); `_01` means a DNL
package (needs the Amlogic driver).

These links are frequently **over their public download quota**
(`DiskResourceDownloadLimitExceededError`). That limit belongs to the file, not to
you — a new machine or a new IP changes nothing. Saving the file to your own Yandex
Disk and downloading from there bypasses the public quota.

### Fallback: the official OTA, straight from Google

If Yandex is blocked, the full Android 14 OTA packages are hosted on Google's own
servers and are always reachable. Prefix them with
`https://android.googleapis.com/packages/ota-api/package/`:

| Build | File |
|---|---|
| `V816.0.26.6.10` user (latest) | `4eb355aa75c0fb7fdf79c98d7dc2e4acd4636280.zip` |
| `V816.0.26.6.10` userdebug | `3008ec5c880eb220b786f2c431e12d2622ea1f56.zip` |
| `V816.0.26.5.18` user | `981690fca34f874330751411fea24dce9c24894e.zip` |
| `V816.0.26.1.7` user | `00291fa1218a9e1ce7672af44e30510d88d22565.zip` |

These are **OTA packages** (`payload.bin`), not flashable images. To convert one:

```
python tools/payload_dumper.py <ota>.zip -o out/     # extracts all 16 partitions
python tools/monta_super.py --molde <any super.img> --dir out/ \
       --saida super.img --conferir                  # rebuilds super (lpmake equivalent)
```

`payload_dumper.py` verifies every extracted partition against the SHA-256 recorded in
the payload manifest. `monta_super.py` exists because the Python `liblp` package only
implements reading; it was validated by rebuilding a factory `super.img`
**byte for byte identical**.

We used this path to independently verify the Yandex package: `bootloader`, `boot`,
`dtbo`, `oem`, `odm_ext` and all eight logical partitions inside `super.img` are
byte-for-byte identical to Google's official OTA of the same build.

---

## Notes on this device

- **The `super` layout**: `size=1887436800`, `first_logical_sector=2048`,
  `alignment=1 MB`, `metadata_max_size=65536`, 3 slots, `logical_block_size=4096`,
  header v10.2, group `amlogic_dynamic_partitions_a`. Extents are aligned to the
  block device `alignment` (1 MB), not to `logical_block_size`.
- **The six metadata areas alternate `_a` and `_b`** in file order, both variants
  pointing at the same extents. This contradicts liblp's own convention (where the
  backup of slot N mirrors the primary of slot N) but is what the factory image does.
- **Android 14 adds three logical partitions** the 1440 image does not have:
  `system_dlkm`, `vendor_dlkm`, `odm_dlkm`.
- The Android 14 `super` totals 1,375,821,824 bytes of data against a group maximum
  of 1,876,951,040.

---

## Sources

Everything useful about this device is on the 4PDA thread, in Russian, behind a
login, and not indexed in English. Thread `4pda.to/forum/index.php?showtopic=1041410`.

| What | Post |
|---|---|
| Firmware list, with the compatibility warnings | `127973104` |
| The Android 14 fastboot package for unbricking | `144826494` |
| Android 14 OTA links (Google) | `135711658` |
| Brick recovery report | `144590518` |
| Same symptom, fixed with the A14 package + `set_active a` | `144825391` |

An account is required — the spoilers holding the links **do not exist in the page
source** for anonymous visitors, which is why several rounds of searching found
nothing.

# The original `go.cmd`, transcribed and translated

`go.cmd` ships inside `mi-tv-stick-4k_dnl_1440_01.7z`, at the root of the extracted folder. It is a 1,560-byte Windows batch file written in Russian, encoded in **CP866** (the Russian OEM code page) so that the console renders it correctly.

It is reproduced here for reference and attribution: it is the source of the partition order this repository follows, and of the identity check that protects you from flashing the wrong device. Credit for the sequence goes to whoever assembled that package.

```
SHA-256  b278b7e19a4439247bfed5dc8d46e7147fb74e51b6af92cef44c4e2dba817e41
MD5      c294f2f6b3681a52e258490f47a000c1
```

> This page transcribes a 1.5 KB text script, so that people can understand and audit the procedure. The firmware itself is not redistributed here.

---

## Transcription (Russian text decoded from CP866)

```bat
@title Прошивка устройства MiTV-AYFR0

@setlocal

@prompt $g

@echo.
@echo Будет установлена прошивка RTT0.211222.001.1440
@echo в устройство Xiaomi TV Stick 4K

@cd /d "%~dp0"

@bin\adnl devices > nul

@echo.
@echo Подключите устройство к компьютеру ...
@bin\adnl getvar identify 2> nul

bin\adnl getvar identify

@bin\adnl getvar identify 2>&1 | find "06-00-00-10-00-00-00-00" > nul
@if not %errorlevel% == 0 (
  echo.
  echo Прошивка невозможна !
  goto quit
)

bin\adnl oem disk_initial

bin\adnl partition -p dtbo_a          -f images\dtbo.img
bin\adnl partition -p dtbo_b          -f images\dtbo.img

bin\adnl partition -p oem_a           -f images\oem.img
bin\adnl partition -p oem_b           -f images\oem.img

bin\adnl partition -p odm_ext_a       -f images\odm_ext.img
bin\adnl partition -p odm_ext_b       -f images\odm_ext.img

bin\adnl partition -p vbmeta_a        -f images\vbmeta.img
bin\adnl partition -p vbmeta_b        -f images\vbmeta.img

bin\adnl partition -p vbmeta_system_a -f images\vbmeta_system.img
bin\adnl partition -p vbmeta_system_b -f images\vbmeta_system.img

bin\adnl partition -p vendor_boot_a   -f images\vendor_boot.img
bin\adnl partition -p vendor_boot_b   -f images\vendor_boot.img

bin\adnl partition -p boot_a          -f images\boot.img
bin\adnl partition -p boot_b          -f images\boot.img

bin\adnl partition -p super           -f images\super-ab-1440-sparse.img -t sparse

:quit

@echo.
@echo Работа скрипта завершена. Нажмите любую клавишу
@pause > nul
```

## Translation of the Russian strings

| Russian | English |
|---|---|
| `Прошивка устройства MiTV-AYFR0` | Flashing device MiTV-AYFR0 |
| `Будет установлена прошивка RTT0.211222.001.1440` | Firmware RTT0.211222.001.1440 will be installed |
| `в устройство Xiaomi TV Stick 4K` | onto the Xiaomi TV Stick 4K |
| `Подключите устройство к компьютеру ...` | Connect the device to the computer ... |
| `Прошивка невозможна !` | Flashing is not possible! |
| `Работа скрипта завершена. Нажмите любую клавишу` | Script finished. Press any key |

---

## What it tells us

**It names the device.** The window title says `MiTV-AYFR0`, matching `ro.product.model` inside the images. Script and firmware belong together.

**It names the build.** `RTT0.211222.001.1440`, matching `ro.build.display.id`.

**It checks the hardware before writing.** The identity string `06-00-00-10-00-00-00-00` must be present in the output of `adnl getvar identify`, or the script jumps to `:quit` and writes nothing. This is the single most important safety property of the whole procedure and our version keeps it unchanged.

**`oem disk_initial` comes first.** This repartitions the storage and destroys all user data. Everything after it depends on it having run in the same session — writing `super` alone against an un-initialised device fails in about 11 ms with `FAILED (remote failure)`.

**Both slots are written.** Seven images, each to `_a` and `_b`. This is an A/B device.

**`super` is written last, in sparse mode.** This is the one line that did not work for us:

```bat
bin\adnl partition -p super -f images\super-ab-1440-sparse.img -t sparse
```

It failed on every attempt, across three USB ports, always at `0x20000` bytes:

```
ERR[DNL]Fail in send data at len 0x20000
FAILED (data transfer failure)
```

Converting the image to raw and dropping `-t sparse` worked on the first try and wrote 1.76 GiB in 287 seconds.

---

## Weaknesses this repository's version addresses

The original is compact and does the right thing, but it was written for someone who already knows the procedure:

- **It does not stop on failure.** Every `adnl` call runs unconditionally after the identity check, so a failed partition write scrolls past and the script still ends with "press any key". Ours aborts and names the failed step.
- **It starts immediately on double-click.** No confirmation before an operation that erases the device. Ours asks twice.
- **It says nothing about the plug-in order**, which was the single biggest practical obstacle: `adnl` has to be waiting *before* the stick is connected.
- **It assumes you are in the right folder** and gives a confusing failure if you are not.
- **It is in Russian**, which is a real barrier for most people searching for this in English, Portuguese or Spanish.

See [`tools/flash-dnl.cmd`](../tools/flash-dnl.cmd). The command sequence, the identity check and the partition order are identical; only the `super` transfer mode differs.

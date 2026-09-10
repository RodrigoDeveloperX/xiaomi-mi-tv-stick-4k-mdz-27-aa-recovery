# Doing this with an AI assistant

🇧🇷 [Versão em português](pt-br/PROMPT-IA.md) · 📖 [README](../README.md)

The main [README](../README.md) is written so you can do everything by hand with nothing but Windows. This page is the other option: if you have an AI assistant with terminal access — Claude Code, Codex CLI, Gemini CLI, Cursor, or anything similar — it can handle the fiddly parts for you.

**What it can do:** work out which of the two bricks you have, verify hashes, extract the archive, inspect the USB device state, install the right driver, run the flash, read the output and tell you what failed.

**What it cannot do:** plug the cable in, or look at your TV. Both matter here, and the second matters more than it sounds — see [the rule this repository learned the hard way](#the-rule-this-repository-learned-the-hard-way).

---

## Before anything: which brick do you have?

There are two, they look identical on the TV, and **they need opposite fixes**. The prompt below starts by finding out which one you have. Do not skip that part — an assistant that assumes the wrong one will flash cleanly, report success, and leave you with a device that still does not boot. That is exactly what happened here, and it cost two days.

---

## How to use it

1. Open your assistant with an empty working folder that has at least **6 GB free**.
2. Paste the prompt below.
3. Let it run the diagnosis first. It will tell you which firmware to download.
4. **Read what it proposes before approving anything.** Everything here erases the device; an assistant that misunderstands the situation can waste your one chance. If it suggests a step that is not in this repository, ask it why before saying yes.

---

## The prompt

Copy everything inside the block.

````text
I have a Xiaomi Mi TV Stick 4K, model MDZ-27-AA (codename "soul"), stuck on
the Mi logo. I want to recover it. I am on Windows.

I am following this procedure:
https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery

Read that repository's README.md and docs/android-14-recovery.md first, then
help me carry it out step by step.

STEP ZERO - DIAGNOSE BEFORE DOWNLOADING ANYTHING

There are two different bricks on this device and they need opposite fixes.
Do not assume which one I have. Find out first:

  a) Check the USB bus. A stick in trouble enumerates as one of:
       VID_1B8E&PID_C004   Amlogic, named "DNL"   -> first fastboot stage
       VID_18D1&PID_4EE7   Google                 -> second fastboot stage
     A stick that BOOTS enumerates as VID_18D1&PID_4EE1, named "MiTV-AYFR0".
     If you see 4EE1, the device is running Android and does not need this.

  b) Get into the SECOND fastboot stage and read the bootloader version:
       fastboot reboot bootloader
       fastboot getvar product              -> must say "soul"
       fastboot getvar version-bootloader

     TIMING, and it is not optional: a stick in this state cycles on and off
     the USB bus by itself, roughly 6 s on, 6 s off. Wait until it is ABSENT
     from the bus, THEN start `fastboot reboot bootloader` so it sits at
     "< waiting for any device >" and captures the fresh session when the
     device reappears. Starting fastboot after it is already back gets a dead
     session: "Write to device failed (Unknown error)". If it has stopped
     cycling, ask me to unplug and replug the cable.

     The second stage needs the Google USB Driver (VID_18D1&PID_4EE7); without
     it every command hangs.
     dl.google.com/android/repository/usb_driver_r13-windows.zip

  c) Decide from what you read:

       version-bootloader is 01.01.25xxxx or 01.01.26xxxx, product is "soul"
         -> the bootloader is ANDROID 14
         -> follow docs/android-14-recovery.md
         -> NO Android 11 firmware will ever boot this device. Do not offer it.

       the device was on Android 11 and never took the Android 14 OTA
         -> follow the Android 11 route in README.md

  Tell me which one you found and why, and wait for me to confirm before
  downloading anything.

VERIFIED FACTS YOU CAN RELY ON (from that repository)

  Android 14 fastboot package (for a device with an Android 14 bootloader):
    mi-tv-stick-4k_14_26.6.10_91.7z
    size    989694390 bytes
    sha256  6300f49e9e15ba50e4b6bc9ea7f3243b80178c122b08a440a5e144b8ea6f6711
    md5     45e8daf80b2abd2f0261f5ff24e98b45
    images/super.img       1887436800 bytes
      sha256 075c4e1b589e9fc0da8dc80a992276a74908c07e2fdcfeb68d64915db1b50a23
    images/bootloader.img  4100096 bytes
      sha256 9c4ae84ebd363afc5640ccb1fada3f2387e71556837b574ead840aa7705609c6
    Source: https://disk.yandex.ru/d/9toYWX5hWET-wQ
    If that link is over its public download quota, the same build is on
    Google's own OTA server, always reachable:
      https://android.googleapis.com/packages/ota-api/package/
      4eb355aa75c0fb7fdf79c98d7dc2e4acd4636280.zip   (1044570446 bytes)
    That one is an OTA (payload.bin), not flashable images. The repository has
    tools/payload_dumper.py and tools/monta_super.py to convert it.

  Android 11 DNL package (only for a device that never took the A14 OTA):
    mi-tv-stick-4k_dnl_1440_01.7z
    size    685065929 bytes
    sha256  6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
    md5     ffb220dd62cbff01f6e39461cd0154d1
    DNL identity from `adnl getvar identify`: 06-00-00-10-00-00-00-00
    ADB interface GUID adnl.exe looks for:
      {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}
    super-raw.img after conversion: 1887436800 bytes
      sha256 a514a082631d42e6fae69dd0c4325eb69ee2054f7cebf832b77bb163390913a2

DEAD ENDS - ALREADY TESTED, DO NOT SPEND MY TIME ON THEM

  - `fastboot reboot fastboot` (FastbootD) does NOT start on a broken device.
    FastbootD lives in the recovery ramdisk and needs a valid device tree,
    which is the broken thing. It is circular. Any package whose script needs
    FastbootD - including the "14-to-11" downgrade package - is a dead end.
    The command you want is `reboot bootloader`, not `reboot fastboot`.
  - The `bootloader` and `reserved` partitions REFUSE writes over DNL, tested
    four ways: isolated, inside `oem disk_initial`, and under four different
    partition names. `reserved` holds the device tree; that is why Android 11
    cannot be restored on a device whose bootloader is already Android 14.
  - `flash bootloader` DOES work, but only from the second fastboot stage,
    after `flashing unlock`.

RULES

- Diagnose before you download. Never assume which brick I have.
- Never skip or weaken the DNL identity check (06-00-00-10-00-00-00-00) on the
  Android 11 route. It is what stops the wrong device from being flashed.
- Check hashes before flashing, not after.
- The flash erases everything. Tell me clearly before the point of no return
  and wait for my explicit confirmation.
- If a step fails, show me the exact error output rather than summarising it.
- Do not invent steps that are not in that repository. If something does not
  match what you expected, say so instead of improvising.
- A flash that returns rc=0 on every step is NOT a recovery. Do not tell me it
  worked until the device has actually booted - either on a TV, or by
  enumerating on USB as VID_18D1&PID_4EE1 "MiTV-AYFR0". Until then, say the
  flash completed and the outcome is unverified.
````

---

## The rule this repository learned the hard way

An earlier version of this README stated that the Android 11 procedure recovered the device. It did not. That claim came from a flash log where all 16 steps returned `rc=0`, written up before anyone put the stick on a TV. It then sat on the Mi logo for 1h30, and for another full hour the next day. The device was only recovered two days later, by a different method.

**A green log is not a working device.** It is the single most useful thing to insist on with an assistant, because a clean exit code is exactly the kind of evidence a language model finds persuasive — and on a bricked device, the only evidence that counts is that it boots.

Two ways to check the outcome without guessing:

- **On a TV** — the real test.
- **On USB** — a booted device enumerates as `VID_18D1&PID_4EE1` with the friendly name `MiTV-AYFR0`, which is Android's MTP gadget. A device that did not boot comes back as `VID_1B8E&PID_C004` (DNL). This works without a TV in the room.

---

## If your assistant has no terminal access

A browser-only chat assistant cannot run any of this. It can still help you read Russian forum posts, interpret an error message, or work out whether your symptom matches this procedure at all — but the actual work has to be done by you, following the [README](../README.md).

---

## A note on trust

An AI assistant will do what you ask with more confidence than accuracy. On a device that is already broken, that is a real risk: there is no undo, and a wrong flash can turn a recoverable stick into an unrecoverable one.

Three things worth insisting on:

1. **The diagnosis happens first.** If an assistant proposes a firmware before it has read `version-bootloader`, it is guessing.
2. **The identity check stays.** If it offers to remove it because "the device is not being detected", the answer is no. That check is the reason a mistake stays harmless.
3. **Success means booted, not `rc=0`.** See above.

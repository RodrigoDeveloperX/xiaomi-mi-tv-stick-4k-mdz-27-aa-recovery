# Doing this with an AI assistant

🇧🇷 [Versão em português](pt-br/PROMPT-IA.md) · 📖 [README](../README.md)

The main [README](../README.md) is written so you can do everything by hand with nothing but Windows. This page is the other option: if you have an AI assistant with terminal access — Claude Code, Codex CLI, Gemini CLI, Cursor, or anything similar — it can handle the fiddly parts for you.

**What it can do:** verify hashes, extract the archive, convert the sparse image, inspect the USB device state, apply the registry fix, run the flash, read the output and tell you what failed.

**What it cannot do:** plug the cable in. The ordering rule still applies — the flashing tool must be *waiting* before you connect the stick — so you will be asked to do that part yourself, at the right moment.

---

## How to use it

1. Download `mi-tv-stick-4k_dnl_1440_01.7z` (see the README for sources).
2. Put it in a folder with at least **4 GB free**.
3. Open your assistant with that folder as its working directory.
4. Paste the prompt below.
5. **Read what it proposes before approving anything.** Everything here erases the device; an assistant that misunderstands the situation can waste your one chance. If it suggests a step that is not in the README, ask it why before saying yes.

---

## The prompt

Copy everything inside the block.

````text
I have a Xiaomi Mi TV Stick 4K, model MDZ-27-AA, that is stuck on the boot
screen and will not start. I want to recover it by flashing the stock
firmware RTT0.211222.001.1440 over USB using Amlogic DNL mode.

I am following this procedure:
https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery

Read that repository's README.md first so you have the full context, then
help me carry it out step by step. I am on Windows.

FACTS YOU CAN RELY ON (verified in that repository):

  Firmware archive : mi-tv-stick-4k_dnl_1440_01.7z
  Size             : 685065929 bytes
  SHA-256          : 6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
  MD5              : ffb220dd62cbff01f6e39461cd0154d1

  Device in DNL mode enumerates as USB\VID_1B8E&PID_C004, usually named "DNL"
  Required identity from `adnl getvar identify`: 06-00-00-10-00-00-00-00
  ADB interface GUID adnl.exe searches for: {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}

  super-ab-1440-sparse.img : 1650178104 bytes (Android sparse)
  super-raw.img after conversion : 1887436800 bytes
    SHA-256 a514a082631d42e6fae69dd0c4325eb69ee2054f7cebf832b77bb163390913a2

WHAT I WANT YOU TO DO, IN ORDER:

1. Verify my copy of the .7z: check the size, SHA-256 and MD5 against the
   values above. If anything differs, STOP and tell me - do not continue.

2. Extract it with 7-Zip and confirm the folder contains bin\adnl.exe and
   images\ with 8 .img files.

3. Check the USB state: is a device with hardware ID VID_1B8E&PID_C004
   present, what driver is bound to it, and does its DeviceInterfaceGUIDs
   registry value contain the ADB GUID above? Report what you find and tell
   me what is missing.

4. If the WinUSB driver is missing, tell me to install it with Zadig myself
   and wait - do not try to install drivers on your own.

5. If the ADB interface GUID is missing from DeviceInterfaceGUIDs, add it
   (keeping any existing GUIDs, REG_MULTI_SZ) and restart the device.
   Show me the before and after values. This needs Administrator.

6. Convert images\super-ab-1440-sparse.img to images\super-raw.img and verify
   the result is exactly 1887436800 bytes.

7. Then STOP and hand control back to me for the flash itself, telling me:
     - to unplug the stick,
     - to start the flash script,
     - to plug the stick back in only once it says it is waiting.
   The DNL bootloader only answers in a short window right after USB
   enumeration, so this order is not optional.

RULES:

- Never skip or weaken the identity check (06-00-00-10-00-00-00-00). It is
  what stops the wrong device from being flashed.
- The flash erases everything on the stick. Tell me clearly before the point
  of no return and wait for my explicit confirmation.
- Do not invent steps that are not in that repository's README. If something
  does not match what you expected, say so instead of improvising.
- If a step fails, show me the exact error output rather than summarising it.
- Do not modify or delete my copy of the .7z or the extracted images.
````

---

## If your assistant has no terminal access

A browser-only chat assistant cannot run any of this. It can still help you read Russian forum posts, interpret an error message, or work out whether your symptom matches this procedure at all — but the actual work has to be done by you, following the [README](../README.md).

---

## A note on trust

An AI assistant will do what you ask with more confidence than accuracy. On a device that is already broken, that is a real risk: there is no undo, and a wrong flash can turn a recoverable stick into an unrecoverable one.

The two things worth insisting on:

1. **The identity check stays.** If an assistant offers to remove it because "the device is not being detected", the answer is no. That check is the reason a mistake stays harmless.
2. **Hashes are checked before flashing, not after.** Verification after the fact tells you why it broke; verification before tells you not to break it.

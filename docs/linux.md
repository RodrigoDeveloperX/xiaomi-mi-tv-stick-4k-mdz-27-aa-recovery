# Recovering from Linux

🇧🇷 **[Versão em português](pt-br/linux.md)**

The [Android 14 recovery](android-14-recovery.md) was written and tested on Windows.
This page covers the same procedure on **Linux**, executed for real on
**2026-11-22** (CachyOS, kernel 7.3) on a Mi TV Stick 4K (MDZ-27-AA / `soul`) that was
stuck on the Android TV boot screen after a failed OTA. It booted afterwards.

Same commands, same order, same package. Only the host setup differs.

---

## What is different on Linux

| Windows guide | Linux |
|---|---|
| Google USB Driver, Zadig / WinUSB | nothing to install; one `udev` rule for permissions |
| `fastboot.exe` shipped in the package | use the system `fastboot`, **platform-tools r33.0.3** (see below) |
| the stick cycles on the bus every ~12 s | in our case it appeared **only when the cable was (re)connected**, for ~5 s |

## 1. Host setup

### 1.1 `udev` rule

```
sudo cp tools/51-mi-tv-stick.rules /etc/udev/rules.d/
sudo udevadm control --reload && sudo udevadm trigger
```

It grants access to `1b8e:c004` (Amlogic DNL) and `18d1:4ee7` (2nd-stage fastboot).

### 1.2 Make the kernel catch the DNL — `old_scheme_first`

Before this, the kernel saw the stick but never got past enumeration:

```
usb 3-4: new high-speed USB device number 15 using xhci_hcd
usb 3-4: device descriptor read/all, error -110
```

`lsusb` showed nothing and `fastboot` stayed on `< waiting for any device >`.
The DNL only lives about 5 s, and the default enumeration scheme loses it. Switching
to the old scheme fixed it immediately:

```
echo 1 | sudo tee /sys/module/usbcore/parameters/old_scheme_first
```

This lasts until reboot. For a permanent setting, use the kernel parameter
`usbcore.old_scheme_first=1`.

After it, a reconnect shows:

```
usb 3-4: New USB device found, idVendor=1b8e, idProduct=c004
usb 3-4: Product: DNL
usb 3-4: Manufacturer: Amlogic Inc.
usb 3-4: USB disconnect        # ~5 s later
```

### 1.3 Use platform-tools **r33.0.3**

The `fastboot` 37.0.0 from our distribution captured the DNL and sent
`reboot bootloader`, but never reached the 2nd stage:

```
Rebooting into bootloader    FAILED (Status read failed (No such device))
```

`fastboot` **33.0.3** worked on the first try with the exact same steps
(`Rebooting into bootloader  OKAY`, and the stick stayed on the bus as `18d1:4ee7`).
We did not bisect between the two versions.

```
curl -fLO https://dl.google.com/android/repository/platform-tools_r33.0.3-linux.zip
unzip platform-tools_r33.0.3-linux.zip
./platform-tools/fastboot --version     # fastboot version 33.0.3-8952118
```

The same version is the one reported to work on Windows by
[psyberpunk's write-up](https://github.com/psyberpunk/Xiaomi-Mi-TV-Stick-4K-MDZ-27-AA-Unbrick-Recovery).

### 1.4 No `adb` server

A running `adb` server competes with `fastboot` for the device. Do not run
`adb devices`; if you did, run `adb kill-server` first.

## 2. Reaching the 2nd stage

Because the DNL only exists for a few seconds after connecting, the order is:

1. Unplug the stick from the PC. Power it **from the PC's USB only** (no wall charger, no HDMI).
2. Start **one** `fastboot reboot bootloader`. It sits at `< waiting for any device >`.
3. Plug the stick in. `fastboot` captures the DNL and the stick re-enumerates as
   `18d1:4ee7` (`Product: soul`), where it **stays** until you reboot it.

```
./platform-tools/fastboot reboot bootloader
./platform-tools/fastboot getvar product            # soul
./platform-tools/fastboot getvar is-userspace       # no
./platform-tools/fastboot getvar version-bootloader # 01.01.260610.084506
```

Do not put anything else in that first window: a `getvar all` there used up the
5 s and the following command found no device.

## 3. Flashing

Download and verify the package as described in [Getting the files](android-14-recovery.md#getting-the-files)
(`sha256sum`, then `7z x`).
Then, with the stick in the 2nd stage:

```
tools/go-a14-linux.sh <extracted package folder> ./platform-tools/fastboot
```

The script runs the same commands as `go.cmd`, stops at the first failure and writes a log.
`fastboot -w` erases userdata. It asks for confirmation before starting.

### First boot

Unplug from the PC, power from a wall charger, connect HDMI. On our run Linux saw
`18d1:4ee1` (`MiTV-AYFR0`, MTP) about 2 minutes after `fastboot reboot`, followed by one
restart, which is the first-boot behavior.

## What we did not verify

- `18d1:0d02` (the 2nd-stage ID reported in the Windows write-up) never appeared on Linux; the
  `udev` rule still lists it.
- `tools/go-a14-linux.sh` mirrors the sequence we ran by hand, but was not itself run end to end.
- One device, one host. Other kernels and USB controllers may behave differently.

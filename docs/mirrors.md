# Mirrors for `mi-tv-stick-4k_dnl_1440_01.7z`

This repository does **not** host the firmware. See [Why the firmware is not hosted here](../README.md#why-the-firmware-is-not-hosted-here) — short version: it is proprietary, signed Xiaomi firmware and we have no right to redistribute it.

What we can do is make any copy you find verifiable. Match these and you have the right file, whatever the source:

```
Name    : mi-tv-stick-4k_dnl_1440_01.7z
Size    : 685065929 bytes
SHA-256 : 6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
MD5     : ffb220dd62cbff01f6e39461cd0154d1
```

---

## Known sources

Status as observed in September 2026. Links rot; treat this as a starting point, not a promise.

| Source | URL | Notes |
|---|---|---|
| **Yandex Disk** | <https://disk.yandex.ru/d/CW66IHxzsgpFHA> | The original. Periodically hits its download limit and refuses new downloads. May require a Yandex account, and account creation can fail where SMS verification does not arrive — it did for us, on a Brazilian number. This is the bottleneck that made the file so hard to obtain. |
| **GSMForum** | <https://gsmforum.ru/resources/xiaomi-mi-tv-stick-4k-mdz-27-aa.12470/> | MDZ-27-AA resource page. Registration may be required. |
| **FirmwareDrive** | <https://firmwaredrive.com/index.php?a=downloads&b=folder&id=47997> | Third-party aggregator. |
| **4PDA thread** | <https://4pda.to/forum/index.php?showtopic=1041410> | The primary community thread. Registration required to see attachments. When a mirror dies, this is where a new one usually appears. Mostly Russian. |

### Modified builds (different files, not this one)

[yuliitezarygml/xiaomi-fimware](https://github.com/yuliitezarygml/xiaomi-fimware) publishes two **modified** builds as GitHub Releases — direct download, no registration:

| File | Size | Method | Bootloader unlock |
|---|---:|---|---|
| `MI-TV-STICK-4K_1440_MOD_8.2.7z` | 789,395,886 bytes | DNL | Not required |
| `MI-TV-STICK-4K_1469_MOD_9.7z` | 662,495,411 bytes | fastboot | **Required** |

These are **not** the stock `1440` file and their hashes are different. We did not test either. Its README warns that a factory reset on `1469_MOD_9` locks the bootloader and forces a re-flash. Use them only if the stock file is genuinely unobtainable, and read that repository's own warnings first.

---

## Contributing a mirror

If you have a working source, please open an issue with:

1. **The URL**, and whether registration or an account is needed.
2. **The SHA-256 of the file you actually downloaded from it** — computed yourself, not copied from this page. That is the whole point: a link is only useful if its bytes verify.
3. Roughly when you downloaded it, and any limits you hit.

```powershell
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm SHA256
```

We will add sources that verify. Please do not send links to files whose hash does not match — a different hash means a different file, and for a device that cannot boot, "probably fine" is not good enough.

### What we will not do

- Host the firmware here, in Releases, or through Git LFS. The rights question does not change with the hosting mechanism.
- Link to sources that bundle the firmware with installers, "download managers", or unrelated executables.
- Vouch for any third-party site's safety. We can tell you whether the bytes are the right bytes. Everything else about a mirror is your own judgement call.

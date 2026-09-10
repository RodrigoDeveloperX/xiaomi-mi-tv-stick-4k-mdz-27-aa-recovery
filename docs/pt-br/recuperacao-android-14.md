# Recuperação Android 14 — o método que funcionou de verdade

🇺🇸 **[English version](../android-14-recovery.md)**

Para um **Xiaomi Mi TV Stick 4K (MDZ-27-AA / `soul`)** cuja OTA de Android 11 → 14
falhou no meio, deixando o aparelho parado no logo Mi.

Executado de verdade em **10/09/2026**: 18 etapas, 0 falhas, aparelho bootou.
Saída completa: [`../../logs/successful-flash-a14-2026-09-10.log`](../../logs/successful-flash-a14-2026-09-10.log)

---

## Por que o caminho do Android 11 não funciona aqui

Se a OTA de A14 avançou o suficiente para trocar o bootloader, seu aparelho virou um
híbrido: bootloader e device tree de Android 14, com um userland de Android 11 — ou
pela metade. Gravar a firmware stock 1440 por cima grava sem erro nenhum e continua
não bootando. Confirmado três vezes aqui, incluindo uma hora inteira ligado na TV.

O motivo é que duas partições **recusam escrita** neste aparelho:

| Caminho tentado | Resultado |
|---|---|
| fastboot, 1º estágio | a partição nem existe na tabela (`partition size: 0`) |
| FastbootD (`fastboot reboot fastboot`) | `Failed to boot into userspace fastboot` |
| `adnl partition -p bootloader` / `-p reserved` | `FAILED (remote failure)` |
| o mesmo, dentro de `adnl oem disk_initial` | comando aceito, e então `ERR[DNL]Fail in send data at len 0x20000` e `ERR[DNL]Fail in _command_end` |

O `bootloader` mora na área de boot por hardware do eMMC; a `reserved` guarda a tabela
de partições e o device tree `_aml_dtb` de onde o U-Boot em execução lê. Nenhuma das
duas pode ser substituída pelo DNL.

Há também uma armadilha circular que vale conhecer: **o FastbootD mora no ramdisk de
recovery dentro de `boot`/`vendor_boot`, e precisa de um device tree válido para
subir.** O device tree é justamente o que está quebrado. Ou seja, você não consegue
usar o modo que grava a `reserved`, porque é a `reserved` que está errada. Qualquer
pacote cujo script dependa do FastbootD — inclusive o de downgrade `14-to-11` — é beco
sem saída num aparelho nesse estado.

**Conclusão: não dá para voltar ao Android 11. É preciso ir para frente.**

---

## Os dois estágios do fastboot

Esta é a descoberta mais útil aqui, e não está documentada em português nem em inglês
em lugar nenhum que encontramos.

O aparelho tem **duas implementações diferentes de fastboot**, e quase tudo que serve
está na segunda:

| | 1º estágio | 2º estágio |
|---|---|---|
| id USB | `VID_1B8E&PID_C004` (Amlogic), nome `DNL` | `VID_18D1&PID_4EE7` (Google) |
| `getvar product` | `amlogic` | `soul` |
| `getvar version-bootloader` | `0.1` | ex.: `01.01.260610.084506` |
| `flashing unlock` | *unknown command* | **OKAY** |
| `flash bootloader` | partition size 0 | **OKAY** |
| `set_active` | *unknown command* | **OKAY** |
| `fastboot -w` | não acha as partições | **OKAY**, com `mke2fs` |

Vai-se do primeiro para o segundo com um comando:

```
fastboot reboot bootloader
```

Repare que é `reboot bootloader`, **não** `reboot fastboot`. O `reboot fastboot` pede o
FastbootD (userspace), que não sobe num aparelho quebrado — essa diferença custou dois
dias aqui.

### É preciso o driver USB do Google

O 2º estágio enumera como `VID_18D1&PID_4EE7` e o Windows não tem driver para ele —
aparece com `CM_PROB_FAILED_INSTALL` e todo comando trava ou falha. Instale o
**Google USB Driver**
(`https://dl.google.com/android/repository/usb_driver_r13-windows.zip`), que traz a
entrada exata:

```
%CompositeAdbInterface% = USB_Install, USB\VID_18D1&PID_4EE7
```

`pnputil /add-driver android_winusb.inf /install`. Não mexe no driver DNL da Amlogic.

### Pegando o aparelho: a questão do tempo

Um stick nesse estado **cicla sozinho no barramento USB** — cerca de 6 s presente, 6 s
ausente, período de ~12 s (medido). Não é preciso desconectar nada.

**A ordem importa e não é intercambiável:**

1. espere o aparelho estar **ausente** do barramento
2. **então** rode `fastboot reboot bootloader` — ele fica em `< waiting for any device >`
3. ele captura a sessão nova quando o aparelho reaparece, ~2 s depois

Subir o fastboot *depois* que o aparelho já voltou pega uma sessão morta e devolve
`Write to device failed (Unknown error)`. Se ele parou de ciclar e o link morreu,
desconecte e reconecte o cabo — só a reenumeração física ressuscita.

O `tools/check-usb-mode.ps1` deste repositório diz em que estágio você está.

---

## O que você precisa

- **`mi-tv-stick-4k_14_26.6.10_91.7z`** (~944 MB) — o pacote fastboot oficial de
  Android 14. Veja [Onde conseguir os arquivos](#onde-conseguir-os-arquivos).
- O **Google USB Driver** (acima).
- Windows. O pacote traz o próprio `fastboot.exe`, `mke2fs.exe` e `make_f2fs.exe`.

Prefira a build que casa com o seu bootloader. Leia a sua com
`fastboot getvar version-bootloader` no 2º estágio: `01.01.260610.084506` significa
`V816.0.26.6.10`, então use o pacote `26.6.10`.

---

## O procedimento

O pacote traz o `go.cmd`, e ele está correto — rode. Todos os comandos abaixo são o que
ele faz, na ordem.

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
fastboot -w                                                  # apaga a userdata
fastboot flashing lock
```

**Nenhum passo usa FastbootD.** É exatamente por isso que este funciona onde o pacote
`14-to-11` não funciona.

O `flash super` tem 1,8 GB; o fastboot divide em pedaços esparsos sozinho (11 × 128 MB
aqui, cerca de 2 minutos). O `fastboot -w` apaga e recria a userdata — é um reset de
fábrica, e é proposital.

O `tools/go-a14.sh` deste repositório é uma transcrição fiel do `go.cmd` (conferida
comando a comando, 20 de 20 idênticos) que acrescenta log e a sincronia com o barramento
descrita acima, para não depender de plugar o stick no instante exato.

### Primeiro boot

Tire do PC, alimente com um **carregador de tomada**, HDMI numa TV. Dê até 10 minutos:
o primeiro boot depois de trocar bootloader, `super` inteira e userdata é lento.

Um aparelho que bootou enumera no USB como `VID_18D1&PID_4EE1`, com o nome amigável
`MiTV-AYFR0` — é o gadget MTP do Android, e é um sinal confiável de que o sistema está
rodando mesmo sem uma TV para olhar. Um aparelho que **não** bootou volta como
`VID_1B8E&PID_C004` (DNL).

### Se continuar parado no logo

Volte ao 2º estágio e troque de slot — os dois relatos publicados se contradizem sobre
qual funciona, então teste os dois:

```
fastboot reboot bootloader
fastboot flashing unlock
fastboot set_active b        # ou 'a'
fastboot reboot
```

---

## Onde conseguir os arquivos

### O pacote fastboot (preferencial)

`mi-tv-stick-4k_14_26.6.10_91.7z` — Yandex Disk, do tópico do 4PDA:
`https://disk.yandex.ru/d/9toYWX5hWET-wQ`

Builds Android 14 mais antigas, mesma geração, também servem:

| Arquivo | Link |
|---|---|
| `mi-tv-stick-4k_14_250303_91.7z` (fastboot) | `https://disk.yandex.ru/d/FS_mL28j84U4Lw` |
| `mi-tv-stick-4k_14_250303_01.7z` (DNL) | `https://disk.yandex.ru/d/as4J2_sLatS4ZA` |

O sufixo `_91` indica pacote de fastboot (precisa do driver ADB); `_01` indica pacote
DNL (precisa do driver da Amlogic).

Esses links vivem **acima da cota pública de download**
(`DiskResourceDownloadLimitExceededError`). Esse limite é do arquivo, não seu — máquina
nova ou IP novo não mudam nada. Salvar o arquivo no seu próprio Yandex Disk e baixar de
lá contorna a cota pública.

### Alternativa: a OTA oficial, direto da Google

Se o Yandex estiver bloqueado, os pacotes OTA completos de Android 14 estão hospedados
nos servidores da própria Google e sempre respondem. Prefixe com
`https://android.googleapis.com/packages/ota-api/package/`:

| Build | Arquivo |
|---|---|
| `V816.0.26.6.10` user (a mais nova) | `4eb355aa75c0fb7fdf79c98d7dc2e4acd4636280.zip` |
| `V816.0.26.6.10` userdebug | `3008ec5c880eb220b786f2c431e12d2622ea1f56.zip` |
| `V816.0.26.5.18` user | `981690fca34f874330751411fea24dce9c24894e.zip` |
| `V816.0.26.1.7` user | `00291fa1218a9e1ce7672af44e30510d88d22565.zip` |

São **pacotes OTA** (`payload.bin`), não imagens graváveis. Para converter:

```
python tools/payload_dumper.py <ota>.zip -o out/     # extrai as 16 particoes
python tools/monta_super.py --molde <qualquer super.img> --dir out/ \
       --saida super.img --conferir                  # remonta a super (equivale ao lpmake)
```

O `payload_dumper.py` confere cada partição extraída contra o SHA-256 gravado no
manifesto do payload. O `monta_super.py` existe porque o pacote `liblp` do Python
implementa só leitura; foi validado remontando uma `super.img` de fábrica
**byte a byte idêntica**.

Usamos esse caminho para verificar o pacote do Yandex de forma independente:
`bootloader`, `boot`, `dtbo`, `oem`, `odm_ext` e as oito partições lógicas dentro da
`super.img` são byte a byte idênticas à OTA oficial da Google da mesma build.

---

## Anotações sobre este aparelho

- **Layout da `super`**: `size=1887436800`, `first_logical_sector=2048`,
  `alignment=1 MB`, `metadata_max_size=65536`, 3 slots, `logical_block_size=4096`,
  header v10.2, grupo `amlogic_dynamic_partitions_a`. Os extents são alinhados ao
  `alignment` do block device (1 MB), não ao `logical_block_size`.
- **As seis áreas de metadata alternam `_a` e `_b`** em ordem de arquivo, e as duas
  variantes apontam para os mesmos extents. Isso contraria a convenção do próprio
  liblp (onde o backup do slot N espelha o primário do slot N), mas é o que a imagem
  de fábrica faz.
- **O Android 14 acrescenta três partições lógicas** que a 1440 não tem:
  `system_dlkm`, `vendor_dlkm`, `odm_dlkm`.
- A `super` de Android 14 soma 1.375.821.824 bytes de dados contra um máximo de grupo
  de 1.876.951.040.

---

## Fontes

Tudo que serve sobre este aparelho está no tópico do 4PDA, em russo, atrás de login, e
não indexado em inglês nem em português. Tópico
`4pda.to/forum/index.php?showtopic=1041410`.

| O quê | Post |
|---|---|
| Lista de firmwares, com os avisos de compatibilidade | `127973104` |
| O pacote fastboot Android 14 para desbrickar | `144826494` |
| Links das OTAs Android 14 (Google) | `135711658` |
| Relato de recuperação de brick | `144590518` |
| Mesmo sintoma, resolvido com o pacote A14 + `set_active a` | `144825391` |

É preciso ter conta — os spoilers que guardam os links **não existem no código da
página** para visitante anônimo, e é por isso que várias rodadas de busca não acharam
nada.

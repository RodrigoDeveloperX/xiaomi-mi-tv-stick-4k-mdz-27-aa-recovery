# Recuperação pelo Linux

🇺🇸 **[English version](../linux.md)**

A [recuperação Android 14](recuperacao-android-14.md) foi escrita e testada no Windows.
Esta página cobre o mesmo procedimento no **Linux**, executado de verdade em
**22/11/2026** (CachyOS, kernel 7.3) num Mi TV Stick 4K (MDZ-27-AA / `soul`) que ficou
parado na tela de boot do Android TV depois de uma OTA que falhou. Ele bootou depois.

Mesmos comandos, mesma ordem, mesmo pacote. Só a preparação do host muda.

---

## O que muda no Linux

| Guia do Windows | Linux |
|---|---|
| Google USB Driver, Zadig / WinUSB | nada a instalar; uma regra `udev` para permissão |
| `fastboot.exe` que vem no pacote | usar o `fastboot` do sistema, **platform-tools r33.0.3** (veja abaixo) |
| o stick cicla no barramento a cada ~12 s | no nosso caso ele apareceu **só quando o cabo foi (re)conectado**, por ~5 s |

## 1. Preparação do host

### 1.1 Regra `udev`

```
sudo cp tools/51-mi-tv-stick.rules /etc/udev/rules.d/
sudo udevadm control --reload && sudo udevadm trigger
```

Ela dá acesso ao `1b8e:c004` (Amlogic DNL) e ao `18d1:4ee7` (fastboot do 2º estágio).

### 1.2 Fazer o kernel pegar o DNL — `old_scheme_first`

Antes disso, o kernel via o stick mas nunca passava da enumeração:

```
usb 3-4: new high-speed USB device number 15 using xhci_hcd
usb 3-4: device descriptor read/all, error -110
```

O `lsusb` não mostrava nada e o `fastboot` ficava em `< waiting for any device >`.
O DNL só vive uns 5 s e o esquema de enumeração padrão o perde. Trocar para o esquema
antigo resolveu na hora:

```
echo 1 | sudo tee /sys/module/usbcore/parameters/old_scheme_first
```

Vale até reiniciar. Para deixar permanente, use o parâmetro de kernel
`usbcore.old_scheme_first=1`.

Depois disso, reconectar mostra:

```
usb 3-4: New USB device found, idVendor=1b8e, idProduct=c004
usb 3-4: Product: DNL
usb 3-4: Manufacturer: Amlogic Inc.
usb 3-4: USB disconnect        # ~5 s depois
```

### 1.3 Use o platform-tools **r33.0.3**

O `fastboot` 37.0.0 da nossa distribuição capturava o DNL e enviava
`reboot bootloader`, mas nunca chegava ao 2º estágio:

```
Rebooting into bootloader    FAILED (Status read failed (No such device))
```

O `fastboot` **33.0.3** funcionou de primeira com exatamente os mesmos passos
(`Rebooting into bootloader  OKAY`, e o stick ficou no barramento como `18d1:4ee7`).
Não investigamos qual versão entre as duas introduziu o problema.

```
curl -fLO https://dl.google.com/android/repository/platform-tools_r33.0.3-linux.zip
unzip platform-tools_r33.0.3-linux.zip
./platform-tools/fastboot --version     # fastboot version 33.0.3-8952118
```

É a mesma versão que o [relato do psyberpunk](https://github.com/psyberpunk/Xiaomi-Mi-TV-Stick-4K-MDZ-27-AA-Unbrick-Recovery) diz funcionar no Windows.

### 1.4 Sem servidor `adb`

Um servidor `adb` rodando disputa o aparelho com o `fastboot`. Não rode `adb devices`;
se rodou, faça `adb kill-server` antes.

## 2. Chegando ao 2º estágio

Como o DNL só existe por alguns segundos depois de conectar, a ordem é:

1. Desconecte o stick do PC. Alimente **só pelo USB do PC** (sem fonte de tomada, sem HDMI).
2. Dispare **um único** `fastboot reboot bootloader`. Ele fica em `< waiting for any device >`.
3. Conecte o stick. O `fastboot` captura o DNL e o stick reenumera como
   `18d1:4ee7` (`Product: soul`), onde **permanece** até você reiniciá-lo.

```
./platform-tools/fastboot reboot bootloader
./platform-tools/fastboot getvar product            # soul
./platform-tools/fastboot getvar is-userspace       # no
./platform-tools/fastboot getvar version-bootloader # 01.01.260610.084506
```

Não coloque mais nada nessa primeira janela: um `getvar all` ali gastou os 5 s e o
comando seguinte não encontrou dispositivo.

## 3. Gravação

Baixe e verifique o pacote como em [Onde conseguir os arquivos](recuperacao-android-14.md#onde-conseguir-os-arquivos)
(`sha256sum`, depois `7z x`).
Então, com o stick no 2º estágio:

```
tools/go-a14-linux.sh <pasta do pacote extraído> ./platform-tools/fastboot
```

O script roda os mesmos comandos do `go.cmd`, para na primeira falha e grava um log.
O `fastboot -w` apaga a userdata. Ele pede confirmação antes de começar.

### Primeiro boot

Tire do PC, alimente por fonte de tomada, conecte o HDMI. Na nossa execução o Linux viu
`18d1:4ee1` (`MiTV-AYFR0`, MTP) cerca de 2 minutos depois do `fastboot reboot`,
seguido de uma reinicialização, que é o comportamento do primeiro boot.

## O que não verificamos

- O `18d1:0d02` (ID do 2º estágio citado no relato do Windows) nunca apareceu no Linux; a
  regra `udev` mantém o ID mesmo assim.
- O `tools/go-a14-linux.sh` espelha a sequência que rodamos à mão, mas ele mesmo não foi
  executado de ponta a ponta.
- Um aparelho, um host. Outros kernels e controladoras USB podem se comportar diferente.

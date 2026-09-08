# O `go.cmd` original, transcrito e traduzido

🇺🇸 [English version](../original-go.cmd.md) · 📖 [README em português](../../README-PT-BR.md)

O `go.cmd` vem dentro do `mi-tv-stick-4k_dnl_1440_01.7z`, na raiz da pasta extraída. É um arquivo de lote do Windows de 1.560 bytes escrito em russo, codificado em **CP866** (a página de código OEM russa), para que o console o exiba corretamente.

Ele é reproduzido aqui para referência e atribuição: é a origem da ordem de partições que este repositório segue e da checagem de identidade que protege você de gravar no aparelho errado. O crédito pela sequência vai para quem montou aquele pacote.

```
SHA-256  b278b7e19a4439247bfed5dc8d46e7147fb74e51b6af92cef44c4e2dba817e41
MD5      c294f2f6b3681a52e258490f47a000c1
```

> Esta página transcreve um script de texto de 1,5 KB, para que as pessoas possam entender e auditar o procedimento. A firmware em si não é redistribuída aqui.

---

## Transcrição (texto russo decodificado de CP866)

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

## Tradução das mensagens em russo

| Russo | Português |
|---|---|
| `Прошивка устройства MiTV-AYFR0` | Gravação do dispositivo MiTV-AYFR0 |
| `Будет установлена прошивка RTT0.211222.001.1440` | Será instalada a firmware RTT0.211222.001.1440 |
| `в устройство Xiaomi TV Stick 4K` | no dispositivo Xiaomi TV Stick 4K |
| `Подключите устройство к компьютеру ...` | Conecte o dispositivo ao computador ... |
| `Прошивка невозможна !` | Gravação impossível! |
| `Работа скрипта завершена. Нажмите любую клавишу` | Script finalizado. Pressione qualquer tecla |

---

## O que ele nos diz

**Ele nomeia o aparelho.** O título da janela diz `MiTV-AYFR0`, coincidindo com o `ro.product.model` dentro das imagens. Script e firmware pertencem um ao outro.

**Ele nomeia o build.** `RTT0.211222.001.1440`, coincidindo com o `ro.build.display.id`.

**Ele confere o hardware antes de gravar.** A string de identidade `06-00-00-10-00-00-00-00` precisa estar presente na saída do `adnl getvar identify`, ou o script pula para `:quit` e não grava nada. Esta é a propriedade de segurança mais importante de todo o procedimento, e a nossa versão a mantém inalterada.

**O `oem disk_initial` vem primeiro.** Ele reparticiona o armazenamento e destrói todos os dados do usuário. Tudo o que vem depois depende de ele ter rodado na mesma sessão — gravar o `super` sozinho contra um aparelho não inicializado falha em cerca de 11 ms com `FAILED (remote failure)`.

**Os dois slots são gravados.** Sete imagens, cada uma em `_a` e `_b`. Este é um aparelho A/B.

**O `super` é gravado por último, em modo sparse.** Esta é a única linha que não funcionou para nós:

```bat
bin\adnl partition -p super -f images\super-ab-1440-sparse.img -t sparse
```

Falhou em todas as tentativas, em três portas USB, sempre em `0x20000` bytes:

```
ERR[DNL]Fail in send data at len 0x20000
FAILED (data transfer failure)
```

Converter a imagem para bruta e tirar o `-t sparse` funcionou de primeira e gravou 1,76 GiB em 287 segundos.

---

## Fragilidades que a versão deste repositório resolve

O original é enxuto e faz a coisa certa, mas foi escrito para quem já conhece o procedimento:

- **Ele não para em caso de falha.** Todas as chamadas ao `adnl` rodam incondicionalmente depois da checagem de identidade, então uma gravação de partição que falha passa despercebida e o script mesmo assim termina com "pressione qualquer tecla". O nosso aborta e diz qual etapa falhou.
- **Ele começa imediatamente no duplo clique.** Sem confirmação antes de uma operação que apaga o aparelho. O nosso pergunta duas vezes.
- **Ele não diz nada sobre a ordem de conexão**, que foi o maior obstáculo prático: o `adnl` precisa estar esperando *antes* de o stick ser conectado.
- **Ele assume que você está na pasta certa** e dá uma falha confusa se você não estiver.
- **Ele é em russo**, o que é uma barreira real para a maioria de quem procura isso em português, inglês ou espanhol.

Veja [`tools/flash-dnl.cmd`](../../tools/flash-dnl.cmd). A sequência de comandos, a checagem de identidade e a ordem das partições são idênticas; só o modo de transferência do `super` é diferente.

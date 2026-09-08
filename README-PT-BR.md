# Xiaomi Mi TV Stick 4K MDZ-27-AA — Recuperação / Unbrick

Recuperação de um **Xiaomi Mi TV Stick 4K (MDZ-27-AA)** que estava **travado na tela de boot**, gravando a firmware stock **`RTT0.211222.001.1440`** por USB, usando o modo **DNL** da Amlogic e a ferramenta `adnl`.

🇺🇸 **[Full English version — README.md](README.md)**

---

## ⚠️ Leia isto antes de qualquer coisa

**Isto é o relato de uma recuperação real que deu certo. Não é um produto e não é uma garantia.**

- O aparelho estava **travado na tela de boot** e não iniciava. Depois deste procedimento, voltou a funcionar normalmente.
- Tudo aqui foi **executado de verdade em 08/09/2026**, em um MDZ-27-AA. A saída completa da ferramenta está em [`logs/successful-flash-2026-09-08.log`](logs/successful-flash-2026-09-08.log) — 16 etapas, todas com `rc=0`.
- Isto é publicado como **um apoio de último recurso para quem já está com problema e não encontrou solução em lugar nenhum**. Se o seu stick ainda liga normalmente, você quase certamente não precisa disto.
- **Não nos responsabilizamos por qualquer falha, dano, perda de dados ou aparelho inutilizado** decorrente de alguém seguir estas anotações. Você faz isso por sua conta e risco, no seu próprio hardware, por decisão sua.
- Ninguém pode chamar um procedimento desses de "100% seguro". Ele **apaga o aparelho inteiro**, depende da sua revisão específica de hardware, e uma gravação interrompida no meio deixa o aparelho sem dar boot até que você repita tudo com sucesso.

Se você não está confortável com isso, pare por aqui e procure a garantia ou a assistência técnica.

---

## Índice

- [Isto serve para você?](#isto-serve-para-você)
- [Quando NÃO usar](#quando-não-usar)
- [O que você precisa](#o-que-você-precisa)
- [O arquivo de firmware](#o-arquivo-de-firmware)
- [Verificando o download](#verificando-o-download)
- [Passo a passo](#passo-a-passo)
- [Os três obstáculos que enfrentamos](#os-três-obstáculos-que-enfrentamos-e-como-cada-um-foi-resolvido)
- [Solução de problemas](#solução-de-problemas)
- [O que mudamos em relação ao `go.cmd` original](#o-que-mudamos-em-relação-ao-gocmd-original)
- [Evidências: o que está comprovado e o que não está](#evidências-o-que-está-comprovado-e-o-que-não-está)
- [Alternativas](#alternativas)
- [Usando uma IA no lugar](#usando-uma-ia-no-lugar-claude-code-codex-etc)
- [Referências](#referências)
- [Créditos](#créditos)

---

## Isto serve para você?

### O aparelho

| | |
|---|---|
| Nome comercial | Xiaomi Mi TV Stick 4K / Xiaomi TV Stick 4K |
| **Número do modelo** | **MDZ-27-AA** (impresso no stick e na caixa) |
| Codinome interno | `soul` |
| String de modelo interna | `MiTV-AYFR0` |
| Plataforma do SoC | Amlogic S4 (`ro.board.platform=s4`) |
| Android | Android TV 11 |

O codinome e a string de modelo acima foram lidos **diretamente das imagens de firmware deste pacote** (`ro.product.device=soul`, `ro.product.model=MiTV-AYFR0`), não copiados de fórum. Veja [`docs/pt-br/conteudo-firmware.md`](docs/pt-br/conteudo-firmware.md).

> O SoC normalmente citado para este aparelho é o **Amlogic S905Y4**. A firmware comprova apenas a família da plataforma (`s4`); o número exato da peça vem de especificações públicas, não destes arquivos.

### O sintoma que isto atende

- O stick liga (o LED acende) mas **trava na tela de boot / logo da Xiaomi ou do Android TV**, para sempre ou em loop.
- Ele **não** chega ao sistema, então ADB pela rede não está disponível.
- Ligado ao PC por USB, o Windows o enumera como **`USB\VID_1B8E&PID_C004`**, normalmente com o nome **`DNL`**, muitas vezes com **Código 28 (nenhum driver instalado)**.

Esse último ponto é o teste de verdade. Rode [`tools/check-dnl-device.ps1`](tools/check-dnl-device.ps1) (botão direito → *Executar com PowerShell*) — ele só lê, não altera nada, e diz se o aparelho está em modo DNL e o que está faltando.

> O **modo DNL** é o modo de recuperação USB da Amlogic exposto pelo bootloader de primeiro estágio. Ele funciona mesmo quando mais nada no aparelho funciona, e é exatamente por isso que serve aqui. No nosso caso, o stick se apresentou em modo DNL sozinho ao ser conectado — **não precisamos acioná-lo manualmente e não conseguimos documentar uma forma confiável de forçá-lo**, veja [o que não está comprovado](#evidências-o-que-está-comprovado-e-o-que-não-está).

---

## Quando NÃO usar

Não use este procedimento se:

- **Seu stick ainda dá boot.** Atualize pelo ar (Configurações → Sobre → Atualização do sistema). Gravar não traz nenhum ganho e apaga tudo.
- **Seu modelo não é MDZ-27-AA.** O Mi TV Stick 1080p/FHD (`MDZ-24-AA`) é outro aparelho, com outras partições. Esta firmware não serve para ele.
- **O Windows mostra o aparelho sob `VID_18D1` (Google).** Isso significa que o stick ainda alcança ADB ou fastboot. Você tem caminhos mais fáceis e o DNL é a ferramenta errada.
- **`adnl getvar identify` não retorna `06-00-00-10-00-00-00-00`.** Os scripts daqui abortam sozinhos nesse caso, e você não deve contornar essa checagem.
- **Você só quer tirar propaganda, instalar algo de lado ou "debloatar".** Isto zera o aparelho para o stock; é um procedimento de reparo, não de modificação.

> ### 🔴 Isto apaga tudo
> O primeiro comando da sequência, `oem disk_initial`, **reparticiona o armazenamento interno e destrói todos os dados do usuário** — contas, aplicativos, configurações. Não existe etapa de backup nem como desfazer. Num aparelho que não dá boot normalmente não há o que perder, e essa é a única razão de isso ser aceitável aqui.

---

## O que você precisa

Tudo abaixo roda no **Windows puro**. Não precisa de Git Bash, nem Linux, nem Python (existe uma versão em Python para quem preferir).

### Hardware

| Item | Observações |
|---|---|
| O stick, MDZ-27-AA | |
| **Cabo USB-A → USB-C com dados** | Cabo só de carga nunca vai enumerar. Se o Windows não mostra absolutamente nada, desconfie primeiro do cabo. |
| Um PC com Windows | Windows 10/11. Precisa de direitos de administrador duas vezes: driver e correção no registro. |
| Um **carregador de tomada 5V/1A** | Para o primeiro boot depois da gravação. Veja [Primeiro boot](#passo-5--primeiro-boot). |

Gravamos a imagem inteira por três portas USB diferentes do mesmo PC. A velocidade da porta não fez diferença mensurável na falha que enfrentamos — veja o [obstáculo 3](#obstáculo-3--o-modo-sparse-falhou-todas-as-vezes).

### Software

| Ferramenta | Onde obter | Redistribuída aqui? |
|---|---|---|
| **7-Zip** | <https://www.7-zip.org/> | Não — instale pelo site oficial |
| **Zadig 2.9** | <https://github.com/pbatard/libwdi/releases> | Não — baixe da página oficial de releases |
| **`adnl.exe` v2.6.3** | Vem **dentro do `.7z` da firmware**, em `bin\` | Não — você já recebe junto com a firmware |
| Os scripts em [`tools/`](tools/) | Este repositório | Sim — são nossos, texto puro, leia antes de rodar |

> **Verifique o Zadig você mesmo.** Botão direito em `zadig-2.9.exe` → *Propriedades* → *Assinaturas Digitais*. Tem que estar assinado por **Akeo Consulting** e o Windows tem que reportar a assinatura como válida. A cópia que usamos mostrava exatamente isso.
>
> O `adnl.exe` e as DLLs ao lado dele (`AdbWinApi.dll`, `AdbWinUsbApi.dll`, `libwinpthread-1.dll`) **não têm assinatura digital**. Vêm de dentro de um pacote de firmware distribuído em fóruns, não conseguimos rastreá-los até uma página oficial da Amlogic, e deliberadamente **não** os espelhamos aqui. Os SHA-256 deles estão em [`docs/pt-br/CHECKSUMS.md`](docs/pt-br/CHECKSUMS.md) para que você ao menos confirme que sua cópia é a mesma que foi realmente usada. Passe um antivírus se isso importar para você.

---

## O arquivo de firmware

Este é o arquivo genuinamente difícil de achar, e a principal razão deste repositório existir.

```
mi-tv-stick-4k_dnl_1440_01.7z
```

| Propriedade | Valor |
|---|---|
| **Tamanho** | **685.065.929 bytes** (653,33 MiB) |
| **SHA-256** | `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b` |
| **MD5** | `ffb220dd62cbff01f6e39461cd0154d1` |
| Conteúdo | 13 arquivos, 1.797.634.555 bytes descompactados |
| Build ID | `RTT0.211222.001` |
| Incremental | `1440` |
| Display ID | `RTT0.211222.001.1440 release-keys` |
| Android | 11 |
| Data do build | Sex 24 Nov 10:24:43 CST 2023 |
| Patch de segurança | 05/10/2023 |

Essas propriedades de build foram **extraídas das imagens dentro do arquivo**, não tiradas de post de fórum. `release-keys` significa que esta é uma build oficial assinada pela Xiaomi, não uma modificada.

### O que tem dentro

```
mi-tv-stick-4k_dnl_1440_01/
├── go.cmd                                    1.560 bytes   script original de gravação (russo)
├── bin/
│   ├── adnl.exe                          2.436.809 bytes   Amlogic USB DNL tool V2.6.3, 20/08/2021
│   ├── AdbWinApi.dll                        97.792 bytes
│   ├── AdbWinUsbApi.dll                     62.976 bytes
│   └── libwinpthread-1.dll                 141.538 bytes
└── images/
    ├── boot.img                         67.108.864 bytes
    ├── dtbo.img                          2.097.152 bytes
    ├── odm_ext.img                      16.777.216 bytes
    ├── oem.img                          33.554.432 bytes
    ├── super-ab-1440-sparse.img      1.650.178.104 bytes   imagem Android sparse
    ├── vbmeta.img                            8.192 bytes
    ├── vbmeta_system.img                     4.096 bytes
    └── vendor_boot.img                  25.165.824 bytes
```

SHA-256 de cada um desses arquivos: [`docs/pt-br/CHECKSUMS.md`](docs/pt-br/CHECKSUMS.md).

### Onde baixar

> ### ⬇️ Download direto, sem cadastro
>
> **[mi-tv-stick-4k_dnl_1440_01_MDZ-27-AA.7z](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/releases/download/v1.0-firmware-1440/mi-tv-stick-4k_dnl_1440_01_MDZ-27-AA.7z)** — espelhado nos [Releases](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/releases/latest) deste repositório.
>
> 685.065.929 bytes · SHA-256 `6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b`
>
> Sem conta, sem limite de download, sem espera. É o mesmo pacote que circula como `mi-tv-stick-4k_dnl_1440_01.7z` — só o nome do arquivo muda. **Confira o hash mesmo assim**, daqui ou de qualquer outro lugar.

Outras fontes, caso este espelho seja removido algum dia:

| Fonte | Observações |
|---|---|
| **Yandex Disk** — <https://disk.yandex.ru/d/CW66IHxzsgpFHA> | O link original de onde este arquivo veio. **Ele atinge periodicamente o limite de downloads** e recusa novos; pode exigir conta no Yandex, e o cadastro pode falhar para números de telefone de alguns países (falhou para nós, com número brasileiro). Esta foi a parte mais difícil de toda a recuperação, e a razão de este repositório espelhar o arquivo. |
| **GSMForum** — <https://gsmforum.ru/resources/xiaomi-mi-tv-stick-4k-mdz-27-aa.12470/> | Espelho de material do MDZ-27-AA. Pode exigir cadastro. |
| **FirmwareDrive** — <https://firmwaredrive.com/index.php?a=downloads&b=folder&id=47997> | Agregador de terceiros. |
| **Tópico do 4PDA** — <https://4pda.to/forum/index.php?showtopic=1041410&st=23820> | Onde o arquivo é discutido e onde novos links aparecem quando os espelhos morrem. Exige cadastro para ver anexos. |

**Seja qual for a fonte, confira o SHA-256 antes de gravar.** É exatamente para isso que o hash é publicado: um espelho que você nunca ouviu falar se torna seguro no momento em que os bytes batem.

> **Você pode encontrar este arquivo com um nome um pouco diferente.** Alguns espelhos acrescentam o número do modelo:
>
> ```
> mi-tv-stick-4k_dnl_1440_01.7z            ← nome usado pelas fontes originais
> mi-tv-stick-4k_dnl_1440_01_MDZ-27-AA.7z  ← mesmo arquivo, com o modelo no fim
> ```
>
> **São o mesmo pacote.** Renomear um arquivo não muda o conteúdo dele, então os dois têm que dar o SHA-256 `6a54918c…03b60b`. É o hash que diz se o arquivo está certo; o nome nunca diz.

Se você tem um espelho funcionando, por favor abra uma issue — veja [`docs/pt-br/espelhos.md`](docs/pt-br/espelhos.md).

### Sobre hospedar a firmware aqui

Sendo direto sobre isso, porque é software de outra pessoa.

O `mi-tv-stick-4k_dnl_1440_01.7z` é firmware stock assinada da Xiaomi (`release-keys`). **Ela continua sendo propriedade da Xiaomi.** Não temos direito de redistribuição, não reivindicamos nenhum, e nada neste repositório concede qualquer direito a você. A [licença MIT](LICENSE) cobre a nossa documentação e os nossos scripts — nunca a firmware.

Ainda assim ela está espelhada aqui, por um motivo: a fonte original é um link do Yandex Disk que vive atingindo o limite de downloads, e quem já está com o aparelho morto ficava sem lugar nenhum para conseguir o arquivo. Uma imagem stock de recuperação é a única coisa que traz um MDZ-27-AA de volta, e não existe download oficial da Xiaomi para ela.

- **Finalidade.** Reparo de aparelho e preservação. Não é uma build modificada, nem um contorno, nem nada que libere função que você não pagou — é o software com que o aparelho saiu de fábrica, oferecido a quem tenta fazer o próprio hardware voltar a funcionar.
- **Se a Xiaomi se opuser, sai do ar.** Sem discussão. Abra uma issue ou entre em contato com o dono do repositório e o arquivo será removido.
- **A documentação se sustenta sozinha.** Se o arquivo um dia for retirado, tudo o que torna outra cópia utilizável continua aqui: nome exato, tamanho exato, SHA-256, MD5, estrutura interna, hashes de cada arquivo e o procedimento completo. O [`docs/pt-br/espelhos.md`](docs/pt-br/espelhos.md) existe exatamente para esse cenário.

**Confira o hash independentemente de onde você baixar** — inclusive daqui. É essa a parte que realmente protege você.

---

## Verificando o download

Faça isso **antes** de extrair. Uma firmware truncada ou adulterada gravada num aparelho que já não dá boot é como um stick recuperável vira um irrecuperável.

### PowerShell (já vem no Windows)

Abra a pasta onde está o arquivo, segure **Shift** e clique com o botão direito num espaço vazio → *Abrir janela do PowerShell aqui*, e então:

```powershell
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm SHA256
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm MD5
(Get-Item .\mi-tv-stick-4k_dnl_1440_01.7z).Length
```

### Prompt de Comando (também já vem)

```cmd
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z SHA256
certutil -hashfile mi-tv-stick-4k_dnl_1440_01.7z MD5
```

### Valores esperados

```
Tamanho : 685065929
SHA-256 : 6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
MD5     : ffb220dd62cbff01f6e39461cd0154d1
```

Maiúsculas e minúsculas não importam. **Se qualquer um dos hashes for diferente, não use o arquivo** — baixe de novo, de outra fonte.

---

## Passo a passo

O tempo de mão na massa é curto; a gravação em si levou **5 minutos e 19 segundos** do início ao fim na nossa execução (09:38:01 → 09:43:20 no log).

### Passo 0 — Extrair a firmware

Botão direito no `.7z` → *7-Zip* → *Extrair aqui*. Você obtém a pasta `mi-tv-stick-4k_dnl_1440_01`, contendo `go.cmd`, `bin\` e `images\`.

Copie os scripts da pasta [`tools/`](tools/) deste repositório **para dentro dessa mesma pasta**, ao lado do `go.cmd`. É onde eles esperam estar.

Você precisa de aproximadamente **4 GB livres**: o arquivo compactado, as imagens extraídas e a imagem `super` convertida.

### Passo 1 — Instalar o driver WinUSB (uma vez por PC)

Só é necessário na primeira vez que você faz isso num determinado computador.

1. Conecte o stick ao PC. O Windows vai mostrá-lo no Gerenciador de Dispositivos, normalmente como **`DNL`** com um triângulo amarelo (*Código 28 — Os drivers deste dispositivo não estão instalados*).
2. Execute o **`zadig-2.9.exe` como Administrador**.
3. Menu **Options → List All Devices**.
4. Na lista suspensa, selecione a entrada chamada **`DNL`**.
5. **Confirme que o Zadig mostra `USB ID  1B8E  C004`.** Se mostrar outra coisa, você está com o dispositivo errado selecionado — não instale, ou vai substituir o driver de algum hardware que nada tem a ver.
6. Escolha **WinUSB** como driver de destino e clique em **Install Driver**.

O Zadig instala como um `oemNN.inf` (`oem76.inf` no nosso caso), derivado do `dnl.inf`, provedor `libwdi`.

> O `android_winusb.inf` que circula em repositórios relacionados **não funciona** aqui. Ele só declara entradas para VID `18D1` (Google) e não tem nada para `1B8E` (Amlogic).

### Passo 2 — Corrigir o GUID de interface (uma vez por PC)

**Faça isso mesmo que o driver pareça perfeitamente instalado.** Sem isso, o `adnl.exe` fica em `< waiting for Amlogic DNL device >` para sempre, enquanto o Gerenciador de Dispositivos mostra um dispositivo saudável. Este é o [obstáculo 2](#obstáculo-2--o-guid-de-interface-incompatível) e não é nada óbvio.

Botão direito em [`tools/fix-adnl-guid.ps1`](tools/fix-adnl-guid.ps1) → **Executar com PowerShell**. Ele se eleva sozinho a Administrador, encontra o dispositivo DNL pelo hardware ID e acrescenta o GUID de interface do ADB que o `adnl.exe` procura. Pode ser rodado mais de uma vez sem problema e não faz nada se não houver dispositivo DNL presente.

Depois rode [`tools/check-dnl-device.ps1`](tools/check-dnl-device.ps1) para confirmar que está tudo verde.

> Se o PowerShell se recusar a rodar o script, botão direito nele → *Propriedades* → marque **Desbloquear** → *OK*. Isso é a proteção do Windows para arquivos baixados da internet, não um erro do script.

### Passo 3 — Converter o `super` para imagem bruta

O pacote traz `images\super-ab-1440-sparse.img` no formato Android sparse. Gravá-lo em modo sparse **falhou em todas as tentativas** aqui — veja o [obstáculo 3](#obstáculo-3--o-modo-sparse-falhou-todas-as-vezes). Converter para imagem bruta e gravar em modo normal funcionou de primeira.

Abra o PowerShell na pasta da firmware extraída e rode:

```powershell
.\simg2img.ps1 .\images\super-ab-1440-sparse.img .\images\super-raw.img
```

Saída esperada:

```
sparse v1.0  block=4096  blocks=460800  chunks=148
raw output will be 1,887,436,800 bytes (1.76 GiB)
...
wrote 1,887,436,800 bytes
size matches the sparse header. Conversion OK.
```

`1.650.178.104 bytes → 1.887.436.800 bytes`. Leva alguns minutos e precisa de 1,8 GB livres.

> O [`tools/simg2img.ps1`](tools/simg2img.ps1) é PowerShell puro — não precisa instalar nada. Foi verificado que ele produz saída **byte a byte idêntica** à implementação de referência em Python ([`tools/simg2img.py`](tools/simg2img.py)) nos quatro tipos de chunk: RAW, FILL, DONT_CARE e CRC32. Use o que preferir; o de Python exige Python instalado.

### Passo 4 — Gravar

> ### 🔴 Ponto sem volta
> O primeiro comando apaga o aparelho. Daqui até o fim do `super`, **não desconecte nada**. Se for interrompido, o stick não vai dar boot até você repetir toda a sequência com sucesso — não dá para consertar gravando só o `super`.

**A ordem importa mais do que qualquer outra coisa aqui.**

1. **Desconecte o stick do PC.** Confirme que ele sumiu do Gerenciador de Dispositivos.
2. Dê duplo clique em **[`flash-dnl.cmd`](tools/flash-dnl.cmd)** (dentro da pasta da firmware extraída).
3. Confirme as duas perguntas. Ele vai imprimir `Waiting for an Amlogic DNL device...` e ficar parado ali.
4. **Agora** conecte o stick. A gravação engata em alguns segundos.
5. Não encoste em nada até aparecer `DONE`.

<!-- -->

> ### ⚠️ O `adnl` precisa estar rodando *antes* de o stick ser conectado
> O bootloader DNL responde apenas numa janela curta logo após a enumeração USB. Depois disso ele continua energizado e visível no Gerenciador de Dispositivos, mas para de atender.
>
> | Ordem | Tentativas | Resultado |
> |---|---|---|
> | Ferramenta esperando primeiro, stick conectado depois | 3 | Identidade respondida em **0,001 s** nas três |
> | Stick já conectado, ferramenta iniciada depois | 3 | Estourou o tempo em 113 s, 121 s e 192 s |
>
> Seis tentativas, uma variável, correlação perfeita. O LED não diz nada sobre isso — ele acende igual nos dois casos.

Antes de gravar qualquer coisa, o script confere a identidade do hardware e aborta se não bater:

```
DNL mode [TPL]	06-00-00-10-00-00-00-00
```

**Não remova essa checagem.** É ela que impede você de gravar firmware de Mi TV Stick em outro aparelho Amlogic qualquer.

#### A sequência que ele executa

```
oem disk_initial                    ← apaga e reparticiona tudo
dtbo_a          / dtbo_b            ← images/dtbo.img
oem_a           / oem_b             ← images/oem.img
odm_ext_a       / odm_ext_b         ← images/odm_ext.img
vbmeta_a        / vbmeta_b          ← images/vbmeta.img
vbmeta_system_a / vbmeta_system_b   ← images/vbmeta_system.img
vendor_boot_a   / vendor_boot_b     ← images/vendor_boot.img
boot_a          / boot_b            ← images/boot.img
super                               ← images/super-raw.img   (por último, ~5 min)
```

Sete imagens, nos dois slots A e B, e então o `super`. Essa é a ordem do `go.cmd` original, sem alteração.

#### O que você deve ver

Cada etapa imprime um `OKAY` e um tempo total. Durações observadas no nosso log:

| Etapa | Tamanho | Tempo |
|---|---|---|
| `oem disk_initial` | — | 0,14 s |
| `dtbo_a` / `dtbo_b` | 2 MB cada | ~0,19 s cada |
| `oem_a` / `oem_b` | 32 MB cada | ~3,25 s cada |
| `odm_ext_a` / `odm_ext_b` | 16 MB cada | ~1,63 s cada |
| `vbmeta_*`, `vbmeta_system_*` | 8 KB / 4 KB | instantâneo |
| `vendor_boot_a` / `_b` | 24 MB cada | ~2,45 s cada |
| `boot_a` / `boot_b` | 64 MB cada | ~6,6 s cada |
| **`super`** | **1800 MB** | **287,46 s (~4 min 47 s)** |

O `super` mostra um contador de porcentagem que anda devagar. Ele está trabalhando. Não mexa.

### Passo 5 — Primeiro boot

1. Desconecte o stick do PC.
2. Ligue-o na porta HDMI da TV e alimente por um **carregador de tomada 5V/1A**, não pela porta USB da TV.
3. Espere. O **primeiro boot leva de 5 a 10 minutos**, boa parte com tela preta ou logo parado.
4. Não corte a energia nesse período.

> **Por que o carregador importa.** O stick é especificado para 5V/1A. Uma porta USB de TV ou monitor costuma entregar só 500 mA. O primeiro boot depois de uma gravação é o momento de pico de consumo — otimização de aplicativos mais escrita pesada na eMMC — e é exatamente aí que a alimentação insuficiente aparece. Use um carregador de verdade pelo menos nesse primeiro boot.

Depois que subir, ele pega as atualizações OTA oficiais sozinho pelo Wi-Fi. Você não precisa gravar nada por cabo de novo.

> **Reset de fábrica é seguro nesta firmware.** O aviso muito repetido de que um reset de fábrica trava o bootloader e obriga a regravar vale para a build **modificada `1469_MOD_9`**, que exige bootloader destravado. Esta aqui é stock, assinada pela Xiaomi, com bootloader travado — reset é operação normal.

---

## Os três obstáculos que enfrentamos, e como cada um foi resolvido

Nenhum deles tem a ver com a firmware em si. Cada um custou tempo real e nenhum está documentado em lugar óbvio, que é boa parte do motivo deste repositório existir.

### Obstáculo 0 — conseguir o arquivo

Antes de qualquer problema técnico: a firmware existia num único link do Yandex Disk que havia **atingido o limite de downloads**, e criar uma conta no Yandex para contornar isso falhou porque a verificação por SMS nunca chegou para um número brasileiro. É isso que os hashes deste repositório resolvem para a próxima pessoa — qualquer espelho se torna utilizável assim que os bytes conferem.

### Obstáculo 1 — sem driver (Código 28)

O Windows via `USB\VID_1B8E&PID_C004` com o nome `DNL`, mas com `CM_PROB_FAILED_INSTALL`.

**Solução:** Zadig → *Options → List All Devices* → selecionar `DNL` → **WinUSB** → *Install Driver*, como Administrador. Coberto no [Passo 1](#passo-1--instalar-o-driver-winusb-uma-vez-por-pc).

### Obstáculo 2 — o GUID de interface incompatível

Com o driver instalado e o Gerenciador de Dispositivos sem erro nenhum, o `adnl` continuava imprimindo `< waiting for Amlogic DNL device >` indefinidamente.

**Causa:** o Zadig registra um GUID de interface **gerado aleatoriamente**. O `adnl.exe` procura o dispositivo pelo GUID de interface do **ADB**, que está compilado dentro do binário. As duas metades funcionavam corretamente; simplesmente nunca se enxergavam.

```
Zadig registrou   : {915C1867-BE44-4EE1-835B-E1D764786AE1}   (aleatório, muda a cada instalação)
adnl.exe procura  : {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}   (GUID de interface do ADB)
```

**Solução:** acrescentar o GUID do ADB em `DeviceInterfaceGUIDs` (tipo `REG_MULTI_SZ`), mantendo o do Zadig, e reiniciar o dispositivo para o Windows reler:

```
HKLM\SYSTEM\CurrentControlSet\Enum\USB\VID_1B8E&PID_C004\<serial>\Device Parameters
    DeviceInterfaceGUIDs = {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}
                           {915C1867-BE44-4EE1-835B-E1D764786AE1}
```

O [`tools/fix-adnl-guid.ps1`](tools/fix-adnl-guid.ps1) faz exatamente isso, encontrando o seu dispositivo automaticamente.

### Obstáculo 3 — o modo sparse falhou todas as vezes

As 14 partições pequenas gravaram sem nenhum problema. O `super` falhou **todas as vezes**, sempre de forma idêntica:

```
ERR[DNL]Fail in send data at len 0x20000
FAILED (data transfer failure)
```

Quatro tentativas, três portas USB diferentes, sempre em **0x20000 (128 KB)**, sempre por volta de 5,3 segundos. As portas tinham velocidades bem distintas e isso não mudou nada — o que descartou cabo, porta e controlador.

**Causa:** o `super` era a única partição gravada com `-t sparse`. As 14 que funcionaram usavam modo normal.

**Solução:** converter a imagem sparse para bruta e gravar em modo normal.

```powershell
.\simg2img.ps1 .\images\super-ab-1440-sparse.img .\images\super-raw.img
```
```
adnl partition -p super -f images\super-raw.img        ← repare: sem -t sparse
```

1,76 GiB gravados em 287 segundos, sem uma única retransmissão.

---

## Solução de problemas

### O Windows não mostra nada quando conecto o stick

- Tente outro **cabo USB** — muitos cabos USB-C são só de carga e não têm as linhas de dados.
- Tente outra porta USB, de preferência diretamente na placa-mãe, e não num hub ou painel frontal.
- Se o stick aparecer sob **`VID_18D1`**, ele está em modo ADB ou fastboot, não DNL — este procedimento não se aplica a você.

### O `DNL` aparece com triângulo amarelo / Código 28

Falta o driver. Isso é o [Passo 1](#passo-1--instalar-o-driver-winusb-uma-vez-por-pc).

### O `< waiting for Amlogic DNL device >` nunca termina

Em ordem de probabilidade:

1. **A correção do GUID não foi aplicada.** Rode o [`tools/fix-adnl-guid.ps1`](tools/fix-adnl-guid.ps1). Foi o nosso caso e é invisível pelo Gerenciador de Dispositivos.
2. **Ordem errada.** O stick tem que ser conectado *depois* que a ferramenta já está esperando. Desconecte, reinicie o script, conecte de novo.
3. **O driver não é WinUSB.** Rode o [`tools/check-dnl-device.ps1`](tools/check-dnl-device.ps1) — ele informa qual driver está vinculado.
4. **A janela do DNL fechou.** Se o stick está conectado há um tempo, desconecte e comece de novo.

### `ERR[DNL]Fail in send data at len 0x20000` / `FAILED (data transfer failure)`

Quase certamente é o `super` em modo sparse. Converta para bruto — [Passo 3](#passo-3--converter-o-super-para-imagem-bruta). Se acontecer numa partição *pequena*, desconfie do cabo.

### `FAILED (remote failure)` em cerca de 11 ms ao gravar só o `super`

O `super` não pode ser gravado sozinho. O `oem disk_initial` precisa rodar na **mesma sessão**, imediatamente antes. Rode o script inteiro de novo.

### A gravação falhou no meio e agora o stick está morto

Esperado, e recuperável. O `oem disk_initial` apagou tudo, então é claro que ele não dá boot. Corrija o que falhou e **rode a sequência completa de novo, do começo**. Ele não está mais quebrado do que já estava.

### A checagem de identidade falha / o script aborta antes de gravar

Isso é a proteção fazendo o trabalho dela. O `adnl getvar identify` retornou algo diferente de `06-00-00-10-00-00-00-00`. Ou o aparelho não é um MDZ-27-AA em modo DNL, ou o `adnl` nunca estabeleceu comunicação de verdade. Não desative a checagem.

### A gravação deu certo mas o stick continua sem dar boot

- Dê os **10 minutos** completos de primeiro boot antes de concluir qualquer coisa.
- Alimente por um **carregador de tomada**, não pela USB da TV. Essa é uma causa realmente comum.
- Teste outra porta e outro cabo HDMI, para descartar o caminho de vídeo.

### O PowerShell não executa os arquivos `.ps1`

Botão direito no arquivo → *Propriedades* → marque **Desbloquear** → *OK*. Se ainda assim recusar, abra o PowerShell como Administrador e rode explicitamente:

```powershell
powershell -ExecutionPolicy Bypass -File .\fix-adnl-guid.ps1
```

---

## O que mudamos em relação ao `go.cmd` original

O `go.cmd` que vem dentro do pacote é em russo e faz essencialmente a coisa certa. Uma transcrição com tradução está em [`docs/pt-br/go.cmd-original.md`](docs/pt-br/go.cmd-original.md).

O nosso [`flash-dnl.cmd`](tools/flash-dnl.cmd) mantém a mesma ordem de partições e a mesma checagem de identidade, e difere exatamente nestes pontos:

| | `go.cmd` original | Este repositório |
|---|---|---|
| Imagem do `super` | `super-ab-1440-sparse.img` com `-t sparse` | `super-raw.img` em modo normal — **a única mudança funcional** |
| Tratamento de erro | Continua depois de uma etapa falhar | Aborta na hora e diz qual etapa falhou |
| Confirmação | Nenhuma — começa no duplo clique | Pergunta duas vezes antes de apagar qualquer coisa |
| Checagem de pasta | Nenhuma | Verifica antes se `bin\` e `images\` estão presentes |
| Idioma | Russo (CP866) | Inglês |
| Orientação | Nenhuma | Explica a ordem de conexão e o que significa uma falha |

A checagem de identidade, a sequência de comandos e a ordem das partições estão **inalteradas**. Não inventamos um procedimento; corrigimos um modo de transferência e acrescentamos proteções.

---

## Evidências: o que está comprovado e o que não está

Ser explícito nisso importa — seguir uma instrução escrita com confiança mas errada é como um aparelho recuperável vira sucata.

### Comprovado pelos arquivos deste repositório

- O tamanho exato, SHA-256 e MD5 do `mi-tv-stick-4k_dnl_1440_01.7z` e de cada arquivo dentro dele.
- O conteúdo completo do pacote (13 arquivos) e sua estrutura interna.
- Identidade do build lida direto das imagens: `ro.build.display.id=RTT0.211222.001.1440 release-keys`, `ro.build.id=RTT0.211222.001`, `ro.build.version.incremental=1440`, `ro.build.version.release=11`, `ro.build.version.security_patch=2023-10-05`, `ro.build.date=Fri Nov 24 10:24:43 CST 2023`.
- Identidade do aparelho lida direto das imagens: `ro.product.device=soul`, `ro.product.model=MiTV-AYFR0`, `ro.product.brand=Xiaomi`, `ro.board.platform=s4`.
- A imagem `super` é um contêiner de partições dinâmicas do Android, metadata LP v10.2, blocos lógicos de 4096 bytes, contendo `system_a`, `vendor_a`, `product_a`, `odm_a`, `system_ext_a`.
- A sequência completa de comandos que funcionou e o tempo exato de cada etapa, em [`logs/successful-flash-2026-09-08.log`](logs/successful-flash-2026-09-08.log): 16 etapas, todas `rc=0`, 09:38:01 → 09:43:20.
- A string de identidade `06-00-00-10-00-00-00-00` e a versão da ferramenta `Amlogic USB DNL tool: V[2.6.3] at Aug 20 2021`.
- O `super` gravado a partir de imagem **bruta** em modo normal completou em 287,46 s.
- O [`tools/simg2img.ps1`](tools/simg2img.ps1) produz saída byte a byte idêntica à referência em Python nos quatro tipos de chunk sparse (verificado contra uma imagem sintética cobrindo RAW, FILL, DONT_CARE e CRC32).

### Em primeira mão, da sessão de recuperação, mas fora do log anexado

O log anexado registra apenas a execução bem-sucedida. Estes vêm das anotações feitas durante a sessão:

- A assinatura da falha em modo sparse (`ERR[DNL]Fail in send data at len 0x20000`, quatro tentativas, três portas, sempre em 0x20000 e ~5,3 s).
- O resultado sobre a ordem de conexão (3 sucessos esperando-primeiro contra 3 timeouts conectado-primeiro).
- O GUID incompatível e o GUID específico gerado pelo Zadig que foi observado.
- `FAILED (remote failure)` em ~11 ms ao gravar o `super` sem o `oem disk_initial` na mesma sessão.
- O primeiro boot levando de 5 a 10 minutos.

### De fontes externas, não verificado aqui

- O SoC ser especificamente o **Amlogic S905Y4** (a firmware só comprova a família de plataforma `s4`).
- A especificação de 5V/1A (etiqueta do aparelho e especificações públicas).
- Tudo a respeito das builds modificadas `1440_MOD_8.2` e `1469_MOD_9`, incluindo a afirmação de que um reset de fábrica na `1469_MOD_9` trava o bootloader — tirado do README do [yuliitezarygml/xiaomi-fimware](https://github.com/yuliitezarygml/xiaomi-fimware). **Não testamos essas builds.**

### 🟡 Não estabelecido — cuidado aqui

- **Como forçar o modo DNL sob demanda.** O nosso stick se apresentou em modo DNL sozinho ao ser conectado. Nunca precisamos acioná-lo, então não podemos documentar uma combinação de botões ou curto de pinos, e **não vamos chutar uma**. Se o seu stick não enumera como `VID_1B8E&PID_C004`, este procedimento não tem ponto de entrada para você, e o tópico do 4PDA é o lugar para perguntar.
- **Se o modo sparse falha universalmente.** Falhou de forma consistente no nosso host, em três portas, mas não podemos afirmar se a causa é a build do `adnl`, o bootloader, a pilha USB do host ou aquela imagem sparse específica. O modo bruto é uma solução de contorno, não um diagnóstico.
- **Se gravar apenas o slot A dentro do `super` é suficiente em geral.** A metadata LP só declara partições `_a`, e o aparelho dá boot — mas não testamos o efeito de uma troca de slot depois disso.
- **Se esta firmware serve para toda revisão de hardware do MDZ-27-AA.** Um aparelho, um sucesso. A checagem de identidade é a sua proteção, não os nossos testes.
- **A procedência do `adnl.exe`.** Não é assinado e não conseguimos rastreá-lo até uma distribuição oficial da Amlogic. Sabemos apenas o SHA-256 da cópia que funcionou.

---

## Alternativas

Se o arquivo stock `1440` estiver realmente inacessível, o [yuliitezarygml/xiaomi-fimware](https://github.com/yuliitezarygml/xiaomi-fimware) publica duas builds **modificadas** como GitHub Releases, com download direto e sem cadastro:

| Arquivo | Tamanho | Método | Bootloader destravado | Dados |
|---|---|---|---|---|
| `MI-TV-STICK-4K_1440_MOD_8.2.7z` | 789.395.886 bytes | DNL | Não exige | Preservados (segundo o README de lá) |
| `MI-TV-STICK-4K_1469_MOD_9.7z` | 662.495.411 bytes | fastboot | **Exige** | Apagados |

> ⚠️ As duas são **modificadas, não stock**. O README de lá afirma que na `1469_MOD_9` um **reset de fábrica trava o bootloader** e obriga a gravar de novo para o aparelho voltar a funcionar. Não testamos nenhuma das duas — trate como plano B, não como primeira escolha, e leia os avisos daquele repositório.

---

## Usando uma IA no lugar (Claude Code, Codex, etc.)

Tudo acima foi escrito para ser feito na mão, apenas com o que já vem no Windows. Se você tiver um assistente de IA com acesso ao terminal, ele consegue conduzir a maior parte — conferir hashes, converter, diagnosticar o estado do USB, ler a saída.

Um prompt pronto está em **[`docs/pt-br/PROMPT-IA.md`](docs/pt-br/PROMPT-IA.md)**. Cole no assistente, na pasta onde você extraiu a firmware.

O assistente ainda não consegue conectar o cabo por você, e a regra de ordem do [Passo 4](#passo-4--gravar) continua valendo.

---

## Referências

Fontes consultadas durante esta recuperação. O tópico do 4PDA é a principal fonte comunitária para este aparelho; quase tudo em russo e exige cadastro para ver anexos.

- 4PDA — tópico principal, Xiaomi Mi TV Stick 4K: <https://4pda.to/forum/index.php?showtopic=1041410>
- 4PDA — referência à firmware: <https://4pda.to/forum/index.php?showtopic=1041410&st=23820>
- 4PDA — discussão sobre limite/indisponibilidade: <https://4pda.to/forum/index.php?showtopic=1041410&st=37200>
- 4PDA — outras versões e métodos: <https://4pda.to/forum/index.php?showtopic=1041410&st=32600>
- 4PDA — caminho por fastboot: <https://4pda.to/forum/index.php?showtopic=1041410&st=19540>
- 4PDA — relato relacionado à build 1407: <https://4pda.to/forum/index.php?showtopic=1041410&st=28380>
- Yandex Disk — link original da firmware: <https://disk.yandex.ru/d/CW66IHxzsgpFHA>
- GitHub — yuliitezarygml/xiaomi-fimware (builds modificadas): <https://github.com/yuliitezarygml/xiaomi-fimware>
- GSMForum — dump do MDZ-27-AA: <https://gsmforum.ru/resources/xiaomi-mi-tv-stick-4k-mdz-27-aa.12470/>
- FirmwareDrive — pasta 47997: <https://firmwaredrive.com/index.php?a=downloads&b=folder&id=47997>
- Zadig / libwdi releases: <https://github.com/pbatard/libwdi/releases>
- 7-Zip: <https://www.7-zip.org/>
- Formato de imagem sparse do AOSP: <https://android.googlesource.com/platform/system/core/+/refs/heads/main/libsparse/include/sparse/sparse.h>

---

## Créditos

- A **comunidade do 4PDA**, que manteve este aparelho vivo e hospedou a firmware por anos.
- Quem subiu o `mi-tv-stick-4k_dnl_1440_01.7z` no **Yandex Disk** — incluindo o `go.cmd` original, cuja sequência de comandos este procedimento segue.
- **[yuliitezarygml](https://github.com/yuliitezarygml)** por espelhar builds alternativas abertamente.
- **[Pete Batard / Akeo](https://github.com/pbatard/libwdi)** pelo Zadig, sem o qual a etapa do driver seria bem mais difícil.
- **Amlogic** pela ferramenta `adnl` incluída no pacote.

Escrito depois de uma recuperação bem-sucedida em 08/09/2026.

---

## Licença

A **documentação e os scripts em [`tools/`](tools/)** deste repositório são publicados sob a [Licença MIT](LICENSE).

Este repositório **não contém firmware, nem binários proprietários, nem ferramentas de terceiros redistribuídas**. A firmware da Xiaomi, o `adnl.exe` e o Zadig continuam sendo propriedade de seus respectivos donos e são referenciados por link, não copiados.

## Isenção de responsabilidade

Fornecido como está, sem garantia de qualquer natureza. **Não assumimos nenhuma responsabilidade por danos, perda de dados, gravação malsucedida ou aparelho permanentemente inutilizado** decorrentes do uso destas informações. Gravar firmware por USB pode inutilizar o hardware e anula a garantia. Este é o registro do que funcionou uma vez, em um aparelho, oferecido a quem já esgotou as outras opções. Você segue inteiramente por sua conta e risco.

---

<sub>Palavras-chave para busca: MDZ-27-AA, MDZ 27 AA firmware, MDZ-27-AA unbrick, MDZ-27-AA recovery, Xiaomi Mi TV Stick 4K brickado, Xiaomi TV Stick 4K firmware, mi-tv-stick-4k_dnl_1440_01, mi-tv-stick-4k_dnl_1440_01.7z, RTT0.211222.001.1440, Xiaomi TV Stick 4K DNL, Xiaomi TV Stick 4K recuperação, adnl, modo DNL Amlogic, MiTV-AYFR0, soul, travado na tela de boot, travado no logo.</sub>

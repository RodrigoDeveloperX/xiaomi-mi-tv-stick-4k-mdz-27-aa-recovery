# Fazendo isto com uma IA

🇺🇸 [English version](../AI-ASSISTANT-PROMPT.md) · 📖 [README](../../README-PT-BR.md)

O [README](../../README-PT-BR.md) principal foi escrito para você fazer tudo à mão, só com o Windows. Esta página é a outra opção: se você tem uma IA com acesso ao terminal — Claude Code, Codex CLI, Gemini CLI, Cursor ou similar — ela pode cuidar das partes chatas.

**O que ela consegue fazer:** descobrir qual dos dois bricks é o seu, conferir hashes, extrair o arquivo, inspecionar o estado do dispositivo USB, instalar o driver certo, rodar a gravação, ler a saída e te dizer o que falhou.

**O que ela não consegue:** plugar o cabo, nem olhar para a sua TV. As duas coisas importam aqui, e a segunda importa mais do que parece — veja [a regra que este repositório aprendeu do jeito difícil](#a-regra-que-este-repositório-aprendeu-do-jeito-difícil).

---

## Antes de tudo: qual brick é o seu?

São dois, idênticos por fora, e **pedem curas opostas**. O prompt abaixo começa descobrindo qual é o seu. Não pule essa parte — uma IA que assumir o errado vai gravar sem nenhum erro, relatar sucesso, e te deixar com um aparelho que continua não bootando. Foi exatamente o que aconteceu aqui, e custou dois dias.

---

## Como usar

1. Abra a IA com uma pasta de trabalho vazia com pelo menos **6 GB livres**.
2. Cole o prompt abaixo.
3. Deixe ela fazer o diagnóstico primeiro. Ela vai te dizer qual firmware baixar.
4. **Leia o que ela propõe antes de aprovar.** Tudo aqui apaga o aparelho; uma IA que entender a situação errada pode desperdiçar a sua única chance. Se ela sugerir um passo que não está neste repositório, pergunte por quê antes de dizer sim.

---

## O prompt

Copie tudo dentro do bloco.

````text
Tenho um Xiaomi Mi TV Stick 4K, modelo MDZ-27-AA (codinome "soul"), parado no
logo Mi. Quero recuperá-lo. Estou no Windows.

Estou seguindo este procedimento:
https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery

Leia o README-PT-BR.md e o docs/pt-br/recuperacao-android-14.md desse
repositório primeiro, e então me ajude a executar passo a passo.

PASSO ZERO - DIAGNOSTICAR ANTES DE BAIXAR QUALQUER COISA

Existem dois bricks diferentes neste aparelho e eles pedem curas opostas.
Nao assuma qual e' o meu. Descubra primeiro:

  a) Verifique o barramento USB. Um stick com problema enumera como um destes:
       VID_1B8E&PID_C004   Amlogic, nome "DNL"   -> primeiro estagio do fastboot
       VID_18D1&PID_4EE7   Google                -> segundo estagio do fastboot
     Um stick que BOOTA enumera como VID_18D1&PID_4EE1, nome "MiTV-AYFR0".
     Se voce ver 4EE1, o aparelho esta rodando Android e nao precisa disto.

  b) Entre no SEGUNDO estagio do fastboot e leia a versao do bootloader:
       fastboot reboot bootloader
       fastboot getvar product              -> tem que dizer "soul"
       fastboot getvar version-bootloader

     A SINCRONIA importa e nao e' opcional: um stick nesse estado entra e sai
     do barramento USB sozinho, cerca de 6 s presente, 6 s ausente. Espere ele
     estar AUSENTE do barramento, e SO' ENTAO dispare o
     `fastboot reboot bootloader`, para ele ficar em
     "< waiting for any device >" e capturar a sessao nova quando o aparelho
     reaparecer. Subir o fastboot depois que ele ja voltou pega sessao morta:
     "Write to device failed (Unknown error)". Se ele parou de ciclar, me peca
     para desconectar e reconectar o cabo.

     O segundo estagio precisa do Google USB Driver (VID_18D1&PID_4EE7); sem
     ele todo comando trava.
     dl.google.com/android/repository/usb_driver_r13-windows.zip

  c) Decida pelo que voce leu:

       version-bootloader e' 01.01.25xxxx ou 01.01.26xxxx, product e' "soul"
         -> o bootloader e' ANDROID 14
         -> siga docs/pt-br/recuperacao-android-14.md
         -> NENHUMA firmware Android 11 vai bootar este aparelho. Nao ofereca.

       o aparelho estava no Android 11 e nunca recebeu a OTA de Android 14
         -> siga o caminho Android 11 do README-PT-BR.md

  Me diga qual dos dois voce encontrou e por que, e espere eu confirmar antes
  de baixar qualquer coisa.

FATOS VERIFICADOS EM QUE VOCE PODE CONFIAR (do repositorio)

  Pacote fastboot Android 14 (para aparelho com bootloader Android 14):
    mi-tv-stick-4k_14_26.6.10_91.7z
    tamanho 989694390 bytes
    sha256  6300f49e9e15ba50e4b6bc9ea7f3243b80178c122b08a440a5e144b8ea6f6711
    md5     45e8daf80b2abd2f0261f5ff24e98b45
    images/super.img       1887436800 bytes
      sha256 075c4e1b589e9fc0da8dc80a992276a74908c07e2fdcfeb68d64915db1b50a23
    images/bootloader.img  4100096 bytes
      sha256 9c4ae84ebd363afc5640ccb1fada3f2387e71556837b574ead840aa7705609c6
    Fonte: https://disk.yandex.ru/d/9toYWX5hWET-wQ
    Se esse link estiver acima da cota publica de download, a mesma build esta
    no servidor de OTA da propria Google, que sempre responde:
      https://android.googleapis.com/packages/ota-api/package/
      4eb355aa75c0fb7fdf79c98d7dc2e4acd4636280.zip   (1044570446 bytes)
    Essa e' uma OTA (payload.bin), nao imagens gravaveis. O repositorio tem
    tools/payload_dumper.py e tools/monta_super.py para converter.

  Pacote DNL Android 11 (so' para aparelho que nunca recebeu a OTA de A14):
    mi-tv-stick-4k_dnl_1440_01.7z
    tamanho 685065929 bytes
    sha256  6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
    md5     ffb220dd62cbff01f6e39461cd0154d1
    Identidade DNL do `adnl getvar identify`: 06-00-00-10-00-00-00-00
    GUID de interface ADB que o adnl.exe procura:
      {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}
    super-raw.img depois da conversao: 1887436800 bytes
      sha256 a514a082631d42e6fae69dd0c4325eb69ee2054f7cebf832b77bb163390913a2

BECOS SEM SAIDA - JA TESTADOS, NAO GASTE MEU TEMPO COM ELES

  - `fastboot reboot fastboot` (FastbootD) NAO sobe num aparelho quebrado.
    O FastbootD mora no ramdisk de recovery e precisa de um device tree
    valido, que e' justamente o que esta quebrado. E' circular. Qualquer
    pacote cujo script dependa do FastbootD - inclusive o de downgrade
    "14-to-11" - e' beco sem saida. O comando certo e' `reboot bootloader`,
    nao `reboot fastboot`.
  - As particoes `bootloader` e `reserved` RECUSAM escrita por DNL, testado de
    quatro formas: isolado, dentro do `oem disk_initial`, e sob quatro nomes
    de particao diferentes. A `reserved` guarda o device tree; e' por isso que
    o Android 11 nao pode ser restaurado num aparelho cujo bootloader ja e'
    Android 14.
  - O `flash bootloader` FUNCIONA, mas so' do segundo estagio do fastboot,
    depois do `flashing unlock`.

REGRAS

- Diagnostique antes de baixar. Nunca assuma qual brick e' o meu.
- Nunca pule nem enfraqueca a checagem de identidade DNL
  (06-00-00-10-00-00-00-00) no caminho Android 11. E' ela que impede o
  aparelho errado de ser gravado.
- Confira os hashes ANTES de gravar, nao depois.
- A gravacao apaga tudo. Me avise claramente antes do ponto sem volta e espere
  minha confirmacao explicita.
- Se um passo falhar, me mostre a saida de erro exata em vez de resumir.
- Nao invente passos que nao estao no repositorio. Se algo nao bater com o que
  voce esperava, diga isso em vez de improvisar.
- Uma gravacao que devolve rc=0 em todos os passos NAO e' uma recuperacao. Nao
  me diga que funcionou ate o aparelho ter bootado de fato - seja numa TV,
  seja enumerando no USB como VID_18D1&PID_4EE1 "MiTV-AYFR0". Ate la, diga que
  a gravacao terminou e que o resultado nao foi verificado.
````

---

## A regra que este repositório aprendeu do jeito difícil

Uma versão anterior deste README afirmava que o procedimento de Android 11 recuperou o aparelho. Não recuperou. A afirmação veio de um log em que as 16 etapas devolveram `rc=0`, escrita antes de alguém colocar o stick numa TV. Ele ficou 1h30 parado no logo Mi, e mais uma hora inteira no dia seguinte. O aparelho só foi recuperado dois dias depois, por outro método.

**Um log verde não é um aparelho funcionando.** É a coisa mais útil a exigir de uma IA, porque um código de saída limpo é exatamente o tipo de evidência que um modelo de linguagem acha convincente — e, num aparelho quebrado, a única evidência que conta é ele ligar.

Duas formas de conferir o resultado sem adivinhar:

- **Na TV** — o teste de verdade.
- **No USB** — um aparelho que bootou enumera como `VID_18D1&PID_4EE1`, com o nome amigável `MiTV-AYFR0`, que é o gadget MTP do Android. Um aparelho que não bootou volta como `VID_1B8E&PID_C004` (DNL). Isso funciona sem TV nenhuma por perto.

---

## Se a sua IA não tem acesso ao terminal

Uma IA só de navegador não consegue rodar nada disso. Ela ainda pode ajudar a ler posts do fórum russo, interpretar uma mensagem de erro, ou avaliar se o seu sintoma bate com este procedimento — mas o trabalho em si tem que ser feito por você, seguindo o [README](../../README-PT-BR.md).

---

## Uma nota sobre confiança

Uma IA vai fazer o que você pedir com mais confiança do que precisão. Num aparelho já quebrado, isso é risco real: não há desfazer, e uma gravação errada pode transformar um stick recuperável em um irrecuperável.

Três coisas em que vale insistir:

1. **O diagnóstico vem primeiro.** Se a IA propuser uma firmware antes de ter lido o `version-bootloader`, ela está chutando.
2. **A checagem de identidade fica.** Se ela oferecer removê-la porque "o aparelho não está sendo detectado", a resposta é não. Essa checagem é o motivo de um erro continuar inofensivo.
3. **Sucesso é bootar, não `rc=0`.** Veja acima.

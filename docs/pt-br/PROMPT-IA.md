# Fazendo isto com uma IA

🇺🇸 [English version](../AI-ASSISTANT-PROMPT.md) · 📖 [README em português](../../README-PT-BR.md)

O [README](../../README-PT-BR.md) principal foi escrito para você fazer tudo na mão, apenas com o que já vem no Windows. Esta página é a outra opção: se você tem um assistente de IA com acesso ao terminal — Claude Code, Codex CLI, Gemini CLI, Cursor ou qualquer outro parecido — ele consegue cuidar das partes chatas.

**O que ele consegue fazer:** conferir hashes, extrair o pacote, converter a imagem sparse, inspecionar o estado do dispositivo USB, aplicar a correção no registro, rodar a gravação, ler a saída e dizer o que falhou.

**O que ele não consegue fazer:** conectar o cabo. A regra de ordem continua valendo — a ferramenta de gravação precisa estar *esperando* antes de você conectar o stick — então essa parte vai ser pedida a você, na hora certa.

---

## Como usar

1. Baixe o `mi-tv-stick-4k_dnl_1440_01.7z` (veja as fontes no README).
2. Coloque-o numa pasta com pelo menos **4 GB livres**.
3. Abra o seu assistente com essa pasta como diretório de trabalho.
4. Cole o prompt abaixo.
5. **Leia o que ele propõe antes de aprovar qualquer coisa.** Tudo aqui apaga o aparelho; um assistente que entende errado a situação pode desperdiçar a sua única chance. Se ele sugerir uma etapa que não está no README, pergunte por que antes de dizer sim.

---

## O prompt

Copie tudo o que está dentro do bloco.

````text
Tenho um Xiaomi Mi TV Stick 4K, modelo MDZ-27-AA, travado na tela de boot,
que não inicia. Quero recuperá-lo gravando a firmware stock
RTT0.211222.001.1440 por USB usando o modo DNL da Amlogic.

Estou seguindo este procedimento:
https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery

Leia primeiro o README-PT-BR.md desse repositório para ter o contexto
completo, e depois me ajude a executá-lo passo a passo. Estou no Windows.

FATOS EM QUE VOCÊ PODE CONFIAR (verificados naquele repositório):

  Pacote de firmware : mi-tv-stick-4k_dnl_1440_01.7z
  Tamanho            : 685065929 bytes
  SHA-256            : 6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
  MD5                : ffb220dd62cbff01f6e39461cd0154d1

  O aparelho em modo DNL enumera como USB\VID_1B8E&PID_C004, normalmente
  com o nome "DNL"
  Identidade exigida em `adnl getvar identify`: 06-00-00-10-00-00-00-00
  GUID de interface do ADB que o adnl.exe procura:
    {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}

  super-ab-1440-sparse.img : 1650178104 bytes (Android sparse)
  super-raw.img depois da conversão : 1887436800 bytes
    SHA-256 a514a082631d42e6fae69dd0c4325eb69ee2054f7cebf832b77bb163390913a2

O QUE QUERO QUE VOCÊ FAÇA, NESTA ORDEM:

1. Verifique a minha cópia do .7z: confira tamanho, SHA-256 e MD5 contra os
   valores acima. Se algo divergir, PARE e me avise - não continue.

2. Extraia com o 7-Zip e confirme que a pasta contém bin\adnl.exe e uma
   pasta images\ com 8 arquivos .img.

3. Verifique o estado do USB: existe um dispositivo com hardware ID
   VID_1B8E&PID_C004 presente? Qual driver está vinculado a ele? O valor de
   registro DeviceInterfaceGUIDs dele contém o GUID do ADB acima? Relate o
   que encontrou e me diga o que está faltando.

4. Se o driver WinUSB estiver faltando, me diga para instalá-lo eu mesmo com
   o Zadig e espere - não tente instalar drivers por conta própria.

5. Se o GUID de interface do ADB estiver faltando em DeviceInterfaceGUIDs,
   acrescente-o (mantendo os GUIDs existentes, REG_MULTI_SZ) e reinicie o
   dispositivo. Me mostre os valores antes e depois. Isso exige
   Administrador.

6. Converta images\super-ab-1440-sparse.img em images\super-raw.img e
   verifique que o resultado tem exatamente 1887436800 bytes.

7. Então PARE e me devolva o controle para a gravação em si, me dizendo:
     - para desconectar o stick,
     - para iniciar o script de gravação,
     - para conectar o stick de volta somente quando ele disser que está
       esperando.
   O bootloader DNL só responde numa janela curta logo após a enumeração
   USB, então essa ordem não é opcional.

REGRAS:

- Nunca pule nem enfraqueça a checagem de identidade
  (06-00-00-10-00-00-00-00). É ela que impede que o aparelho errado seja
  gravado.
- A gravação apaga tudo no stick. Me avise claramente antes do ponto sem
  volta e espere minha confirmação explícita.
- Não invente etapas que não estejam no README daquele repositório. Se algo
  não bater com o que você esperava, diga isso em vez de improvisar.
- Se uma etapa falhar, me mostre a saída de erro exata em vez de resumi-la.
- Não modifique nem apague a minha cópia do .7z nem as imagens extraídas.
````

---

## Se o seu assistente não tem acesso ao terminal

Um assistente de chat só no navegador não consegue executar nada disso. Ele ainda pode ajudar você a ler posts de fórum em russo, interpretar uma mensagem de erro ou avaliar se o seu sintoma bate com este procedimento — mas o trabalho em si tem que ser feito por você, seguindo o [README](../../README-PT-BR.md).

---

## Uma observação sobre confiança

Uma IA vai fazer o que você pedir com mais confiança do que precisão. Num aparelho que já está quebrado, isso é um risco real: não existe desfazer, e uma gravação errada pode transformar um stick recuperável num irrecuperável.

As duas coisas em que vale insistir:

1. **A checagem de identidade fica.** Se um assistente se oferecer para removê-la porque "o dispositivo não está sendo detectado", a resposta é não. Essa checagem é a razão de um erro continuar inofensivo.
2. **Hashes são conferidos antes de gravar, não depois.** Verificar depois do fato diz por que quebrou; verificar antes diz para não quebrar.

# Espelhos do `mi-tv-stick-4k_dnl_1440_01.7z`

🇺🇸 [English version](../mirrors.md) · 📖 [README em português](../../README-PT-BR.md)

Este repositório **não** hospeda a firmware. Veja [Por que a firmware não está hospedada aqui](../../README-PT-BR.md#por-que-a-firmware-não-está-hospedada-aqui) — em resumo: é firmware proprietária e assinada da Xiaomi e não temos direito de redistribuí-la.

O que podemos fazer é tornar verificável qualquer cópia que você encontre. Se estes valores baterem, você tem o arquivo certo, seja qual for a fonte:

```
Nome    : mi-tv-stick-4k_dnl_1440_01.7z
          mi-tv-stick-4k_dnl_1440_01_MDZ-27-AA.7z   (mesmo arquivo, em alguns espelhos)
Tamanho : 685065929 bytes
SHA-256 : 6a54918cb8a07214374868e8bee5c4b02fbeba4a3a5100cb0541d2b74103b60b
MD5     : ffb220dd62cbff01f6e39461cd0154d1
```

**Não julgue uma cópia pelo nome do arquivo.** Espelhos renomeiam arquivos o tempo todo — acrescentando o modelo, tirando o sufixo, colocando uma versão. Renomear não muda nada dentro do pacote, então o hash continua idêntico. Um arquivo com o hash certo é o arquivo certo, não importa como se chame; e um arquivo com o hash errado é o arquivo errado, por mais certo que o nome pareça.

---

## Fontes conhecidas

Situação conforme observada em setembro de 2026. Links apodrecem; trate isto como ponto de partida, não como promessa.

| Fonte | URL | Observações |
|---|---|---|
| **Yandex Disk** | <https://disk.yandex.ru/d/CW66IHxzsgpFHA> | O original. Atinge periodicamente o limite de downloads e recusa novos. Pode exigir conta no Yandex, e a criação de conta pode falhar onde a verificação por SMS não chega — foi o nosso caso, com número brasileiro. Esse é o gargalo que tornou o arquivo tão difícil de obter. |
| **GSMForum** | <https://gsmforum.ru/resources/xiaomi-mi-tv-stick-4k-mdz-27-aa.12470/> | Página de recurso do MDZ-27-AA. Pode exigir cadastro. |
| **FirmwareDrive** | <https://firmwaredrive.com/index.php?a=downloads&b=folder&id=47997> | Agregador de terceiros. |
| **Tópico do 4PDA** | <https://4pda.to/forum/index.php?showtopic=1041410> | O tópico principal da comunidade. Exige cadastro para ver anexos. Quando um espelho morre, é ali que normalmente aparece um novo. Quase tudo em russo. |

### Builds modificadas (arquivos diferentes, não este)

O [yuliitezarygml/xiaomi-fimware](https://github.com/yuliitezarygml/xiaomi-fimware) publica duas builds **modificadas** como GitHub Releases — download direto, sem cadastro:

| Arquivo | Tamanho | Método | Bootloader destravado |
|---|---:|---|---|
| `MI-TV-STICK-4K_1440_MOD_8.2.7z` | 789.395.886 bytes | DNL | Não exige |
| `MI-TV-STICK-4K_1469_MOD_9.7z` | 662.495.411 bytes | fastboot | **Exige** |

Estas **não** são o arquivo stock `1440` e os hashes delas são diferentes. Não testamos nenhuma das duas. O README de lá avisa que um reset de fábrica na `1469_MOD_9` trava o bootloader e obriga a gravar de novo. Use apenas se o arquivo stock estiver realmente inacessível, e leia antes os avisos daquele repositório.

---

## Contribuindo com um espelho

Se você tem uma fonte funcionando, por favor abra uma issue com:

1. **A URL**, e se exige cadastro ou conta.
2. **O SHA-256 do arquivo que você realmente baixou dela** — calculado por você, não copiado desta página. É esse o ponto: um link só é útil se os bytes conferirem.
3. Aproximadamente quando você baixou, e quaisquer limites que tenha encontrado.

```powershell
Get-FileHash .\mi-tv-stick-4k_dnl_1440_01.7z -Algorithm SHA256
```

Vamos adicionar as fontes que conferirem. Por favor não envie links de arquivos cujo hash não bate — um hash diferente significa um arquivo diferente, e para um aparelho que não dá boot, "provavelmente está ok" não é bom o suficiente.

### O que não vamos fazer

- Hospedar a firmware aqui, em Releases ou via Git LFS. A questão de direitos não muda com o mecanismo de hospedagem.
- Linkar para fontes que empacotam a firmware com instaladores, "gerenciadores de download" ou executáveis não relacionados.
- Atestar a segurança de qualquer site de terceiros. Podemos dizer se os bytes são os bytes certos. Todo o resto sobre um espelho é julgamento seu.

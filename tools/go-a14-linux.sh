#!/bin/bash
# Grava o pacote Android 14 (mi-tv-stick-4k_14_26.6.10_91) a partir do Linux.
# Mesmos comandos e mesma ordem do go.cmd oficial; adiciona log e para no
# primeiro erro.
#
# Uso:
#   tools/go-a14-linux.sh <pasta-do-pacote-extraido> [caminho-do-fastboot]
#
# Requisitos (veja docs/linux.md):
#   - fastboot do platform-tools r33.0.3 (o r37 nao chegou ao 2o estagio)
#   - regra udev de tools/51-mi-tv-stick.rules
#   - usbcore.old_scheme_first=1 (senao o kernel perde o DNL de ~5 s)
#   - nenhum servidor adb rodando
#
# ATENCAO: 'fastboot -w' APAGA a userdata. E' o reset de fabrica do go.cmd.

set -uo pipefail

PKG="${1:-}"
FB="${2:-fastboot}"
LOG="go-a14-linux-$(date +%Y%m%d-%H%M%S).log"

[ -d "$PKG/images" ] || { echo "uso: $0 <pasta-do-pacote> [fastboot]"; exit 2; }
command -v "$FB" >/dev/null || { echo "fastboot nao encontrado: $FB"; exit 2; }

for f in bootloader dtbo oem odm_ext vbmeta vbmeta_system vendor_boot boot super; do
  [ -f "$PKG/images/$f.img" ] || { echo "falta $PKG/images/$f.img"; exit 2; }
done

if [ "$(cat /sys/module/usbcore/parameters/old_scheme_first 2>/dev/null)" != "Y" ]; then
  echo "AVISO: usbcore.old_scheme_first nao esta em Y. Sem isso o DNL costuma"
  echo "falhar com 'device descriptor read/all, error -110'. Para ativar:"
  echo "  echo 1 | sudo tee /sys/module/usbcore/parameters/old_scheme_first"
fi
pgrep -x adb >/dev/null && echo "AVISO: ha um servidor adb rodando; rode 'adb kill-server'."

exec > >(tee "$LOG") 2>&1
cd "$PKG" || exit 2

echo "fastboot: $("$FB" --version | head -1)"
read -r -p "Isto APAGA todos os dados do stick. Digite SIM para continuar: " ok
[ "$ok" = "SIM" ] || { echo "cancelado"; exit 1; }

run() {
  echo ">>> fastboot $*"
  "$FB" "$@" || { echo "FALHOU: fastboot $*"; exit 1; }
}

get() { timeout 15 "$FB" getvar "$1" 2>&1 | sed -n "s/^$1: *//p"; }

# O fastboot precisa estar esperando ANTES do stick reaparecer no barramento.
# O DNL so existe ~5 s apos conectar o cabo, entao: rode, e entao reconecte.
if [ "$(get product)" != "soul" ]; then
  echo ">>> Desconecte o stick, rode o proximo passo e RECONECTE o cabo agora."
  echo ">>> fastboot reboot bootloader (esperando o DNL)"
  timeout 180 "$FB" reboot bootloader || { echo "nao capturou o DNL"; exit 1; }
  for _ in $(seq 1 30); do
    [ "$(get product)" = "soul" ] && break
    sleep 1
  done
fi

[ "$(get product)" = "soul" ] || { echo "nao chegou ao 2o estagio"; exit 1; }
[ "$(get is-userspace)" = "no" ] || { echo "nao esta no bootloader"; exit 1; }
echo "version-bootloader: $(get version-bootloader)"

run flashing unlock
run flashing unlock_critical

run flash bootloader images/bootloader.img
for p in dtbo oem odm_ext vbmeta vbmeta_system vendor_boot boot; do
  run --slot all flash "$p" "images/$p.img"
done
run flash super images/super.img

run flashing lock
run flashing lock_critical

run reboot bootloader
for _ in $(seq 1 30); do
  [ "$(get product)" = "soul" ] && break
  sleep 1
done
[ "$(get product)" = "soul" ] || { echo "nao voltou ao 2o estagio"; exit 1; }

run flashing unlock
run set_active other
run set_active other
run -w
run flashing lock

echo "=== FIM. Log: $LOG ==="
echo "Tire o stick do PC, ligue na TV com carregador de tomada e espere ate 10 min."

#!/bin/bash
# Transcricao FIEL do go.cmd do pacote mi-tv-stick-4k_14_26.6.10_91.
#
# Os comandos e a ordem sao exatamente os do script oficial. O que este arquivo
# acrescenta e' log de tudo e a sincronia com o barramento -- porque o go.cmd
# original assume que o operador conecta o stick na hora certa, e aqui o link do
# DNL morre entre sessoes (§11.1 do doc de 10/09).
#
# POR QUE ESTE FLUXO FUNCIONA ONDE OS OUTROS FALHARAM
# Nenhum passo usa FastbootD. Tudo acontece no 2o estagio do fastboot, que neste
# aparelho abre em 2 segundos (comprovado duas vezes hoje). O pacote 14->11
# exigia FastbootD, que nao sobe aqui porque depende do device tree que esta
# errado -- o problema circular do §12.
#
# O bootloader e' gravado com 'flash bootloader' do proprio 2o estagio, nao como
# mmcblk0boot0. E' o que o log de referencia do 4PDA mostra dando OKAY.
#
# ATENCAO: o script termina com 'flashing lock'. E' o que o oficial faz. Se o
# aparelho nao bootar depois, o passo documentado no post #38965 e' voltar ao 2o
# estagio, 'flashing unlock' e 'set_active a' (ou b) -- e isso continua possivel
# com o bootloader travado, porque foi assim que destravamos as 10:17.
#
# 'fastboot -w' APAGA a userdata. E' proposital: e' o reset de fabrica.

set -o pipefail
BASE="/d/PROJECT"
PKG="$BASE/firmware/mi-tv-stick-4k_14_26.6.10_91"
FB="./bin/fastboot.exe"
LOG="$BASE/logs/go-a14-$(date +%Y%m%d-%H%M%S).txt"

exec 3>&1
exec >"$LOG" 2>&1
say(){ echo "$*"; echo "$*" >&3; }

estado(){
  local s t
  for t in 1 2 3; do
    s=$(powershell -NoProfile -ExecutionPolicy Bypass -File "$BASE/ferramentas/pnp.ps1" 2>/dev/null | tr -d '\r\n ')
    [ "$s" != "QUERYFAIL" ] && { echo "$s"; return; }
  done
  echo "QUERYFAIL"
}

N=0; FALHAS=0
run(){
  N=$((N+1))
  say "[$N $(date +%H:%M:%S)] fastboot $*"
  echo "--- fastboot $* ---"
  local out rc
  out=$(timeout 1800 "$FB" "$@" 2>&1); rc=$?
  echo "$out"; echo "[rc=$rc]"
  if [ $rc -ne 0 ] || echo "$out" | grep -qi "FAILED"; then
    say "    ^ FALHOU"; FALHAS=$((FALHAS+1)); return 1
  fi
  return 0
}
# leitura simples, sem contar como etapa
get(){ timeout 60 "$FB" getvar "$1" 2>&1 | tr -d '\r' | grep -i "^$1:" | awk '{print $2}'; }

entra_estagio2(){
  say ">>> testando se o aparelho responde..."
  local P; P=$(get product)
  if [ "$P" = "soul" ]; then say "    ja esta no 2o estagio"; return 0; fi

  # A ORDEM IMPORTA. O fastboot precisa ser disparado ENQUANTO o aparelho esta
  # fora do barramento, para ficar em "< waiting for any device >" e capturar a
  # sessao nova quando ele reaparece. Subir o fastboot depois que ele ja voltou
  # pega uma sessao morta: "Write to device failed" (foi o que aconteceu as
  # 16:07). E' o §11.1 do doc de 10/09, e e' como o gravar-14to11.sh e o
  # fastbootd.sh chegaram ao 2o estagio hoje.
  local i tent
  for tent in 1 2 3; do
    say "    [tentativa $tent] DESCONECTE o stick do USB."
    local gone=0
    for i in $(seq 1 300); do
      [ -z "$(estado)" ] && { gone=1; say "    saiu do barramento apos ${i}s"; break; }
      sleep 1
    done
    [ $gone -eq 0 ] && { say "TIMEOUT: nunca saiu do barramento."; return 1; }

    say "    fastboot no ar. RECONECTE o stick agora."
    echo "--- fastboot reboot bootloader (tentativa $tent) ---"
    timeout 180 "$FB" reboot bootloader 2>&1; echo "[rc=$?]"

    local k
    for k in $(seq 1 30); do
      sleep 1
      [ "$(estado)" = "FASTBOOT" ] && { say "    2o estagio apos ${k}s"; break; }
    done
    P=$(get product)
    say "    product = ${P:-<vazio>}"
    [ "$P" = "soul" ] && return 0
    say "    ainda nao. Vamos repetir o ciclo."
    for i in $(seq 1 120); do [ -z "$(estado)" ] && break; sleep 1; done
  done
  say "ABORTADO: nao cheguei ao 2o estagio em 3 tentativas. Nada foi gravado."
  return 1
}

main(){
  local f
  for f in bootloader dtbo oem odm_ext vbmeta vbmeta_system vendor_boot boot super; do
    [ -f "$PKG/images/$f.img" ] || { say "ERRO: falta $PKG/images/$f.img"; return 1; }
  done
  cd "$PKG" || { say "ERRO: falta $PKG"; return 1; }
  [ -x "$FB" ] || { say "ERRO: falta $PKG/bin/fastboot.exe"; return 1; }

  say "===== GO-A14  V816.0.26.6.10  $(date +%H:%M:%S) ====="
  say "barramento: $(estado)"
  say ""

  entra_estagio2 || return 1

  local US; US=$(get is-userspace)
  say "    is-userspace = ${US:-?}  (o oficial exige 'no')"
  [ "$US" = "no" ] || { say "ABORTADO: nao esta no bootloader."; return 1; }
  say "    version-bootloader = $(get version-bootloader)"
  say ""

  run flashing unlock
  run flashing unlock_critical
  say "    unlocked = $(get unlocked)"
  say ""
  say ">>> gravando. NAO desconecte ate o fim."

  run flash bootloader images/bootloader.img
  for f in dtbo oem odm_ext vbmeta vbmeta_system vendor_boot boot; do
    run --slot all flash "$f" "images/$f.img"
  done
  say "    (a super tem 1,8 GB e leva varios minutos)"
  run flash super images/super.img

  say ""
  run flashing lock
  run flashing lock_critical

  say ""
  say ">>> segunda etapa: slots e wipe"
  echo "--- fastboot reboot bootloader ---"
  timeout 120 "$FB" reboot bootloader 2>&1; echo "[rc=$?]"
  local k
  for k in $(seq 1 40); do
    sleep 1
    [ "$(estado)" = "FASTBOOT" ] && break
  done
  say "    version-bootloader = $(get version-bootloader)"
  run flashing unlock
  run set_active other
  run set_active other
  say "    (o -w apaga a userdata; e' o reset de fabrica)"
  run -w
  run flashing lock
  return 0
}

main
RC=$?
say ""
if [ $RC -eq 0 ]; then
  say "===== FIM: $N etapas, $FALHAS falha(s) ====="
  if [ $FALHAS -eq 0 ]; then
    say "Tire o stick do PC, ligue na TV com carregador de tomada e espere ate"
    say "10 minutos no primeiro boot."
  else
    say "Houve falhas. Veja o log antes de testar na TV."
  fi
else
  say "===== ABORTADO ====="
fi
say "log: $LOG"

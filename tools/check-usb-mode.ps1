# Le o barramento USB e diz qual estagio do stick esta presente.
# Saida: "DNL", "FASTBOOT", "" (ausente) ou "QUERYFAIL".
#
# Por que existe: o one-liner anterior usava -ErrorAction SilentlyContinue e
# devolvia vazio quando o proprio Get-PnpDevice falhava por um instante --
# indistinguivel de "o aparelho sumiu". Era 1 leitura ruim a cada 3. Aqui a
# consulta so vale se o barramento inteiro veio; senao diz QUERYFAIL e quem
# chama tenta de novo.
$ErrorActionPreference = 'Stop'
try {
  $all = @(Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB\*' })
} catch {
  Write-Output 'QUERYFAIL'; exit 0
}
if ($all.Count -eq 0) { Write-Output 'QUERYFAIL'; exit 0 }
$ids = @($all | ForEach-Object { $_.InstanceId })
if ($ids -match 'VID_18D1') { Write-Output 'FASTBOOT'; exit 0 }
if ($ids -match 'VID_1B8E') { Write-Output 'DNL'; exit 0 }
Write-Output ''

<#
.SYNOPSIS
    Makes adnl.exe able to see a Xiaomi Mi TV Stick 4K that is already in DNL
    mode with the WinUSB driver installed by Zadig.

.DESCRIPTION
    Symptom this fixes:
        adnl.exe prints "< waiting for Amlogic DNL device >" forever, even
        though Device Manager shows the stick with a working WinUSB driver
        and no yellow warning icon.

    Cause:
        Zadig registers a randomly generated device interface GUID.
        adnl.exe looks the device up by the ADB interface GUID, which is
        compiled into the binary. Both sides work; they just never meet.

    Fix:
        Add the ADB interface GUID to DeviceInterfaceGUIDs (REG_MULTI_SZ)
        for the DNL device, keeping whatever Zadig already wrote, then
        restart the device so Windows re-reads it.

    Safe to run more than once. It only touches the registry key of a USB
    device whose hardware ID is VID_1B8E&PID_C004 (Amlogic DNL). It writes
    nothing if no such device is present.

.EXAMPLE
    Right-click this file -> "Run with PowerShell"
    (it re-launches itself as Administrator if needed)
#>

[CmdletBinding()]
param(
    # Override only if your device enumerates with different IDs.
    [string]$HardwareId = 'VID_1B8E&PID_C004'
)

# --- self-elevate: this needs Administrator to write under HKLM ---
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-launching as Administrator..."
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"", '-HardwareId', "`"$HardwareId`""
    )
    return
}

$ErrorActionPreference = 'Stop'
$ADB_INTERFACE_GUID = '{F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}'

Write-Host ""
Write-Host "Looking for a DNL device with hardware ID USB\$HardwareId ..."

$enumRoot = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\$HardwareId"
if (-not (Test-Path $enumRoot)) {
    Write-Host ""
    Write-Host "Not found." -ForegroundColor Yellow
    Write-Host "The stick is not connected, or it is not in DNL mode, or Windows"
    Write-Host "has not enumerated it yet. Plug it in and run this again."
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}

# One subkey per physical device (its USB serial). Normally exactly one.
$instances = Get-ChildItem $enumRoot | Select-Object -ExpandProperty PSChildName
Write-Host ("Found {0} device instance(s)." -f $instances.Count)

$changed = 0
foreach ($serial in $instances) {

    $instanceId = "USB\$HardwareId\$serial"
    $paramKey   = "$enumRoot\$serial\Device Parameters"

    Write-Host ""
    Write-Host "Device: $instanceId"

    if (-not (Test-Path $paramKey)) {
        New-Item -Path $paramKey -Force | Out-Null
        Write-Host "  created 'Device Parameters' key"
    }

    $existing = (Get-ItemProperty -Path $paramKey -Name DeviceInterfaceGUIDs `
                    -ErrorAction SilentlyContinue).DeviceInterfaceGUIDs
    Write-Host ("  before: {0}" -f (($existing -join ', ')))

    if ($existing -and $existing[0] -eq $ADB_INTERFACE_GUID) {
        Write-Host "  already correct, nothing to do." -ForegroundColor Green
        continue
    }

    # ADB GUID first, then anything Zadig wrote (without duplicating ours).
    $newValue = @($ADB_INTERFACE_GUID) +
                @($existing | Where-Object { $_ -and $_ -ne $ADB_INTERFACE_GUID })

    Set-ItemProperty -Path $paramKey -Name DeviceInterfaceGUIDs `
        -Value ([string[]]$newValue) -Type MultiString

    $after = (Get-ItemProperty -Path $paramKey -Name DeviceInterfaceGUIDs).DeviceInterfaceGUIDs
    Write-Host ("  after:  {0}" -f (($after -join ', '))) -ForegroundColor Green
    $changed++

    # Windows only re-reads DeviceInterfaceGUIDs when the device restarts.
    try {
        Write-Host "  restarting device..."
        Disable-PnpDevice -InstanceId $instanceId -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        Enable-PnpDevice  -InstanceId $instanceId -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 3
        Write-Host "  device restarted." -ForegroundColor Green
    }
    catch {
        Write-Host ("  could not restart it automatically: {0}" -f $_.Exception.Message) `
            -ForegroundColor Yellow
        Write-Host "  Unplug the stick and plug it back in instead."
    }

    Get-PnpDevice -InstanceId $instanceId -ErrorAction SilentlyContinue |
        Format-List Status, Class, FriendlyName | Out-String | Write-Host
}

Write-Host ""
if ($changed -gt 0) {
    Write-Host "Done. $changed device(s) updated." -ForegroundColor Green
} else {
    Write-Host "Nothing needed changing." -ForegroundColor Green
}
Write-Host "This fix is permanent for this PC. You do not need to run it again."
Write-Host ""
Read-Host "Press Enter to close"

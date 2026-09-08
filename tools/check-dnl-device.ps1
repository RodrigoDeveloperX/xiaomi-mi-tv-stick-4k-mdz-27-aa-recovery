<#
.SYNOPSIS
    Read-only check: is the stick in DNL mode, does it have a driver, and is
    the interface GUID set up so adnl.exe can find it?

.DESCRIPTION
    Changes nothing. Run it whenever adnl.exe does not see the device, and it
    will tell you which of the three usual problems you have.

.EXAMPLE
    Right-click -> "Run with PowerShell"
#>

[CmdletBinding()]
param(
    [string]$HardwareId = 'VID_1B8E&PID_C004'
)

$ADB_INTERFACE_GUID = '{F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}'

function Say([string]$text, [string]$color = 'Gray') { Write-Host $text -ForegroundColor $color }

Say ""
Say "=== Mi TV Stick 4K / DNL mode check ===" 'Cyan'
Say ""

# --- 1. is a DNL device present at all? ------------------------------------
$devices = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
           Where-Object { $_.InstanceId -like "*$HardwareId*" }

if (-not $devices) {
    Say "[X] No device with hardware ID USB\$HardwareId is connected." 'Red'
    Say ""
    Say "    That ID is the Amlogic DNL bootloader. If the stick is plugged in"
    Say "    and you still get this, it is not in DNL mode."
    Say ""
    Say "    Other Amlogic USB IDs you may see instead:"
    Say "      VID_1B8E&PID_C003  - Amlogic World-Cup / burning mode"
    Say "      VID_18D1&PID_...   - Google: normal ADB or fastboot, NOT DNL"
    Say ""
    Say "    Anything under VID_18D1 means the device still boots far enough"
    Say "    for fastboot, and DNL is not the right procedure for you."
    Say ""
    Read-Host "Press Enter to close"
    exit 1
}

Say "[OK] DNL device found." 'Green'
Say ""

$problems = 0

foreach ($d in $devices) {
    Say "  InstanceId   : $($d.InstanceId)"
    Say "  FriendlyName : $($d.FriendlyName)"
    Say "  Status       : $($d.Status)"
    Say "  Class        : $($d.Class)"
    Say "  Service      : $($d.Service)"

    # --- 2. driver installed? ---------------------------------------------
    if ($d.Status -ne 'OK') {
        Say ""
        Say "  [X] Windows reports a problem with this device." 'Red'
        Say "      Typically 'Code 28 - no driver installed'."
        Say "      Fix: run Zadig as Administrator, Options > List All Devices," 'Yellow'
        Say "      pick the entry named DNL, choose the WinUSB driver, Install." 'Yellow'
        Say "      Check that Zadig shows USB ID 1B8E C004 before installing." 'Yellow'
        $problems++
    }
    elseif ($d.Service -ne 'WinUSB') {
        Say ""
        Say "  [!] Driver is '$($d.Service)', not WinUSB." 'Yellow'
        Say "      adnl.exe needs WinUSB. Install it with Zadig."
        $problems++
    }
    else {
        Say ""
        Say "  [OK] WinUSB driver is bound." 'Green'
    }

    # --- 3. interface GUID ------------------------------------------------
    $paramKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($d.InstanceId)\Device Parameters"
    $guids = (Get-ItemProperty -Path $paramKey -Name DeviceInterfaceGUIDs `
                -ErrorAction SilentlyContinue).DeviceInterfaceGUIDs

    Say ""
    if (-not $guids) {
        Say "  [X] DeviceInterfaceGUIDs is not set." 'Red'
        Say "      adnl.exe will sit at '< waiting for Amlogic DNL device >' forever."
        Say "      Fix: run tools\fix-adnl-guid.ps1" 'Yellow'
        $problems++
    }
    elseif ($guids -notcontains $ADB_INTERFACE_GUID) {
        Say "  [X] The ADB interface GUID is missing." 'Red'
        Say "      present : $($guids -join ', ')"
        Say "      needed  : $ADB_INTERFACE_GUID"
        Say "      adnl.exe looks the device up by that GUID, which is compiled"
        Say "      into the binary. Zadig writes a random one instead."
        Say "      Fix: run tools\fix-adnl-guid.ps1" 'Yellow'
        $problems++
    }
    else {
        Say "  [OK] ADB interface GUID is present:" 'Green'
        Say "       $($guids -join ', ')"
    }

    Say ""
    Say "  ---"
}

Say ""
if ($problems -eq 0) {
    Say "Everything looks right on the PC side." 'Green'
    Say ""
    Say "Reminder about the order that mattered here:" 'Cyan'
    Say "  1. UNPLUG the stick."
    Say "  2. Start the flash script, let it sit at"
    Say "     '< waiting for Amlogic DNL device >'."
    Say "  3. THEN plug the stick in."
    Say ""
    Say "Starting the tool while the stick was already plugged in failed"
    Say "every time in our tests, even though the device looked fine here."
} else {
    Say "$problems problem(s) found - see the notes above." 'Red'
}
Say ""
Read-Host "Press Enter to close"

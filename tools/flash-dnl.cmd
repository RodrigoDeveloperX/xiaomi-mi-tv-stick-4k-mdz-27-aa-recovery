@echo off
setlocal enabledelayedexpansion

rem ===========================================================================
rem  Xiaomi Mi TV Stick 4K (MDZ-27-AA) - DNL flash
rem  Firmware: RTT0.211222.001.1440 (stock, release-keys)
rem
rem  Put this file INSIDE the extracted firmware folder, next to bin\ and
rem  images\, then double-click it.
rem
rem  WARNING: this ERASES THE WHOLE DEVICE, user data included.
rem
rem  Same command sequence as the go.cmd shipped in the package, with one
rem  deliberate change: the super partition is written from a RAW image in
rem  normal mode instead of a sparse image in sparse mode. See the README.
rem
rem  Before writing a single byte it checks the hardware identity string and
rem  aborts if it does not match, so pointing this at a different Amlogic
rem  device does nothing.
rem ===========================================================================

cd /d "%~dp0"

set "ADNL=bin\adnl.exe"
set "EXPECTED_ID=06-00-00-10-00-00-00-00"

echo.
echo ================================================================
echo   Xiaomi Mi TV Stick 4K (MDZ-27-AA)  --  DNL flash
echo   Firmware RTT0.211222.001.1440
echo ================================================================
echo.

rem --- sanity: are we in the right folder? -----------------------------------
if not exist "%ADNL%" (
    echo [ERROR] bin\adnl.exe not found.
    echo.
    echo This script must sit INSIDE the extracted firmware folder,
    echo in the same place as go.cmd - the folder that contains bin\ and images\.
    echo.
    echo Current folder: %CD%
    goto :fail
)
if not exist "images\boot.img" (
    echo [ERROR] images\boot.img not found. Current folder: %CD%
    goto :fail
)

rem --- pick the super image --------------------------------------------------
rem  Preferred: raw image written in normal mode. This is what actually
rem  completed here. Sparse mode failed every time at 0x20000 bytes.
set "SUPER_FILE="
set "SUPER_MODE="
if exist "images\super-raw.img" (
    set "SUPER_FILE=images\super-raw.img"
    set "SUPER_MODE=normal"
) else (
    for %%F in ("images\super*sparse*.img") do (
        if not defined SUPER_FILE (
            set "SUPER_FILE=images\%%~nxF"
            set "SUPER_MODE=sparse"
        )
    )
)

if not defined SUPER_FILE (
    echo [ERROR] No super image found in images\.
    echo Expected images\super-raw.img or images\super-ab-1440-sparse.img
    goto :fail
)

if "%SUPER_MODE%"=="sparse" (
    echo [WARNING] Only the SPARSE super image was found:
    echo             %SUPER_FILE%
    echo.
    echo   Writing super in sparse mode failed on every attempt during this
    echo   recovery, always at the same point:
    echo       ERR[DNL]Fail in send data at len 0x20000
    echo.
    echo   Recommended: cancel now, convert it to a raw image with
    echo       tools\simg2img.ps1
    echo   and run this script again. Instructions are in the README.
    echo.
    choice /c YN /n /m "Continue anyway with sparse mode? [Y/N] "
    if errorlevel 2 goto :cancelled
)

echo Super image : %SUPER_FILE%  (mode: %SUPER_MODE%)
echo.
echo ----------------------------------------------------------------
echo   THIS WILL ERASE EVERYTHING ON THE STICK, INCLUDING YOUR DATA.
echo   Do not unplug the stick or the USB cable until it finishes.
echo   Expect roughly 5 to 6 minutes. The last step (super) alone takes
echo   about 5 minutes and looks frozen while it works.
echo ----------------------------------------------------------------
echo.
choice /c YN /n /m "Type Y to start, N to cancel [Y/N] "
if errorlevel 2 goto :cancelled

rem --- wait for the device ---------------------------------------------------
echo.
echo ================================================================
echo   NOW UNPLUG THE STICK if it is plugged in, then plug it back in.
echo.
echo   The order matters: this tool has to be waiting FIRST, and the
echo   stick plugged in AFTER. Plugging it in first and starting this
echo   afterwards did not work here.
echo ================================================================
echo.
echo Waiting for an Amlogic DNL device...
echo.

"%ADNL%" getvar identify > "%TEMP%\adnl_identify.txt" 2>&1
type "%TEMP%\adnl_identify.txt"

find "%EXPECTED_ID%" "%TEMP%\adnl_identify.txt" > nul
if errorlevel 1 (
    echo.
    echo [ABORTED] Hardware identity does not match %EXPECTED_ID%.
    echo NOTHING was written to the device.
    echo.
    echo This is the safety check. Either the device is not a Mi TV Stick 4K
    echo in DNL mode, or adnl could not talk to it at all. See the
    echo troubleshooting section of the README.
    del "%TEMP%\adnl_identify.txt" > nul 2>&1
    goto :fail
)
del "%TEMP%\adnl_identify.txt" > nul 2>&1

echo.
echo Identity OK. Starting. DO NOT UNPLUG ANYTHING.
echo.

rem --- erase and repartition -------------------------------------------------
call :run oem disk_initial
if errorlevel 1 goto :fail

rem --- one image, both A and B slots -----------------------------------------
call :writepair dtbo          dtbo.img
if errorlevel 1 goto :fail
call :writepair oem           oem.img
if errorlevel 1 goto :fail
call :writepair odm_ext       odm_ext.img
if errorlevel 1 goto :fail
call :writepair vbmeta        vbmeta.img
if errorlevel 1 goto :fail
call :writepair vbmeta_system vbmeta_system.img
if errorlevel 1 goto :fail
call :writepair vendor_boot   vendor_boot.img
if errorlevel 1 goto :fail
call :writepair boot          boot.img
if errorlevel 1 goto :fail

rem --- super, last and largest ----------------------------------------------
echo.
echo === super (about 5 minutes - it is not frozen) ===
if "%SUPER_MODE%"=="sparse" (
    "%ADNL%" partition -p super -f "%SUPER_FILE%" -t sparse
) else (
    "%ADNL%" partition -p super -f "%SUPER_FILE%"
)
if errorlevel 1 (
    echo.
    echo [FAILED] super could not be written.
    echo.
    echo IMPORTANT: the device is now in an unbootable state, because
    echo 'oem disk_initial' already erased it. This is recoverable - just
    echo run this whole script again from the start. Writing super on its
    echo own will NOT work: it has to happen in the same session as
    echo 'oem disk_initial'.
    goto :fail
)

echo.
echo ================================================================
echo   DONE. All partitions written.
echo.
echo   Unplug the stick from the PC and plug it into your TV, using a
echo   proper 5V/1A wall charger - not a TV USB port. The first boot
echo   after a flash draws the most power and can take 5 to 10 minutes
echo   on a black screen or on the logo. Do not cut the power.
echo ================================================================
echo.
pause
exit /b 0

rem ===========================================================================
:writepair
rem  %1 = partition base name, %2 = image file name
echo.
echo === %~1_a / %~1_b  ^<- images\%~2 ===
"%ADNL%" partition -p %~1_a -f "images\%~2"
if errorlevel 1 (
    echo [FAILED] writing %~1_a
    exit /b 1
)
"%ADNL%" partition -p %~1_b -f "images\%~2"
if errorlevel 1 (
    echo [FAILED] writing %~1_b
    exit /b 1
)
exit /b 0

rem ===========================================================================
:run
echo.
echo === %* ===
"%ADNL%" %*
if errorlevel 1 (
    echo [FAILED] %*
    exit /b 1
)
exit /b 0

rem ===========================================================================
:cancelled
echo.
echo Cancelled. Nothing was written.
pause
exit /b 1

:fail
echo.
pause
exit /b 1

<#
.SYNOPSIS
    Converts an Android sparse image (simg) into a raw image, using only
    Windows PowerShell. No Python, no Git Bash, no extra software.

.DESCRIPTION
    The Xiaomi Mi TV Stick 4K (MDZ-27-AA) DNL package ships
    images\super-ab-1440-sparse.img in Android sparse format. Writing it with
    "adnl partition -t sparse" failed repeatedly during our recovery
    (ERR[DNL]Fail in send data at len 0x20000). Converting it to a raw image
    and writing it in normal mode worked on the first try.

    This script performs that conversion. It is a straight reimplementation of
    the sparse format described in AOSP system/core/libsparse/sparse_format.h.

.EXAMPLE
    .\simg2img.ps1 super-ab-1440-sparse.img super-raw.img

.NOTES
    Needs about 1.8 GB of free disk space for the output of the 1440 package.
    Takes a few minutes. Progress is printed while it runs.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Source,
    [Parameter(Mandatory = $true, Position = 1)][string]$Destination
)

$ErrorActionPreference = 'Stop'

# --- Sparse format constants (AOSP sparse_format.h) ---
# Note: written as [uint32] on purpose. In Windows PowerShell 5.1 the bare
# literal 0xED26FF3A overflows into a negative Int32 and the comparison below
# would always fail.
$SPARSE_HEADER_MAGIC = [Convert]::ToUInt32('ED26FF3A', 16)
$CHUNK_TYPE_RAW      = 0xCAC1
$CHUNK_TYPE_FILL     = 0xCAC2
$CHUNK_TYPE_DONTCARE = 0xCAC3
$CHUNK_TYPE_CRC32    = 0xCAC4

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source file not found: $Source"
}

$srcPath = (Resolve-Path -LiteralPath $Source).Path
$dstPath = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine((Get-Location -PSProvider FileSystem).ProviderPath, $Destination))

$in  = [System.IO.File]::Open($srcPath, 'Open', 'Read', 'Read')
$br  = New-Object System.IO.BinaryReader($in)
$out = $null

try {
    # --- sparse_header ---
    $magic          = $br.ReadUInt32()
    if ($magic -ne $SPARSE_HEADER_MAGIC) {
        throw (("Not an Android sparse image (magic 0x{0:X8}, expected 0xED26FF3A). " +
                "If the file is already raw, you do not need this script.") -f $magic)
    }
    $majorVersion   = $br.ReadUInt16()
    $minorVersion   = $br.ReadUInt16()
    $fileHdrSize    = $br.ReadUInt16()
    $chunkHdrSize   = $br.ReadUInt16()
    $blockSize      = $br.ReadUInt32()
    $totalBlocks    = $br.ReadUInt32()
    $totalChunks    = $br.ReadUInt32()
    $imageChecksum  = $br.ReadUInt32()

    $expectedBytes = [uint64]$totalBlocks * [uint64]$blockSize

    Write-Host ("sparse v{0}.{1}  block={2}  blocks={3}  chunks={4}" -f `
        $majorVersion, $minorVersion, $blockSize, $totalBlocks, $totalChunks)
    Write-Host ("raw output will be {0:N0} bytes ({1:N2} GiB)" -f `
        $expectedBytes, ($expectedBytes / 1GB))

    $free = (Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($dstPath).TrimEnd('\:'))).Free
    if ($null -ne $free -and $free -lt $expectedBytes) {
        throw ("Not enough free space on the destination drive: need {0:N0} bytes, have {1:N0}." -f `
            $expectedBytes, $free)
    }

    $in.Seek([int64]$fileHdrSize, 'Begin') | Out-Null

    $out = [System.IO.File]::Open($dstPath, 'Create', 'Write', 'None')

    $bufSize = 4MB
    $buffer  = New-Object byte[] $bufSize
    [uint64]$written = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lastReport = 0

    for ($i = 0; $i -lt $totalChunks; $i++) {
        $chunkType  = $br.ReadUInt16()
        $null       = $br.ReadUInt16()          # reserved
        $chunkBlocks = $br.ReadUInt32()
        $totalSize   = $br.ReadUInt32()          # header + payload
        if ($chunkHdrSize -gt 12) {
            $in.Seek([int64]($chunkHdrSize - 12), 'Current') | Out-Null
        }

        [uint64]$outBytes = [uint64]$chunkBlocks * [uint64]$blockSize

        switch ($chunkType) {

            $CHUNK_TYPE_RAW {
                [uint64]$remaining = $outBytes
                while ($remaining -gt 0) {
                    $take = [int][Math]::Min([uint64]$bufSize, $remaining)
                    $got  = $in.Read($buffer, 0, $take)
                    if ($got -le 0) { throw "Unexpected end of file inside a RAW chunk (chunk $i)." }
                    $out.Write($buffer, 0, $got)
                    $remaining -= [uint64]$got
                    $written   += [uint64]$got
                }
            }

            $CHUNK_TYPE_FILL {
                $fill = $br.ReadBytes(4)
                # Build one buffer-sized block of the repeating 4-byte pattern.
                $pattern = New-Object byte[] $bufSize
                for ($p = 0; $p -lt $bufSize; $p += 4) {
                    [Array]::Copy($fill, 0, $pattern, $p, 4)
                }
                [uint64]$remaining = $outBytes
                while ($remaining -gt 0) {
                    $take = [int][Math]::Min([uint64]$bufSize, $remaining)
                    $out.Write($pattern, 0, $take)
                    $remaining -= [uint64]$take
                    $written   += [uint64]$take
                }
            }

            $CHUNK_TYPE_DONTCARE {
                # Not present in the source image: emit zeroes, same as simg2img.
                $zeros = New-Object byte[] $bufSize
                [uint64]$remaining = $outBytes
                while ($remaining -gt 0) {
                    $take = [int][Math]::Min([uint64]$bufSize, $remaining)
                    $out.Write($zeros, 0, $take)
                    $remaining -= [uint64]$take
                    $written   += [uint64]$take
                }
            }

            $CHUNK_TYPE_CRC32 {
                $null = $br.ReadUInt32()
            }

            default {
                throw (("Unknown chunk type 0x{0:X4} at chunk {1}. File may be corrupt - " +
                        "check the SHA-256 of the .7z before continuing.") -f $chunkType, $i)
            }
        }

        if ($sw.Elapsed.TotalSeconds - $lastReport -ge 5) {
            $lastReport = $sw.Elapsed.TotalSeconds
            $pct = if ($expectedBytes -gt 0) { 100.0 * $written / $expectedBytes } else { 0 }
            Write-Host ("  {0,5:N1}%  {1:N0} / {2:N0} bytes" -f $pct, $written, $expectedBytes)
        }
    }

    $out.Flush()
}
finally {
    if ($out) { $out.Dispose() }
    $br.Dispose()
    $in.Dispose()
}

$actual = (Get-Item -LiteralPath $dstPath).Length
Write-Host ""
Write-Host ("wrote {0:N0} bytes to {1}" -f $actual, $dstPath)

if ([uint64]$actual -ne $expectedBytes) {
    Write-Host ("MISMATCH: expected {0:N0} bytes. Do NOT flash this file." -f $expectedBytes) `
        -ForegroundColor Red
    exit 1
}

Write-Host "size matches the sparse header. Conversion OK." -ForegroundColor Green

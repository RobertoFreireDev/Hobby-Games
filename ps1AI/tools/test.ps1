param([Parameter(Mandatory = $true)][string]$Game,
      [string]$Inputs = '',      # "frame:BUTTON[:hold],..."
      [string]$Shots = '120',    # "frame,frame,..." (use >= 60)
      [int]$Seconds = 0,         # extra run time after the last shot
      [int]$Port = 8080,
      [switch]$Iso,              # boot game.cue through the BIOS instead of loading game.exe
      [ValidateSet('Debug', 'Release')][string]$Config = 'Debug')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
Import-ToolEnv
$root = Get-RepoRoot
Stop-Redux
& (Join-Path $PSScriptRoot 'build.ps1') -Game $Game -Config $Config
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$bld = Join-Path $root "build\$Game"
$out = Join-Path $bld 'test'
New-Item -ItemType Directory -Force -Path $out | Out-Null
Get-ChildItem $out -File | Remove-Item -Force
$log   = Join-Path $out 'tty.log'
$lua   = Join-Path $root 'tools\autoplay.lua'   # via $root: PCSX-Redux hangs on non-ASCII paths
$shotN = @($Shots -split ',' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ } | Sort-Object)
$exec  = "AUTOPLAY_INPUTS='$Inputs';AUTOPLAY_SHOTS='$($shotN -join ',')'"
$a =@('-run', '-webserver', '-webserver-port', "$Port", '-logfile', "`"$log`"",
       '-dofile', "`"$lua`"", '-exec', "`"$exec`"")
if ($Iso) { $a += @('-iso', "`"$bld\game.cue`"") } else { $a += @('-loadexe', "`"$bld\game.exe`"") }
# Minimized: the window does not steal focus, so keys the human types elsewhere
# cannot reach the emulator's pad 1 and disturb the scripted inputs.
# Working dir = emulator folder, so its crash reporter (.sentry-native/) stays out of the repo.
Start-Process -FilePath $env:PCSX_REDUX -ArgumentList $a -WindowStyle Minimized -WorkingDirectory (Split-Path $env:PCSX_REDUX) | Out-Null

$api = "http://127.0.0.1:$Port/api/v1"
function Get-Flow { try { Invoke-RestMethod -Uri "$api/execution-flow" -TimeoutSec 2 } catch { $null } }
$t0 = Get-Date
$deadline = $t0.AddSeconds(60)
do { Start-Sleep -Milliseconds 250; $st = Get-Flow      # wait for the emulator to come up
     if ((Get-Date) -gt $deadline) { Stop-Redux; throw 'Emulator web API unreachable' }
} until ($st -and ($st.running -or ((Get-Date) - $t0).TotalSeconds -gt 8))

foreach ($f in $shotN) {
    $deadline = (Get-Date).AddSeconds(30 + $f / 60)
    do { Start-Sleep -Milliseconds 100; $st = Get-Flow
         if ((Get-Date) -gt $deadline) { Stop-Redux; throw "Timed out waiting for frame $f" }
    } until ($st -and -not $st.running)
    $png = Join-Path $out ('frame_{0:D5}.png' -f $f)
    Invoke-WebRequest -UseBasicParsing -Uri "$api/screen/still" -OutFile $png | Out-Null
    Invoke-RestMethod -Method Post -Uri "$api/execution-flow?function=resume" | Out-Null
    Write-Host "SHOT $png"
}
if ($Seconds -gt 0) { Start-Sleep -Seconds $Seconds }
Stop-Redux
Start-Sleep -Milliseconds 500
Write-Host '--- tty.log (last 40 lines) ---'
if (Test-Path $log) { Get-Content $log -Tail 40 }
if ((Test-Path $log) -and (Select-String -Path $log -Pattern 'assert\(' -Quiet)) { Write-Host 'ASSERT FAILED (see log)'; exit 2 }

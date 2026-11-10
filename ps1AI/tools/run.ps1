param([Parameter(Mandatory = $true)][string]$Game, [switch]$Iso,
      [ValidateSet('Debug', 'Release')][string]$Config = 'Debug')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
Import-ToolEnv
Stop-Redux
& (Join-Path $PSScriptRoot 'build.ps1') -Game $Game -Config $Config
if ($LASTEXITCODE) { exit $LASTEXITCODE }
$bld = Join-Path (Get-RepoRoot) "build\$Game"
$a =@('-run', '-fastboot')
if ($Iso) { $a += @('-iso', "`"$bld\game.cue`"") } else { $a += @('-loadexe', "`"$bld\game.exe`"") }
Start-Process -FilePath $env:PCSX_REDUX -ArgumentList $a -WorkingDirectory (Split-Path $env:PCSX_REDUX) | Out-Null
Write-Host 'PCSX-Redux started.'

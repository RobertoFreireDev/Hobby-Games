param([Parameter(Mandatory = $true)][string]$Game,
      [ValidateSet('Debug', 'Release')][string]$Config = 'Debug')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
Import-ToolEnv
$root = Get-RepoRoot
$src  = Join-Path $root "games\$Game"
$bld  = Join-Path $root "build\$Game"
if (-not (Test-Path (Join-Path $src 'CMakeLists.txt'))) { throw "No game at $src" }
if (-not $env:PSN00BSDK_LIBS) { throw 'PSN00BSDK_LIBS is not set (see CLAUDE.md section 2)' }
$tc = ($env:PSN00BSDK_LIBS -replace '\\', '/') + '/cmake/sdk.cmake'
# Hide CMake author warnings coming from the SDK's own cmake files (flag renamed in CMake 4).
$quiet = if ((cmake --version | Select-Object -First 1) -match ' (\d+)\.' -and [int]$Matches[1] -ge 4) { '-Wno-author' } else { '-Wno-dev' }
cmake $quiet -S $src -B $bld -G Ninja "-DCMAKE_TOOLCHAIN_FILE=$tc" "-DCMAKE_BUILD_TYPE=$Config"
if ($LASTEXITCODE) { exit $LASTEXITCODE }
cmake --build $bld
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Write-Host "BUILD OK: $bld\game.exe  $bld\game.cue"

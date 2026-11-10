# Dot-sourced by build.ps1 / run.ps1 / test.ps1.

# Load the variables from the one-time setup (CLAUDE.md section 2) even when this terminal
# (or VS Code / Claude Code) was started before they were set.
function Import-ToolEnv {
    foreach ($n in 'PSN00BSDK_LIBS', 'PCSX_REDUX') {
        if (-not [Environment]::GetEnvironmentVariable($n)) {
            $v = [Environment]::GetEnvironmentVariable($n, 'User')
            if ($v) { [Environment]::SetEnvironmentVariable($n, $v) }   # process scope only
        }
    }
    if (-not (Get-Command cmake -ErrorAction SilentlyContinue) -or
        -not (Get-Command mipsel-none-elf-gcc -ErrorAction SilentlyContinue)) {
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                    [Environment]::GetEnvironmentVariable('Path', 'User')
    }
}

# Close every running PCSX-Redux (launcher + pcsx-redux.main). Done before building, since
# an emulator running the CD image keeps game.bin open and mkpsxiso cannot rewrite it.
function Stop-Redux {
    Get-Process | Where-Object { $_.ProcessName -like 'pcsx-redux*' } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 300
}

# The PSn00bSDK post-build step (nm > game.map inside nested cmd /C) breaks on paths with
# spaces, and some tools mishandle non-ASCII characters. When the repo lives in such a path,
# work through a junction at C:\psx\work\<repo-name> that points to the real repo folder.
# Files still land in the real repo (build/<name>/ ...), the junction only changes the path.
function Get-RepoRoot {
    $real = (Split-Path $PSScriptRoot -Parent).TrimEnd('\')
    if ($real -match '^[A-Za-z0-9_:\\.\-]+$') { return $real }
    $name = (Split-Path $real -Leaf) -replace '[^A-Za-z0-9_\-]', '_'
    $work = Join-Path $env:SystemDrive 'psx\work'
    $link = Join-Path $work $name
    if (Test-Path $link) {
        $item   = Get-Item $link -Force
        $target = "$(@($item.Target)[0])".TrimEnd('\')
        if ($item.LinkType -ne 'Junction' -or $target -ne $real) {
            throw "$link exists but does not point to $real (remove it or rename the repo folder)"
        }
    } else {
        New-Item -ItemType Directory -Force -Path $work | Out-Null
        New-Item -ItemType Junction -Path $link -Target $real | Out-Null
    }
    return $link
}

param([Parameter(Mandatory = $true)][ValidatePattern('^[a-z0-9_]+$')][string]$Name)
$root = Split-Path $PSScriptRoot -Parent
$dst  = Join-Path $root "games\$Name"
if (Test-Path $dst) { throw "games\$Name already exists" }
Copy-Item -Recurse (Join-Path $root 'games\_template') $dst
Write-Host "Created $dst"

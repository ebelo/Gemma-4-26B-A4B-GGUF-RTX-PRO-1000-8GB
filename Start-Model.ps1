# Foreground launcher. Ctrl+C stops this server; no background processes are installed.
[CmdletBinding()]
param(
    [string]$Runtime = (Join-Path $PSScriptRoot 'runtime\llama-server.exe'),
    [string]$Model = (Join-Path $PSScriptRoot 'models\gemma-4-26B-A4B-it-UD-Q4_K_M.gguf'),
    [string]$Draft = (Join-Path $PSScriptRoot 'models\mtp-gemma-4-26B-A4B-it-Q8_0.gguf'),
    [ValidateRange(1024,65535)][int]$Port = 18290,
    [switch]$PrintCommand
)
$ErrorActionPreference = 'Stop'
$serverArgs = @(
    '-m',
    $Model,
    '--host',
    '127.0.0.1',
    '--port',
    $Port,
    '-ngl',
    '99',
    '--cpu-moe',
    '--moe-cache-mib',
    '3072',
    '--moe-cache-cpu-share',
    '0.95',
    '-c',
    '32768',
    '-np',
    '1',
    '-t',
    '8',
    '-tb',
    '8',
    '-b',
    '512',
    '-ub',
    '256',
    '-fa',
    'on',
    '-ctk',
    'q8_0',
    '-ctv',
    'q8_0',
    '--fit',
    'off',
    '--no-webui',
    '--jinja',
    '--no-cache-prompt',
    '--spec-type',
    'draft-mtp',
    '--spec-draft-n-max',
    '2',
    '-md',
    $Draft,
    '-ngld',
    'all'
)
if ($PrintCommand) { Write-Output $Runtime; $serverArgs | ForEach-Object { Write-Output $_ }; return }
foreach ($required in @($Runtime, $Model, $Draft)) {
    if (!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing file: $required. See README.md." }
}
$Runtime = (Resolve-Path -LiteralPath $Runtime).Path
$Model = (Resolve-Path -LiteralPath $Model).Path
if ($Draft) { $Draft = (Resolve-Path -LiteralPath $Draft).Path }
# Resolve again after normalization so paths containing spaces stay individual arguments.
$serverArgs = @(
    '-m',
    $Model,
    '--host',
    '127.0.0.1',
    '--port',
    $Port,
    '-ngl',
    '99',
    '--cpu-moe',
    '--moe-cache-mib',
    '3072',
    '--moe-cache-cpu-share',
    '0.95',
    '-c',
    '32768',
    '-np',
    '1',
    '-t',
    '8',
    '-tb',
    '8',
    '-b',
    '512',
    '-ub',
    '256',
    '-fa',
    'on',
    '-ctk',
    'q8_0',
    '-ctv',
    'q8_0',
    '--fit',
    'off',
    '--no-webui',
    '--jinja',
    '--no-cache-prompt',
    '--spec-type',
    'draft-mtp',
    '--spec-draft-n-max',
    '2',
    '-md',
    $Draft,
    '-ngld',
    'all'
)
& $Runtime @serverArgs
if ($LASTEXITCODE -ne 0) { throw "llama-server exited with code $LASTEXITCODE" }

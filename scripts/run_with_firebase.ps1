param(
    [switch]$Check,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot 'firebase_config.json'

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "Missing firebase_config.json in the project root. Copy firebase_config.example.json to firebase_config.json and fill in your Firebase values before running the app."
    exit 1
}

if ($Check) {
    Write-Host "Firebase config file found: $configPath"
    exit 0
}

$flutterArgs = @('run', '--dart-define-from-file=' + $configPath)
if ($ExtraArgs.Count -gt 0) {
    $flutterArgs += $ExtraArgs
}

& flutter @flutterArgs
exit $LASTEXITCODE

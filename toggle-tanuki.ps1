# Natywny Tanuki (bez docker). Binarka: bin/tanuki.exe (go build -o bin/tanuki.exe ./cmd/tanuki).
# Dane: %LOCALAPPDATA%\tanuki\data, logi: %LOCALAPPDATA%\tanuki\tanuki*.log.
# Tanuki szuka .claude wzgledem katalogu roboczego, wiec startuje z profilu uzytkownika (~/.claude).
$exe = Join-Path $PSScriptRoot 'bin/tanuki.exe'
$userHome = $env:USERPROFILE
$base = Join-Path $env:LOCALAPPDATA 'tanuki'

$env:TANUKI_DATA = Join-Path $base 'data'
$env:TANUKI_PROXY_PORT = '18080'
$env:TANUKI_LISTEN_HOST = '127.0.0.1'
$env:TANUKI_UPSTREAM = 'https://api.anthropic.com'
$env:TANUKI_HOOK_CMD = '"' + ($exe -replace '[\\]', '/') + '" hook'

if (-not (Test-Path $exe)) { Write-Host "Brak $exe - zbuduj: go build -o bin/tanuki.exe ./cmd/tanuki" -ForegroundColor Red; exit 1 }

# Jednorazowa migracja: zatrzymaj stary kontener docker, jesli jeszcze chodzi.
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker inspect -f '{{.State.Running}}' tanuki 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Push-Location $PSScriptRoot
        docker compose down 2>$null | Out-Null
        Pop-Location
    }
}

$exePath = (Resolve-Path $exe).Path
$running = Get-Process -Name tanuki -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exePath }

Push-Location $userHome
try {
    if ($running) {
        $running | Stop-Process -Force
        $running | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
        # Zabity proces nie sprzata po sobie: reset usuwa przekierowanie i hooki z ~/.claude.
        & $exe reset | Out-Null
        Write-Host "Tanuki zatrzymane, Claude Code laczy sie bezposrednio." -ForegroundColor Yellow
        exit 0
    }

    New-Item -ItemType Directory -Force $base | Out-Null
    # Start-Process z -Redirect* dziedziczy uchwyty: proxy trzymaloby potok stdout wywolujacego
    # (Stateful Buttons) i przycisk krecilby sie, dopoki Tanuki dziala. ShellExecute nie dziedziczy
    # uchwytow (a zmienne srodowiskowe tak), przekierowanie robi cmd.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = '/c ""' + $exePath + '" proxy >"' + (Join-Path $base 'tanuki.log') + '" 2>"' + (Join-Path $base 'tanuki.err.log') + '""'
    $psi.WorkingDirectory = $userHome
    $psi.UseShellExecute = $true
    $psi.WindowStyle = 'Hidden'
    [System.Diagnostics.Process]::Start($psi) | Out-Null

    $settings = Join-Path $userHome '.claude/settings.json'
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 250
        if (Select-String -Path $settings -Pattern 'ANTHROPIC_BASE_URL' -Quiet) {
            Write-Host "Tanuki dziala: nowe sesje Claude Code ida przez proxy." -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "Tanuki nie wystartowal, zobacz $base/tanuki.err.log" -ForegroundColor Red
    exit 1
}
finally { Pop-Location }

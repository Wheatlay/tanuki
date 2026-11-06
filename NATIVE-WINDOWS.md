# Tanuki natywnie na Windows (bez docker), lokalny setup

Uruchamianie: przycisk „Tanuki” w Stateful Buttons (VS Code) → `toggle-tanuki.ps1`. Po przełączeniu okno VS Code przeładowuje się samo (`thenVscodeCommand`); inne okna trzeba przeładować ręcznie.

Budowanie: `go build -o bin/tanuki.exe ./cmd/tanuki` (`bin/` jest w `.git/info/exclude`). Działający exe jest zablokowany: zbuduj pod inną nazwą i podmień, albo najpierw wyłącz Tanuki.

Lokalne zmiany w kodzie (niezacommitowane):
- `TANUKI_LISTEN_HOST` (domyślnie `0.0.0.0`): skrypt ustawia `127.0.0.1`, żeby proxy nie było widoczne w LAN.
- `TANUKI_HOOK_CMD` (domyślnie `docker exec -i tanuki /tanuki hook`): skrypt wpisuje ścieżkę do `bin/tanuki.exe`.
- `dataDir()`: bez `TANUKI_DATA` używa `%LOCALAPPDATA%\tanuki\data`, bo hooki odpalane przez Claude Code nie mają tej zmiennej.

Ślad poza repo:
- `%LOCALAPPDATA%\tanuki\data`: dane engagementu (mapowania), przeniesione 06.11.2026 z wolumenu docker `tanuki-data`.
- `%LOCALAPPDATA%\tanuki\tanuki.log`, `tanuki.err.log`: logi procesu.
- `~/.claude/settings.json` (`ANTHROPIC_BASE_URL`, hook `pre-tool-use`) i `~/.claude/CLAUDE.md` (blok `TANUKI`): wpisywane przy starcie, czyszczone przy wyłączeniu (`tanuki.exe reset`).
- Stary wolumen docker `tanuki-data` i obraz `ghcr.io/pigyon/tanuki`: zostały, nieużywane.

Gdy Claude Code nie łączy się (ECONNREFUSED) przy wyłączonym Tanuki: w `C:\Users\krzys` uruchom `Desktop/2-Wydane/tanuki/bin/tanuki.exe reset`.

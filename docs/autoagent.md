# autoagent.md — Claude Code Autonomous Agent Configuratie

> **Doel:** Claude Code zo configureren dat hij grotendeels autonoom kan werken aan iOS-projecten zonder dat ik bij de laptop hoef te zitten, met push-notificaties op mijn telefoon voor de momenten dat hij wél input nodig heeft, en met intelligente pauze-en-hervat-logica bij rate limits.

> **Werkt samen met:** [`make_app.md`](./make_app.md) (workflow-index) en alle bestanden in `phases/`.

---

## 1. Filosofie

- **Standaard:** Claude werkt door zonder te vragen voor alle veilige, herstelbare acties.
- **Vragen:** alleen voor onomkeerbare of risicovolle acties — en dan via push-notificatie met **Ja/Nee**.
- **Limit:** bij 95% verbruik gaat de agent in wachtstand, stuurt push, hervat automatisch na reset.
- **Audit:** alles wordt gelogd zodat ik achteraf kan reviewen wat er gebeurde.

---

## 2. Toegestane acties (autonoom — geen prompt)

Deze acties voert Claude uit zonder bevestiging:

### Code & Files
- **Code schrijven** in `Features/`, `Core/`, `Infrastructure/`, `DesignSystem/`, `Tests/`
- **Code refactoren** binnen bestaande modules
- **Bestanden aanmaken** in projectmappen (behalve uitgesloten paden — zie §3)
- **Bestanden verwijderen** binnen het project (behalve uitgesloten paden)
- **Bestanden hernoemen / verplaatsen**
- **Documentatie aanmaken/updaten** in `/docs/` (inclusief features-specs in `docs/features/`)

### Build & Test
- `xcodebuild` / `swift build` (alle varianten)
- `xcodebuild test` / `swift test`
- Simulator starten en sluiten
- SwiftLint, SwiftFormat draaien
- `xcrun simctl` voor simulator-management

### Git
- `git add`, `git commit` (volgens commit-conventie in `architecture.md` §9)
- `git status`, `git diff`, `git log`, `git branch`
- `git checkout` naar bestaande branches
- `git stash` / `git stash pop`
- **Git tags zetten** voor fase-afsluitingen (bv. `v0.3-phase-3`)

### Dependencies
- `swift package update`, `swift package resolve`
- `pod install`, `pod update` (indien CocoaPods)
- `brew install` voor dev-tools (alleen uit toegestane lijst — zie §5)
- Tuist/XcodeGen regenereren

### Inspectie
- `Read`, `Glob`, `Grep`, `Bash` voor read-only commands
- `WebSearch`, `WebFetch` voor documentatie

---

## 3. Verboden acties (altijd geweigerd, ook met "ja" antwoord)

Deze gaan via `permissions.deny` en zijn **hard geblokkeerd**:

```json
{
  "permissions": {
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/*.p8)",
      "Read(**/*.p12)",
      "Read(**/AuthKey_*)",
      "Read(**/.git-credentials)",
      "Read(~/.ssh/**)",
      "Read(~/Library/Keychains/**)",
      "Bash(rm -rf /*)",
      "Bash(rm -rf ~/*)",
      "Bash(rm -rf .git*)",
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard origin/*)",
      "Bash(sudo *)",
      "Bash(curl * | sh)",
      "Bash(curl * | bash)",
      "Bash(wget * | sh)",
      "Bash(npm publish*)",
      "Bash(pod trunk push*)",
      "Bash(fastlane deliver*)",
      "Bash(fastlane pilot upload*)",
      "Bash(xcrun altool --upload-app*)",
      "Bash(xcrun notarytool submit*)"
    ]
  }
}
```

---

## 4. Acties die wél vragen (push-notificatie met Ja/Nee)

Voor deze acties stuurt de Notification-hook een push naar mijn telefoon:

| Actie | Reden |
|-------|-------|
| `git push` (naar remote) | Onomkeerbaar publiek maken |
| `git push origin main` | Specifiek main-protectie |
| Branch verwijderen (`git branch -D`) | Werk weg |
| `git rebase`, `git reset --hard` | Geschiedenis-herschrijving |
| Edit aan `*.pbxproj` | Brittle, makkelijk te corrupteren |
| Edit aan `Info.plist` (entitlements/permissions) | Compliance-impact |
| Edit aan `PrivacyInfo.xcprivacy` | App Store-impact |
| Edit aan `entitlements`-files | Capability-impact |
| TestFlight upload, App Store upload | Distributie-actie |
| Fastlane deploy lanes | Distributie-actie |
| Nieuwe externe dependency toevoegen | Supply-chain risico |
| Migration-scripts draaien | Mogelijk destructief |
| `xcrun simctl erase` | Wist simulator-data |
| **Fase-gate afsluiten** | Bewuste mijlpaal-bevestiging |

**Vraag-formaat:** push-bericht bevat:
1. Korte beschrijving (max 100 tekens)
2. Het exacte commando dat uitgevoerd wordt
3. Twee knoppen: ✅ Ja  /  ❌ Nee

---

## 5. settings.json — concrete configuratie

Plaats in `~/.claude/settings.json` (globaal) of `.claude/settings.json` (per project, overschrijft globaal):

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Glob(**)",
      "Grep(**)",
      "Edit(**)",
      "Write(**)",
      "Bash(xcodebuild *)",
      "Bash(swift build*)",
      "Bash(swift test*)",
      "Bash(swift package *)",
      "Bash(xcrun simctl list*)",
      "Bash(xcrun simctl boot*)",
      "Bash(xcrun simctl shutdown*)",
      "Bash(xcrun simctl install*)",
      "Bash(xcrun simctl launch*)",
      "Bash(swiftlint*)",
      "Bash(swiftformat*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git status*)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(git branch*)",
      "Bash(git checkout*)",
      "Bash(git stash*)",
      "Bash(git pull*)",
      "Bash(git fetch*)",
      "Bash(git tag*)",
      "Bash(pod install*)",
      "Bash(pod update*)",
      "Bash(tuist *)",
      "Bash(xcodegen *)",
      "Bash(brew install swiftlint)",
      "Bash(brew install swiftformat)",
      "Bash(brew install xcodegen)",
      "Bash(brew install tuist)",
      "WebSearch",
      "WebFetch"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(git rebase*)",
      "Bash(git reset --hard*)",
      "Bash(git branch -D*)",
      "Edit(**/*.pbxproj)",
      "Edit(**/Info.plist)",
      "Edit(**/PrivacyInfo.xcprivacy)",
      "Edit(**/*.entitlements)",
      "Bash(fastlane *)",
      "Bash(xcrun altool*)",
      "Bash(xcrun notarytool*)",
      "Bash(xcrun simctl erase*)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/*.p8)",
      "Read(**/*.p12)",
      "Read(**/AuthKey_*)",
      "Read(~/.ssh/**)",
      "Read(~/Library/Keychains/**)",
      "Bash(rm -rf /*)",
      "Bash(rm -rf ~/*)",
      "Bash(rm -rf .git*)",
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(sudo *)",
      "Bash(curl * | sh)",
      "Bash(curl * | bash)",
      "Bash(wget * | sh)",
      "Bash(npm publish*)",
      "Bash(pod trunk push*)"
    ]
  },
  "env": {
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "32000",
    "MCP_TIMEOUT": "30000",
    "MCP_TOOL_TIMEOUT": "60000"
  },
  "hooks": {
    "Notification": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "$HOME/.claude/scripts/notify-push.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "$HOME/.claude/scripts/check-usage.sh" }] }
    ],
    "Stop": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "$HOME/.claude/scripts/notify-done.sh" }] }
    ]
  }
}
```

> **Belangrijk:** Zet `.claude/settings.json` per project **niet** in `.gitignore` als je de config wilt delen, maar wél als hij user-specifieke paden of secrets bevat.

---

## 6. CLAUDE.md per project

Naast `settings.json` heeft elk project een `CLAUDE.md` in de root die Claude vertelt hoe hij `make_app.md` volgt:

```markdown
# CLAUDE.md

Volg de workflow uit `docs/make_app.md`. Voor elke fase:

1. Lees `docs/phases/0X-*.md` voor de huidige fase.
2. Lees `docs/architecture.md` als referentie.
3. Werk de exit-gate-checklist af.
4. Vraag bevestiging via Notification-hook vóór git tag + minor bump.
5. Werk CHANGELOG.md bij.

Project-specifieke features staan in `docs/features.md`.
Architectuur-afwijkingen documenteren in `docs/architecture-decisions.md`.
```

---

## 7. Rate Limit Handling — 95% wachtstand

### Strategie
1. **Monitoring:** vóór elke tool-call checkt de `PreToolUse`-hook (`check-usage.sh`) het huidige usage-percentage.
2. **Drempel:** bij ≥95% verbruikte limit → agent gaat in wachtstand.
3. **Notificatie:** push-bericht "⏸️ Limit 95% bereikt — pauzeer tot reset om HH:MM".
4. **Wachten:** wrapper-script `claude-resume.sh` houdt sessie alive, polling elke 5 min.
5. **Hervatten:** bij detectie dat limit gereset is → `continue` sturen en push "▶️ Hervat".
6. **Hard limit:** als limit alsnog volledig wordt geraakt mid-actie → exit en restart na reset.

### `check-usage.sh` (PreToolUse hook)

```bash
#!/usr/bin/env bash
# Check huidige Claude usage en pauzeer indien ≥95%

USAGE_FILE="$HOME/.claude/state/usage.json"
THRESHOLD=95

if [[ ! -f "$USAGE_FILE" ]]; then
  exit 0  # geen data = doorgaan
fi

PERCENTAGE=$(jq -r '.percentage_used // 0' "$USAGE_FILE")
RESET_TIME=$(jq -r '.reset_time // ""' "$USAGE_FILE")

if (( $(echo "$PERCENTAGE >= $THRESHOLD" | bc -l) )); then
  "$HOME/.claude/scripts/notify-push.sh" \
    "⏸️ Claude limit ${PERCENTAGE}% — pauze tot ${RESET_TIME}"

  touch "$HOME/.claude/state/PAUSED"

  # Block deze tool-call (PreToolUse exit code 2 = block)
  echo '{"decision": "block", "reason": "Usage limit threshold reached, pausing"}' >&2
  exit 2
fi

exit 0
```

### `claude-resume.sh` (wrapper)

```bash
#!/usr/bin/env bash
# Wrapper rond Claude Code die automatisch hervat na rate limit.

POLL_INTERVAL="${CLAUDE_POLL_INTERVAL:-300}"  # 5 min
PAUSE_FILE="$HOME/.claude/state/PAUSED"

while true; do
  while [[ -f "$PAUSE_FILE" ]]; do
    if check_limit_reset; then  # eigen functie: vraagt API of reset is
      rm "$PAUSE_FILE"
      "$HOME/.claude/scripts/notify-push.sh" "▶️ Limit gereset — hervat sessie"
      break
    fi
    sleep "$POLL_INTERVAL"
  done

  claude "$@"
  EXIT_CODE=$?

  [[ $EXIT_CODE -eq 0 ]] && break

  echo "Claude exited met code $EXIT_CODE — retry over ${POLL_INTERVAL}s"
  sleep "$POLL_INTERVAL"
done
```

> **Alternatief:** `npm i -g claude-auto-retry` (community-tool) detecteert rate limit + auto-resume native.

---

## 8. Push-notificaties — Ja/Nee flow

### Optie A — Native (aanbevolen sinds Claude Code 2.x)

Claude Code heeft sinds late 2025 ingebouwde push notifications via Remote Control:

1. Open Claude-app op telefoon → Settings → Remote Control → "Pair with Claude Code".
2. Schakel in: **"Push when Claude decides"** en **"Push on permission requests"**.
3. Alle `Notification`-hook events triggeren een push naar de telefoon.
4. Vanuit de notificatie kun je direct antwoorden of de sessie openen.

### Optie B — Custom via `notify-push.sh`

Voor eigen notificatiekanaal (Pushover, ntfy, Telegram bot):

```bash
#!/usr/bin/env bash
# Verstuur push via ntfy.sh (gratis, self-hostable)
MESSAGE="${1:-Claude needs attention}"
TOPIC="${NTFY_TOPIC:-claude-code-tim}"

curl -s -X POST "https://ntfy.sh/${TOPIC}" \
  -H "Title: Claude Code" \
  -H "Priority: high" \
  -H "Tags: robot" \
  -H "Actions: view, Open Mac, ssh://my-mac" \
  -d "$MESSAGE" > /dev/null
```

Voor Ja/Nee-keuzes: ntfy ondersteunt action buttons die een HTTP-callback triggeren — koppel aan een lokaal scriptje dat het antwoord teruggeeft via de `canUseTool` callback.

---

## 9. Veiligheidsvangrails

- **Sandboxing aan:** start Claude met `/sandbox` (macOS Seatbelt). Beperkt filesystem-bereik tot project-dir.
- **`.claudeignore`** in elk project, minimaal:
  ```
  .env
  .env.*
  *.p8
  *.p12
  AuthKey_*.p8
  fastlane/Appfile
  fastlane/.env
  *.mobileprovision
  Pods/
  .build/
  DerivedData/
  ```
- **Eén bron, meerdere AI-tools.** Houd `.claudeignore` als de canonieke bron en symlink andere AI-tool-ignores ernaar:
  ```bash
  # Eenmalig per project, in project root
  ln -s .claudeignore .cursorignore
  ln -s .claudeignore .aiderignore
  ln -s .claudeignore .aiexclude     # voor toekomstige tools
  ```
  Zo hoef je nooit meer te onthouden welke ignore-files synchroon moeten blijven. Als je morgen Cursor probeert is je veiligheid identiek aan Claude Code.
- **Pre-commit hook** die `git diff --cached` scant op secrets (API keys, tokens). Blokkeert commit bij hit.
- **Audit log** in `~/.claude/logs/audit-YYYY-MM-DD.log` — elke autonome actie wordt gelogd met timestamp + commando.
- **Geen `--dangerously-skip-permissions` ooit.** Deny-rules altijd actief houden.

---

## 10. Workflow voor "ik ga de deur uit"

1. Open project: `cd ~/Projects/MyApp`
2. Start sessie: `claude-resume.sh` *(of plain `claude` met `claude-auto-retry`)*
3. Geef opdracht, bv. *"Implementeer Fase 5 uit docs/make_app.md voor de chat-feature."*
4. Schakel telefoon-notificaties in (eenmalig per device).
5. Sluit laptop-deksel niet (`caffeinate` indien nodig).
6. Vertrek.
7. Claude werkt door. Bij vragen → push. Bij limit → wachtstand + push. Na reset → automatisch verder.
8. Bij thuiskomst: review audit log + git log.

---

## 11. Onderhouden

- Review `permissions.allow` elke twee weken — verplaats veelvoorkomende `ask`-prompts die altijd "ja" zijn naar `allow`.
- Review `permissions.deny` na elke Apple-policy-update of CVE-melding.
- Test `notify-push.sh` maandelijks.
- Update `claude-auto-retry` of eigen wrapper bij elke major Claude Code release.

---

## 12. Quick reference

```bash
# Start autonoom met wachtstand-support
claude-resume.sh

# Pauze handmatig forceren
touch ~/.claude/state/PAUSED

# Pauze opheffen
rm ~/.claude/state/PAUSED

# Audit log bekijken
tail -f ~/.claude/logs/audit-$(date +%F).log

# Permissions live editen tijdens sessie
/permissions
```

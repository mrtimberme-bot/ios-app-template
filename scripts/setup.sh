#!/usr/bin/env bash
# setup.sh — Vervang {{placeholders}} na clone van ios-app-template
#
# Gebruik:
#   bash scripts/setup.sh <AppNaam> <bundle.id> <TEAMID> <"Beschrijving"> <github-org>
#
# Voorbeeld:
#   bash scripts/setup.sh MijnApp com.company.mijnapp ABC123DEF "Mijn nieuwe iOS app" timothystekkinger

set -euo pipefail

APP_NAME="${1:-}"
BUNDLE_ID="${2:-}"
TEAM_ID="${3:-}"
DESCRIPTION="${4:-}"
GITHUB_ORG="${5:-timothystekkinger}"

if [ -z "$APP_NAME" ] || [ -z "$BUNDLE_ID" ] || [ -z "$TEAM_ID" ]; then
  echo "Gebruik: bash scripts/setup.sh <AppNaam> <bundle.id> <TEAMID> [beschrijving] [github-org]"
  echo ""
  echo "Voorbeeld:"
  echo "  bash scripts/setup.sh MijnApp com.company.mijnapp ABC123DEF4 \"Mijn app\" timothystekkinger"
  exit 1
fi

TEMPLATE_NAME="{{APP_NAME}}"
TEMPLATE_BUNDLE="{{BUNDLE_ID}}"
TEMPLATE_TEAM="{{TEAM_ID}}"
TEMPLATE_DESC="{{APP_DESCRIPTION}}"
TEMPLATE_ORG="{{GITHUB_ORG}}"

echo "🔧 Setup: $APP_NAME ($BUNDLE_ID)"
echo ""

# ── Hernoem mappen ─────────────────────────────────────────────────────────
if [ -d "$TEMPLATE_NAME" ]; then
  mv "$TEMPLATE_NAME" "$APP_NAME"
  echo "✅ Map hernoemd: $TEMPLATE_NAME → $APP_NAME"
fi

if [ -d "${TEMPLATE_NAME}Tests" ]; then
  mv "${TEMPLATE_NAME}Tests" "${APP_NAME}Tests"
  echo "✅ Map hernoemd: ${TEMPLATE_NAME}Tests → ${APP_NAME}Tests"
fi

if [ -d "${TEMPLATE_NAME}UITests" ]; then
  mv "${TEMPLATE_NAME}UITests" "${APP_NAME}UITests"
  echo "✅ Map hernoemd: ${TEMPLATE_NAME}UITests → ${APP_NAME}UITests"
fi

# ── Vervang tokens in alle tekstbestanden ──────────────────────────────────
echo "🔄 Tokens vervangen..."

find . \
  -not -path "./.git/*" \
  -not -path "*/DerivedData/*" \
  -not -path "*/.build/*" \
  -not -name "*.png" \
  -not -name "*.jpg" \
  -not -name "*.pdf" \
  -not -name "*.p8" \
  -not -name "*.p12" \
  -not -name "*.mobileprovision" \
  -type f \
  | while read -r file; do
    if file "$file" | grep -q "text"; then
      sed -i '' \
        -e "s/$TEMPLATE_NAME/$APP_NAME/g" \
        -e "s/$TEMPLATE_BUNDLE/$BUNDLE_ID/g" \
        -e "s/$TEMPLATE_TEAM/$TEAM_ID/g" \
        -e "s|$TEMPLATE_ORG|$GITHUB_ORG|g" \
        "$file" 2>/dev/null || true

      if [ -n "$DESCRIPTION" ]; then
        sed -i '' "s/$TEMPLATE_DESC/$DESCRIPTION/g" "$file" 2>/dev/null || true
      fi
    fi
  done

echo "✅ Tokens vervangen"

# ── Hernoem bestanden die de app naam bevatten ─────────────────────────────
find . -name "*${TEMPLATE_NAME}*" -not -path "./.git/*" | while read -r file; do
  new_name=$(echo "$file" | sed "s/$TEMPLATE_NAME/$APP_NAME/g")
  if [ "$file" != "$new_name" ]; then
    mv "$file" "$new_name" 2>/dev/null || true
    echo "✅ Bestand hernoemd: $(basename $file) → $(basename $new_name)"
  fi
done

# ── CHANGELOG initialiseren ───────────────────────────────────────────────
cat > CHANGELOG.md <<EOF
# Changelog — $APP_NAME

## [Unreleased]

### Added
- Initiële app setup

EOF

echo "✅ CHANGELOG.md aangemaakt"

# ── docs/tasks/daily-log.md initialiseren ─────────────────────────────────
cat > docs/tasks/daily-log.md <<EOF
# Daily Log — $APP_NAME

## $(date '+%Y-%m-%d')
### Gedaan
- App setup vanuit ios-app-template

### Volgende stap
- /plan-feature → architectuurkeuzes vastleggen
- /theme-designer → brand identity definiëren
- /setup-certs → code signing configureren

EOF

echo "✅ docs/tasks/daily-log.md aangemaakt"

# ── .claude/ inrichten ─────────────────────────────────────────────────────
mkdir -p .claude
cat > .claude/template-sync-date <<EOF
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
echo "✅ .claude/template-sync-date aangemaakt"

echo ""
echo "✅ Setup compleet voor $APP_NAME!"
echo ""
echo "Volgende stappen:"
echo "  1. Installeer XcodeGen: brew install xcodegen"
echo "  2. Genereer Xcode project: xcodegen generate"
echo "  3. Open: open $APP_NAME.xcodeproj"
echo "  4. Signing instellen: Target → Signing & Capabilities → Team: $TEAM_ID"
echo "  5. Run op simulator om te verifiëren"
echo ""
echo "Claude Code starten:"
echo "  claude"
echo "  /sod"

# ios-app-template

> iOS app template voor snelle, kwalitatieve app ontwikkeling met Claude Code.

## Vereisten

- macOS 15+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [Fastlane](https://fastlane.tools): `brew install fastlane`
- [pre-commit](https://pre-commit.com): `brew install pre-commit`
- GitHub CLI: `brew install gh`

## Nieuwe app aanmaken

### Optie 1: Via Claude Code (aanbevolen)
```
/new-app
```

Claude Code vraagt om de app naam, bundle ID, en team ID en doet de rest.

### Optie 2: Handmatig
```bash
gh repo create MijnApp \
  --template timothystekkinger/ios-app-template \
  --private --clone

cd MijnApp
bash scripts/setup.sh "MijnApp" "com.company.mijnapp" "TEAMID123" "Mijn app beschrijving"

brew install xcodegen
xcodegen generate

open MijnApp.xcodeproj
```

## Eerste stappen na setup

1. Open `MijnApp.xcodeproj` in Xcode
2. Signing instellen: Target → Signing & Capabilities → Team
3. Run op simulator om te verifiëren
4. `claude` starten → `/setup-certs` → `/plan-feature`

## Configuratie vereist

Maak een `.env` bestand (kopie van `.env.example`) met:
- App Store Connect API credentials (voor Fastlane)
- Fastlane Match wachtwoord (voor code signing)

> Commit NOOIT je `.env` bestand — het staat in `.gitignore`.

## Workflow commando's

| Commando | Wanneer |
|---------|---------|
| `/sod` | Begin van de dag |
| `/eod` | Einde van de dag |
| `/plan-feature` | Nieuwe feature plannen |
| `/start-feature` | Feature branch starten |
| `/wrap-feature` | Feature afronden + PR |
| `/audit` | Pre-release check |
| `/ship` | Naar TestFlight / App Store |
| `/post-launch` | Na App Store approval |
| `/template-sync` | Template updates binnenhalen |
| `/setup-certs` | Code signing instellen |

## Template updaten

Verbeteringen die je ontdekt terugsturen naar het template:
1. Open een issue of PR op `timothystekkinger/ios-app-template`
2. Bestaande apps updaten: `/template-sync`

## Structuur

```
{{APP_NAME}}/          Xcode app target
  App/               Entry point
  Features/          Feature modules
  Services/          Cross-feature services
  DesignSystem/      Tokens + components
  Models/            Shared models
  Utilities/         Helpers
  Resources/         Assets, PrivacyInfo, Info.plist
Packages/
  AppUI/             Gedeelde UI components (SPM)
  CoreKit/           Gedeelde utilities (SPM)
fastlane/            Release automation
docs/                Documentatie
.github/workflows/   CI/CD
scripts/setup.sh     Post-clone setup script
project.yml          XcodeGen configuratie
```

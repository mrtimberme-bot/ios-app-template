# Daily Log — {{APP_NAME}}

## {{SETUP_DATE}}
### Gedaan
- App aangemaakt vanuit ios-app-template

### Volgende stap
- /plan-feature → architectuurkeuzes vastleggen
- /theme-designer → brand identity

### Notes
Placeholder — setup.sh vervangt dit bij initialisatie.

## 2026-05-12

### Gedaan
- Volledig iOS app lifecycle workflow opgezet
- ios-app-template GitHub repo aangemaakt (mrtimberme-bot/ios-app-template)
- 3 nieuwe commands: /post-launch, /setup-certs, /template-sync
- /new-app, /ship, /sod, /eod verbeterd
- post-launch skill aangemaakt
- WORKFLOW.md instructiegids geschreven
- Bugfix: /new-app kloont nu altijd naar ~/Development/<AppNaam>
- Bugfix: CI skip op template repo zelf ({{APP_NAME}} placeholder fix)

### Volgende stap
Template testen door een echte nieuwe app aan te maken via /new-app

### Openstaand
- /new-app uitproberen end-to-end met een test-app
- GitHub repo eventueel verplaatsen naar timothystekkinger account

### Notes voor morgen
Start met /sod in de Template directory. Template staat klaar op GitHub.

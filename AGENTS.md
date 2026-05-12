# {{APP_NAME}} — Codex Agent Instructies

## Taal & communicatie
Code en commits: Engels. Communicatie met gebruiker: Nederlands.

## Wat Codex doet in dit project
- Boilerplate genereren (views, viewmodels, services)
- Repetitieve tests schrijven
- Kleine bugs fixen die Claude Code aanwijst
- Documentatie updates

## Wat Codex NIET doet
- Architectuurkeuzes
- Privacy manifest updates (dat doet Claude Code)
- `.pbxproj` edits
- Signing of certificates

## Code conventies
- Swift 6, @Observable ViewModels, SwiftData voor persistence
- Design tokens via `DesignTokens.swift` — nooit hardcoded
- `Logger` voor logging, nooit `print()`
- Geen force unwraps in production

## Git
- Feature branches: `feat/<naam>`, `fix/<naam>`
- Conventional commits
- NOOIT direct op main

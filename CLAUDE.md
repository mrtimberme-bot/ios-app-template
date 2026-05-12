# {{APP_NAME}} — Claude Code Instructies

## Context detection
- `CLAUDE_CONFIG_DIR` gezet → Xcode native agent modus
- Anders → terminal CLI

## Tech stack
- **Deployment target:** iOS 18.0+
- **UI:** SwiftUI only
- **State:** `@Observable` + SwiftUI
- **Concurrency:** Swift 6 Minimal
- **Persistence:** SwiftData
- **Secrets:** Keychain via `KeychainService`
- **Logging:** `os.Logger` (geen `print()`)
- **Design:** DesignTokens.swift
- **Monetization:** {{MONETIZATION_STRATEGY}}

## KRITIEKE REGELS

### Git (1-3)
1. **NOOIT** direct op `main`. Feature branch → PR → akkoord → merge.
2. Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `perf:`
3. Branch naming: `feat/<naam>`, `fix/<naam>`, `chore/<naam>` (kebab-case)

### Testing (4-5)
4. **NOOIT** tests lokaal draaien — Mac crasht daarop.
5. Tests draaien ALLEEN via GitHub Actions CI.

### Code (6-9)
6. **NOOIT** `.pbxproj` bewerken. Gebruik Xcode File → New → File.
7. Geen force unwrapping (`!`) in production code.
8. Geen `print()` — gebruik `Logger(subsystem: "{{BUNDLE_ID}}", category: "")`.
9. Geen `@unchecked Sendable` zonder comment waarom.

### Privacy & security (10-12)
10. `PrivacyInfo.xcprivacy` updaten bij elke nieuwe dependency.
11. `Info.plist` usage descriptions verplicht, in mensentaal.
12. Secrets uitsluitend via `KeychainService`.

### Design (13-16)
13. Design tokens via `DesignTokens` — nooit hardcoded kleuren/fonts/spacing.
14. Dark mode vanaf dag 1.
15. Dynamic Type XS tot XXXL.
16. VoiceOver labels op alle interactieve elementen.

## Folder structure

```
{{APP_NAME}}/App/, Features/, Services/, DesignSystem/, Models/, Utilities/, Resources/
Packages/AppUI/, Packages/CoreKit/
docs/tasks/, docs/architecture/, docs/design/, docs/audit/, docs/release/
```

## Default simulator
iPhone 16 Pro, iOS 18.x

## Skills (proactief activeren)
- `app-store-readiness` → PR + pre-submit
- `privacy-manifest` → nieuwe dependency
- `hig-compliance` + `accessibility-auditor` → UI werk
- `security-auditor` → network/auth/storage
- `motion-designer` + `haptics-designer` → interactions
- `ux-designer` + `onboarding-designer` → flows
- `localization-manager` → strings
- `swift-reviewer` → PR review
- `post-launch` → na App Store approval, dag 1/7/30

## Subagents
`ios-architect`, `swiftui-specialist`, `tca-specialist`, `ux-designer`,
`app-review-auditor`, `security-auditor`, `performance-analyst`, `release-manager`

## Workflow
ios-blok-workflow: één feature = één blok = één branch = één PR

Dagelijkse routine: `/sod` → `/plan-feature` → `/start-feature` → code → `/wrap-feature` → `/eod`
Release: `/audit` → `/ship` → `/post-launch`
Updates: `/template-sync` (maandelijks)

## Notificaties
Gebruik `/notify` proactief. Max 10 woorden.
Notificeer bij: plan klaar, feature compleet, CI resultaat, ship status.

## PR beschrijving
Elke PR bevat: `## Rollback-impact` sectie.

## Bij twijfel
Plan-mode eerst → output naar `docs/tasks/` → geen implementatie zonder akkoord.

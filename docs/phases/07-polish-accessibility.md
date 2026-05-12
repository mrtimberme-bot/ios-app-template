# Fase 7 — UX-polish & Accessibility

> **Doel:** van "werkt" naar "voelt goed".
> **Versie na afsluiten:** v0.7
> **Vorige fase:** [06-features.md](./06-features.md)
> **Volgende fase:** [08-stabilisation.md](./08-stabilisation.md)

> **Diepte-referenties voor deze fase:**
> - [`onboarding.md`](../onboarding.md) — first-run flow, permission priming, empty states
> - [`localization.md`](../localization.md) — pluralization, RTL, locale-aware formatting
> - [`testing-strategy.md`](../testing-strategy.md) §5 — snapshot tests voor DesignSystem-components

---

## Activiteiten

### 1. HIG-review

Doorloop [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) met je app open ernaast:

- **Navigation** — `NavigationStack` correct gebruikt? Back-gestures werken?
- **Modals & sheets** — gebruikt waar passend, niet overal?
- **Lists & grids** — pull-to-refresh waar logisch? Swipe-actions?
- **Buttons** — primary/secondary visueel onderscheid? Genoeg tap-targets (44pt min)?
- **Haptics** — subtiele feedback bij belangrijke acties (`UIImpactFeedbackGenerator`)?
- **Gestures** — natuurlijke patronen, geen conflicten?

### 2. UI-states per scherm

Voor élk scherm controleren:

| State | Wat moet er gebeuren? |
|-------|----------------------|
| **Loading** | Skeleton, progress, of `ProgressView`? |
| **Empty** | Vriendelijke uitleg + actie ("Stuur je eerste bericht") |
| **Error** | Wat ging fout + retry-knop |
| **Success/Default** | De normale weergave |
| **Offline** | Indicator + cached data tonen indien mogelijk |

Geen scherm zonder al deze states.

### 3. Animaties & transities

- Subtiel, niet showy.
- `.spring()` voor natuurlijke bewegingen.
- Symmetrisch: als je iets in-animeert, animeer het ook uit.
- Performance: 60fps minimum, 120fps op ProMotion.
- Respecteer **Reduce Motion** systeem-instelling:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? nil : .spring(), value: state)
```

### 4. Accessibility — kritisch

#### VoiceOver

- Elke interactieve view heeft `.accessibilityLabel`
- Decoratieve images: `.accessibilityHidden(true)`
- Custom controls: `.accessibilityAddTraits(.isButton)` etc.
- Test met VoiceOver aan (Settings → Accessibility → VoiceOver)

```swift
Button(action: send) {
    Image(systemName: "paperplane.fill")
}
.accessibilityLabel("Stuur bericht")
.accessibilityHint("Verstuurt het ingetypte bericht naar de assistent")
```

#### Dynamic Type

- Gebruik semantic font-sizes (`.body`, `.title`, etc.) — niet hardcoded points.
- Test op grootste size (Settings → Accessibility → Display & Text Size → Larger Text → max).
- Layouts moeten meeschalen — geen tekst die afgekapt raakt.

#### Contrast

- Minimum WCAG AA voor body-tekst (4.5:1 ratio).
- Test in Light + Dark mode.
- **Increase Contrast**-modus respecteren.

#### Reduce Motion + Reduce Transparency

- Animaties beperken bij Reduce Motion.
- Geen kritieke info in transparency-effecten als Reduce Transparency aan staat.

### 5. Localization-skelet

Zelfs als je nu alleen NL of EN ondersteunt:

- Alle UI-strings in `Localizable.xcstrings`
- Geen hardcoded strings in Swift-code:

```swift
// ❌ Fout
Text("Verstuur bericht")

// ✅ Goed
Text("send_message_button", bundle: .main)

// Of (iOS 15+)
Text(.init("send_message_button"))
```

- Datumformatten via `Date.FormatStyle` (locale-aware).
- Currency via `NumberFormatter` of `.formatted(.currency(...))`.

### 6. Dark Mode

Test elk scherm in:

- Light mode
- Dark mode
- Switching tijdens gebruik

Custom kleuren via `Color`-assets met light/dark variants.

### 7. Landscape

Beslis bewust:

- Wel ondersteunen → test elk scherm.
- Niet ondersteunen → in Info.plist `UISupportedInterfaceOrientations` correct zetten.

### 8. iPad-specifieke aanpassingen (indien ondersteund)

- Multi-column layouts waar passend
- Pointer-support (hover states)
- Keyboard shortcuts (`@FocusedValue`, `.keyboardShortcut`)
- Multitasking (Slide Over, Split View)

---

## Exit-gate

- [ ] Accessibility Inspector geeft 0 errors voor alle schermen
- [ ] App is volledig navigeerbaar met VoiceOver
- [ ] Loading, empty, error states bestaan voor elk scherm
- [ ] Dark Mode werkt op elk scherm
- [ ] Dynamic Type werkt op grootste size
- [ ] Reduce Motion gerespecteerd
- [ ] Geen hardcoded strings in UI-code
- [ ] Landscape-keuze gemaakt en consistent
- [ ] Haptics op belangrijke acties
- [ ] **Git-tag:** `v0.7-polish`
- [ ] CHANGELOG.md geüpdatet

---

## Anti-patterns

- ❌ "Accessibility doe ik later." → Later betekent post-rejection of post-bad-review.
- ❌ Alleen testen in Light mode. → Helft van je users zit in Dark.
- ❌ Hardcoded font-sizes. → Dynamic Type is verplicht voor App Store-acceptatie.
- ❌ Animaties zonder Reduce Motion-check. → Misselijkheidsklachten in reviews.

---

## Tips

- Zet je telefoon vandaag op grootste Dynamic Type. Werk er een uur mee. Je vindt 80% van de issues meteen.
- VoiceOver-test: doe je hele primaire flow met scherm uitgeschakeld (zwarte gordijn-modus). Lukt dat? Goed.
- Localizable.xcstrings (Xcode 15+) is veel beter dan losse `.strings`-bestanden — gebruik dat.

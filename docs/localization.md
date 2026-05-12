# localization.md — Localization Diepte-gids

> **Doel:** lokalisatie die verder gaat dan strings vertalen — pluralization, RTL, locale-aware formatting, currency edge cases.
> **Wanneer raadplegen:** Fase 7 (UX-polish), elke nieuwe taal-toevoeging.
> **Hoort bij:** `phases/07-polish-accessibility.md`.

---

## 1. String Catalogs (xcstrings) — Xcode 15+

**Vervangt** `.strings` en `.stringsdict` files. Eén bestand voor alle talen, plurals, vars.

### Setup

1. Project → File → New → String Catalog → `Localizable.xcstrings`
2. In code:
```swift
Text("welcome.title")  // key, geen string
Text(.init("send_message_button"))
```
3. Xcode detecteert automatisch nieuwe keys bij build.

### Pluralization

```swift
Text("\(count) item(s)")
```

Xcode geneert dan in xcstrings:
```json
{
  "%lld item(s)": {
    "extractionState": "manual",
    "localizations": {
      "en": {
        "variations": {
          "plural": {
            "one": { "stringUnit": { "value": "%lld item" } },
            "other": { "stringUnit": { "value": "%lld items" } }
          }
        }
      },
      "nl": {
        "variations": {
          "plural": {
            "one": { "stringUnit": { "value": "%lld item" } },
            "other": { "stringUnit": { "value": "%lld items" } }
          }
        }
      }
    }
  }
}
```

**Talen met meer plural-categorieën** (Russisch, Pools, Arabisch): `zero`, `one`, `two`, `few`, `many`, `other`. Xcode toont alle relevante per taal.

---

## 2. Locale-aware formatting

### Datums

```swift
// ❌ Fout — hardcoded format
let formatter = DateFormatter()
formatter.dateFormat = "dd/MM/yyyy"

// ✅ Goed — Apple's FormatStyle
let date = Date()
let formatted = date.formatted(date: .long, time: .shortened)
// EN: "March 5, 2026 at 2:30 PM"
// NL: "5 maart 2026 om 14:30"
// JA: "2026年3月5日 14:30"
```

### Numbers

```swift
let count = 1234567.89
count.formatted()
// EN: "1,234,567.89"
// NL: "1.234.567,89"
// DE: "1.234.567,89"
// FR: "1 234 567,89"
```

### Currency

```swift
let amount = Decimal(string: "1234.50")!
amount.formatted(.currency(code: "EUR"))
// EN: "€1,234.50"
// NL: "€ 1.234,50"
```

**Currency-edge cases:**
- **JPY** (Yen): geen decimalen — `¥1234`, niet `¥1234.00`
- **BHD** (Bahraini Dinar): drie decimalen
- **CLP** (Chilean Peso): geen decimalen
- Vertrouw `FormatStyle.currency` — die weet dit.

### Relative dates

```swift
let earlier = Date().addingTimeInterval(-3600)
earlier.formatted(.relative(presentation: .named))
// EN: "1 hour ago" / "yesterday"
// NL: "1 uur geleden" / "gisteren"
```

### Lists

```swift
let names = ["Alice", "Bob", "Charlie"]
names.formatted(.list(type: .and))
// EN: "Alice, Bob, and Charlie"
// NL: "Alice, Bob en Charlie"
```

### Measurements

```swift
let distance = Measurement(value: 5, unit: UnitLength.kilometers)
distance.formatted()
// EN-US: "3.107 mi"  (auto-converted to imperial!)
// EN-GB: "5 km"
// NL: "5 km"
```

---

## 3. RTL — Right-to-Left

Talen: Arabisch, Hebreeuws, Perzisch, Urdu.

### SwiftUI doet veel automatisch

- `HStack` flipt naar RTL in RTL-locale
- `.leading` / `.trailing` flippen mee
- Terug-knop verschijnt rechts
- Tekst-alignment volgt taal

### Wat NIET automatisch flipt

- **Custom layouts** met `.frame(alignment: .leading)`
- **Hardcoded `Image(systemName: "arrow.right")`** — gebruik `arrow.forward` (auto-flips)
- **Animaties** met `.offset(x:)` — overweeg `.offset(x: layoutDirection == .rightToLeft ? -10 : 10)`
- **Gestures** (swipe-from-left dichtklappen → wordt swipe-from-right in RTL)

### Test op RTL

```bash
# Run met RTL forced
xcrun simctl launch booted com.company.app -AppleLanguages '(ar)'
```

Of in Xcode scheme: Edit Scheme → Run → Options → App Language → "Right-to-Left Pseudo Language"

---

## 4. Locale-aware sorting

```swift
// ❌ Fout — bytewise sorting
let names = ["Émile", "Anna", "Zoë"].sorted()
// ["Anna", "Zoë", "Émile"]  — accenten komen achteraan

// ✅ Goed — locale-aware
let sorted = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
// In FR: ["Anna", "Émile", "Zoë"]
// Voorbij ASCII-order
```

---

## 5. Pseudolocalization — onthul fragility

Test je UI met verlengde, gemarkeerde strings:

- Settings → Developer → Show non-localized strings: visualiseert hardcoded text
- Edit Scheme → App Language → "Double-Length Pseudolanguage": elke string wordt verdubbeld

Vangt:
- Hardcoded strings (blijven Engels)
- Te krap-gemodelleerde UI (Duitse vertalingen zijn vaak 30% langer)
- Layout-bugs bij ongewone tekst

---

## 6. Strings buiten code

### Info.plist localized strings

`InfoPlist.xcstrings` voor Info.plist-keys (privacy descriptions!):

```
NSCameraUsageDescription:
  en: "We need camera access to take profile photos."
  nl: "We hebben cameratoegang nodig om profielfoto's te maken."
  fr: "Nous avons besoin d'accéder à la caméra pour prendre des photos de profil."
```

### App-naam per locale

```
CFBundleDisplayName:
  en: "ChatHub"
  nl: "ChatHub"  // meestal niet vertalen
  ja: "チャットハブ"  // wel transliteratie
```

---

## 7. Translatie-workflow

### Klein (1-2 talen)

- Vertaal zelf of via een vertaler.
- Reviewers in de doel-taal zijn cruciaal — zelfde woord kan formal/informal verschillen.

### Middel (3-10 talen)

- Tools: Crowdin, Lokalise, POEditor.
- Export xcstrings → naar tool → vertalingen → import terug.
- Houd `Translation Memory` — herhaalde strings zelfde vertaling.

### Groot (10+ talen)

- Continue lokalisatie (CI-integratie).
- Glossary voor product-termen.
- Quality assurance per taal.

### AI-vertalingen

Workflow: AI-vertaling → human review per taal. Pure machine-vertalingen halen App Review niet — Apple checkt op natuurlijkheid in populaire talen.

---

## 8. Tekst-expansie verwachtingen

Vergeleken met Engels:

| Taal | Gemiddelde uitbreiding |
|------|----------------------|
| Duits | +30% |
| Frans | +20% |
| Spaans | +25% |
| Nederlands | +15% |
| Russisch | +30% |
| Japans | -10% (compacter) |
| Chinees | -25% (compacter) |
| Arabisch | +25% + RTL |

**Implicatie:** ontwerp UI die mee schaalt. Vermijd hardcoded breedtes voor labels.

---

## 9. Veelvoorkomende valkuilen

### String concatenation

```swift
// ❌ Fout — werkt niet in talen waar woordvolgorde anders is
Text(NSLocalizedString("welcome", comment: "")) + Text(", ") + Text(name) + Text("!")

// ✅ Goed — interpolatie in één string
Text("welcome_user_format \(name)")
// xcstrings: "Hello, %@!"
// Talen kunnen woordvolgorde aanpassen
```

### Genus / geslacht

Sommige talen vereisen geslachts-bewuste vertalingen (Frans, Spaans, Duits, etc.):
```
You completed it.
→ Tu l'as terminé. (m)
→ Tu l'as terminée. (f)
```

xcstrings ondersteunt dit via `device variations` of `device + plural`.

### Capital letters

Duits kapitaliseert alle nouns. Engels niet. Nooit auto-uppercase op locale-onbekende strings:

```swift
// ❌ Fout
Text(name).textCase(.uppercase)
// In Türkse locale: 'i' → 'İ' (met punt). Andere talen: zonder punt. Bug!
```

---

## 10. Test-matrix

Voor elke release minimaal testen:

| Locale | Wat te checken |
|--------|---------------|
| **EN-US** | Default, sanity check |
| **NL** | Diakrieten, langere strings |
| **DE** | Lange strings (uitbreiding) + capitalization rules |
| **JA** | Compacte strings, zonder spaces tussen woorden |
| **AR** | RTL layout, bidirectional tekst |
| **Pseudo (Double Length)** | UI-fragility |

---

## 11. Anti-patterns

- ❌ Hardcoded strings in Swift `Text("Hello")`. → Gebruik string keys.
- ❌ Hardcoded `DateFormatter` met `dateFormat`. → Use `FormatStyle`.
- ❌ String concatenation voor zinnen. → Use interpolated full sentences.
- ❌ "Translate later". → Het wordt niet later. Ontwerp meertalig vanaf dag 1.
- ❌ Engels-only screenshots in App Store. → Minder downloads in non-EN-markten.
- ❌ Pure machine-translation submissie. → Apple kan rejecten voor "betekenisloze" content.

---

## 12. Checklist per release

- [ ] Alle nieuwe strings in xcstrings, niet hardcoded
- [ ] Plural-varianten ingevuld voor count-strings
- [ ] Locale-aware formatting (dates, numbers, currency)
- [ ] `arrow.forward` ipv `arrow.right` voor RTL-flippable icons
- [ ] InfoPlist privacy descriptions gelocaliseerd
- [ ] Pseudolocalization run zonder layout-breuk
- [ ] RTL-test op één RTL-locale
- [ ] Screenshots gelocaliseerd indien UI-tekst zichtbaar
- [ ] Geen string concatenation voor zinnen

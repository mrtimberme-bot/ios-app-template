# data-migration.md — Persistence & Schema Migrations

> **Doel:** veilig migreren van persistent storage tussen app-versies zonder data-loss en zonder crashloops.
> **Wanneer raadplegen:** Fase 4 (kiezen storage layer), elke release waar het schema verandert, productie-incidents.
> **Hoort bij:** `architecture.md` §1 (Core domain models), `release-management.md` (rollback procedures).

---

## 1. Waarom dit zo cruciaal is

**Migration-bugs zijn de #1 reden** waarom apps na een update crashloops hebben. Eén keer een veld type wijzigen zonder migration → 100% van bestaande gebruikers crash op launch → hard rejection bij update of expedited review nodig.

Schema-veranderingen die ALTIJD migration vereisen:
- Nieuw verplicht veld toevoegen
- Veld-type wijzigen (String → Int)
- Veld renamen
- Relatie toevoegen/verwijderen
- Entity verwijderen
- Required ↔ Optional wijzigen

Schema-veranderingen die meestal géén migration nodig hebben:
- Nieuw optional veld toevoegen
- Index toevoegen
- Compute-property toevoegen

---

## 2. SwiftData migrations (iOS 17+)

SwiftData heeft `VersionedSchema` + `SchemaMigrationPlan`:

```swift
// V1
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Conversation.self] }

    @Model class Conversation {
        var title: String
        var createdAt: Date
        init(title: String, createdAt: Date) {
            self.title = title
            self.createdAt = createdAt
        }
    }
}

// V2 — voegt 'isPinned' toe (lightweight)
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Conversation.self] }

    @Model class Conversation {
        var title: String
        var createdAt: Date
        var isPinned: Bool = false  // default → lightweight
        // ...
    }
}

// V3 — splitst 'title' op in 'title' + 'subtitle' (custom)
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [Conversation.self] }

    @Model class Conversation {
        var title: String
        var subtitle: String?
        // ...
    }
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { context in
            let conversations = try context.fetch(FetchDescriptor<SchemaV2.Conversation>())
            for old in conversations {
                let parts = old.title.split(separator: ":", maxSplits: 1)
                old.title = String(parts[0])
                // subtitle wordt in didMigrate gezet als Schema V3 actief is
            }
            try context.save()
        },
        didMigrate: nil
    )
}
```

**Belangrijke regels:**

- **Versie nummers strikt opvolgend.** Geen versies overslaan.
- **Eén migration per release.** Niet 3 schema-wijzigingen tegelijk doorvoeren.
- **Lightweight waar kan, custom waar moet.** Custom migrations zijn 10× foutgevoeliger.

---

## 3. Core Data migrations

Voor pre-iOS-17 of complexere domains:

**Lightweight migration:**
- Xcode → Editor → Add Model Version
- Maak nieuwe `.xcdatamodel` versie current
- Inferred mapping aan in persistent store options:

```swift
let options = [
    NSMigratePersistentStoresAutomaticallyOption: true,
    NSInferMappingModelAutomaticallyOption: true
]
```

**Heavy migration:**
- Maak `Mapping Model` (`.xcmappingmodel`) tussen versies
- Custom `NSEntityMigrationPolicy` voor logica
- Test op kopie van productie-data **vóór** je release

---

## 4. GRDB migrations

```swift
var migrator = DatabaseMigrator()

migrator.registerMigration("v1") { db in
    try db.create(table: "conversation") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("title", .text).notNull()
    }
}

migrator.registerMigration("v2_add_isPinned") { db in
    try db.alter(table: "conversation") { t in
        t.add(column: "isPinned", .boolean).notNull().defaults(to: false)
    }
}

try migrator.migrate(dbQueue)
```

**GRDB-voordeel:** migrations zijn imperatieve SQL, makkelijk te begrijpen, voorspelbaar.

---

## 5. Test-strategie voor migrations

**Verplicht voor elke migration:**

1. **Unit test op een lege store** — start met V1, migreer naar Vn, verifieer schema.
2. **Unit test op een gevulde store** — vul V1 met test-data, migreer, verifieer dat data bestaat en correct getransformeerd is.
3. **Edge cases:**
   - Lege store
   - Lege strings, nil-values
   - Maximum-size data (lange strings, veel rows)
   - Corrupte data (kan productie hebben — wees defensief)
4. **Test op kopie van productie-data** vóór release. Vraag een power-user om hun database-bestand.

```swift
final class MigrationTests: XCTestCase {
    func test_v1_to_v3_with_data() throws {
        let url = createV1Store(with: [
            ("First: Subtitle", Date()),
            ("Second", Date())
        ])

        let container = try ModelContainer(
            for: SchemaV3.Conversation.self,
            migrationPlan: AppMigrationPlan.self,
            configurations: ModelConfiguration(url: url)
        )

        let context = ModelContext(container)
        let results = try context.fetch(FetchDescriptor<SchemaV3.Conversation>())

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.title, "First")
        XCTAssertEqual(results.first?.subtitle, "Subtitle")
        XCTAssertEqual(results.last?.title, "Second")
        XCTAssertNil(results.last?.subtitle)
    }
}
```

---

## 6. Backup vóór migration

Voor risico-volle migrations: maak backup vóór, restore bij failure.

```swift
public actor MigrationGuard {
    public func performMigration(at storeURL: URL) async throws {
        let backupURL = storeURL.appendingPathExtension("backup")
        try FileManager.default.copyItem(at: storeURL, to: backupURL)

        do {
            try await actuallyMigrate(storeURL)
            try? FileManager.default.removeItem(at: backupURL)
        } catch {
            // Restore backup
            try? FileManager.default.removeItem(at: storeURL)
            try FileManager.default.moveItem(at: backupURL, to: storeURL)
            throw MigrationError.failed(underlying: error)
        }
    }
}
```

**Trade-off:** verdubbelt disk-usage tijdens migration. Acceptabel voor de meeste apps (tenzij gebruikers GB's data hebben).

---

## 7. Telemetry rond migrations

Log naar je analytics:

- `migration.started` (from_version, to_version)
- `migration.completed` (duration_ms, rows_migrated)
- `migration.failed` (from_version, to_version, error_type, error_message)

Bij failure-piek na release: weet je binnen 24 uur dat er iets mis is, niet pas via App Store reviews.

---

## 8. Rollback-strategie

**Wat als migration faalt voor een grote groep gebruikers?**

iOS heeft **geen automatic downgrade**. Je kunt geen oude app-versie pushen. Wat wel:

1. **Phased Release Rollout** in App Store Connect — start releases bij 1%, schaal op naar 100% over 7 dagen. Als crashes piek bij 1%, **pauzeer** je rollout.
2. **Expedited Review** voor hotfix-release — Apple keurt sneller goed bij kritieke productie-issues.
3. **Feature flag** in nieuwe build die problematische code-pad uitzet (zie `architecture.md` §15 hopelijk... eh, kill-switches in `phases/02`).
4. **Server-side fallback** — als migration faalt, gebruik tijdelijk in-memory of cached data tot fix beschikbaar is.

Zie `release-management.md` voor volledige incident-procedure.

---

## 9. Anti-patterns

- ❌ Schema wijzigen zonder version bump. → Bestaande gebruikers crashen op launch.
- ❌ Eén release met 4 schema-wijzigingen. → Onmogelijk te debuggen welke step faalt.
- ❌ Migration alleen op simulator testen. → Productie-data heeft edge cases die simulator niet heeft.
- ❌ Geen migration test op gevulde store. → Lege store-test garandeert niets.
- ❌ Custom migration zonder backup. → One-way ticket bij failure.
- ❌ Vertrouwen op "dit veld kan niet leeg zijn". → Productie heeft alles.

---

## 10. Checklist voor elke release met schema-wijziging

- [ ] Versie nummer schema bumped
- [ ] Migration plan registreert nieuwe stage
- [ ] Unit test op lege store
- [ ] Unit test op gevulde store
- [ ] Test op productie-database-kopie (van power-user of TestFlight-tester)
- [ ] Backup-mechanisme actief tijdens migration
- [ ] Telemetry events (started/completed/failed) gelogd
- [ ] Phased Release Rollout aan in App Store Connect
- [ ] Hotfix branch klaar in geval van crash-piek
- [ ] Feature flag voor problematische features actief

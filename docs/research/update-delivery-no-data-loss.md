# Research: delivering updates without data loss

Ticket: [#5](https://github.com/nicolasbiscotti/economic-analysis/issues/5) · Map: [#1](https://github.com/nicolasbiscotti/economic-analysis/issues/1) · Researched 2026-11-14

**Question.** What are the established practices for delivering app updates (store releases, OTA/JS updates, web deploys) without users ever losing data? This covers on-device schema migrations and how to test them; clients on different app versions syncing against one backend; rollback safety; store rules on OTA; and backup/export as a safety net.

Every claim below cites the primary source it comes from. Lines marked **Inference** are our own reasoning, not something a source says.

---

## 1. The core fact: you never control which version is running

Every delivery channel leaves old versions running in the field for a long, open-ended time:

- **App stores roll out gradually and can't un-ship.** Apple's phased release goes 1% → 2% → 5% → 10% → 20% → 50% → 100% over 7 days and only covers *automatic* updates. "apps and app updates in phased release can be manually downloaded from the App Store by anyone at any time." You can pause for up to 30 days in total. ([Apple, phased release](https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases/)) On Google Play, halting a staged rollout stops new users from getting the version, but "Users who already received the app version in your staged rollout version will remain on that version". The fix Google suggests is a new release. ([Play Console Help, staged rollouts](https://support.google.com/googleplay/android-developer/answer/6346149))
- **The web is not instant either.** A new service worker waits until every tab controlled by the old one has closed. `skipWaiting()` means "your new service worker is likely controlling pages that were loaded with an older version". Mixed versions sharing storage "can result in errors, or worse, data loss." Also: "You may not be updating from the previous version. It may be a service worker many versions old." ([web.dev, service worker lifecycle](https://web.dev/articles/service-worker-lifecycle))
- **IndexedDB blocks upgrades across tabs.** When an open connection at the old version exists, the new version's `open()` fires `blocked` and waits. The old connection has to close in its `versionchange` handler. ([MDN, blocked event](https://developer.mozilla.org/en-US/docs/Web/API/IDBOpenDBRequest/blocked_event))

**Inference:** Every migration and every sync-protocol change has to assume that (a) a device may jump from any old schema version straight to the newest, and (b) old and new clients write to the same backend at the same time, for weeks or longer.

## 2. On-device schema migrations

**The incremental, versioned, all-paths-tested pattern** (Android Room is the best-documented first-party example. The ideas carry over to any SQLite or IndexedDB stack):

- Declare migrations per version step, automatic or manual. A missing path throws `IllegalStateException`. Do **not** set `fallbackToDestructiveMigration`: it "*permanently deletes all data*" when a path is missing. ([Android, Room migrations](https://developer.android.com/training/data-storage/room/migrating-db-versions))
- Export schema JSON at every version and "Store these files in your version control system so that you can recreate lower versions of the database for testing". (same source)
- Test each step. Seed data at version N with raw SQL ("You can't use DAO classes because they expect the latest schema"), migrate, then check both the schema *and* that the data survived. Also "include a test that covers all migrations", which catches drift between a fresh install and an upgraded one. (same source)
- Write migrations as literal SQL rather than shared constants: "use full queries instead of referencing constants that represent the queries." (same source) **Inference:** a migration is a frozen historical artifact, so it must not change when app code changes.

**SQLite specifics** (relevant to any local-first SQLite stack: Expo SQLite, op-sqlite, PowerSync, wa-sqlite on web):

- `ALTER TABLE` only supports rename table/column, add column (with restrictions), drop column (with restrictions), and set/drop NOT NULL. Anything else uses the **12-step procedure**: `foreign_keys=OFF` → `BEGIN` → create `new_X` → copy → drop `X` → rename `new_X`→`X` → recreate indexes/triggers/views → `PRAGMA foreign_key_check` → `COMMIT` → `foreign_keys=ON`. Renaming the old table first is marked *incorrect* because it can corrupt references. ([SQLite, ALTER TABLE](https://www.sqlite.org/lang_altertable.html))
- **Inference:** SQLite DDL is transactional, so each migration step can be atomic. A crash mid-migration then leaves the previous version intact rather than a half-migrated database.

**Sync-engine variant:** PowerSync's client schema "is just a view on top of the schemaless data", so client schema changes need "no client-side migrations". The developer still has to keep them "backwards-compatible with older versions of client apps", and "Nothing in PowerSync will fail hard if there are incompatible schema changes". App logic can still break. ([PowerSync, implementing schema changes](https://docs.powersync.com/maintenance-ops/implementing-schema-changes)) **Inference:** a sync engine moves the migration problem; it does not remove it. Compatibility between data shapes in the field still has to be designed.

## 3. Mixed client versions against one backend

- **Additive changes are safe, breaking ones need versioning.** PowerSync: with additive changes "old clients ignore the new tables and columns, and no special handling is required". Breaking changes need parallel versioned streams, chosen by a client-sent `schema_version` parameter. Keep the old stream until "the older app versions are no longer in use". The parameter is client-controlled, so "not a good place to do authorization". ([PowerSync, multiple client versions](https://docs.powersync.com/sync/advanced/multiple-client-versions.md))
- **Send a schema version from day one.** Replicache passes `schemaVersion` in every push and pull: "Consider setting the `schemaVersion` from the start so that you don't later have to special case the 'no schemaVersion' case." On write operations (mutators): "Replicache does not handle mutator versioning". To change a mutator's signature "you must choose a new name". ([Replicache, launch checklist](https://doc.replicache.dev/howto/launch)) The server can reply `VersionNotSupported`, and the client then calls `onUpdateNeeded` (from the published type definitions, [replicache.d.ts](https://cdn.jsdelivr.net/npm/replicache@15.3.0/out/replicache.d.ts)).
- **The general compatibility rules** ([Google AIP-180](https://google.aip.dev/180)): you may add fields and enum values. "New required fields **must not** be added". Fields must not be removed or renamed (a rename counts as remove + add). Types must not change. "Changing the default value is considered breaking".
- **Inference (local-first specific):** an offline client may hold *queued writes made by an old version* and upload them after the server has moved on, possibly after the user has upgraded the app. The backend must keep accepting every write shape that any supported client version could have queued. That is the real definition of "minimum supported version" for a sync backend.
- **Forced updates / minimum version:**
  - Android has a first-party "immediate" in-app update flow: full screen, the user must update to continue. A "flexible" flow downloads in the background. ([Android, in-app updates](https://developer.android.com/guide/playcore/in-app-updates))
  - iOS has no equivalent first-party API that we found. **Inference:** iOS forced updates are app-built (a server-provided minimum version plus a blocking screen linking to the App Store).
  - On the sync side the mechanism is the server rejecting unsupported versions (Replicache `VersionNotSupported` above).
  - **Inference:** a forced update should block *new* work but still let the client upload its queued writes, or keep them locally until after the upgrade. Otherwise forcing the update itself becomes a data-loss path.

## 4. OTA updates: what the stores allow

- **Apple, Developer Program License Agreement §3.3.1(B):** "an Application may not download or install executable code. Interpreted code may be downloaded to an Application but only so long as such code: (a) does not change the primary purpose of the Application by providing features or functionality that are inconsistent with the intended and advertised purpose of the Application (b) does not bypass signing, sandbox, or other security features of the OS; and (c) for Applications distributed on the App Store, does not create a store or storefront for other Applications." ([Apple DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/))
- **Apple, App Review Guideline 2.5.2:** apps may not "download, install, or execute code which introduces or changes features or functionality of the app". Guideline 2.3.12: significant changes must be listed in "What's New". ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)) **Inference:** together these mean OTA JS is fine for fixes and small changes, while new features should go through review.
- **Google Play, Device and Network Abuse policy:** an app "may not modify, replace, or update itself using any method other than Google Play's update mechanism" nor "download executable code (such as dex, JAR, .so files)". This does not cover "code that runs in a virtual machine or an interpreter … (such as JavaScript in a webview or browser)". ([Play policy](https://support.google.com/googleplay/android-developer/answer/9888379))
- **Expo EAS Update:**
  - Expo's own FAQ says updates "need to follow the App Store and Play Store guidelines… changes to your app's behavior need to be reviewed."
  - These cannot ship OTA: native code or dependencies, permissions, Expo SDK upgrades. ([EAS Update FAQ](https://docs.expo.dev/eas-update/faq/))
  - The runtime version gates which native builds accept which updates. The `fingerprint` policy changes it whenever anything native changes, which makes incompatible updates "very unlikely". ([Runtime versions](https://docs.expo.dev/eas-update/runtime-versions/))
- **CodePush is gone as a hosted service:** App Center retired on March 31, 2025. Microsoft offers a standalone, self-hosted [code-push-server](https://github.com/microsoft/code-push-server) as the alternative. ([Microsoft Learn, App Center retirement](https://learn.microsoft.com/en-us/appcenter/retirement))

## 5. Rollback safety

- **Store binaries:** no rollback. Users who updated stay on that version (Play, above). Android treats a downgrade as needing explicit handling: Room offers `fallbackToDestructiveMigrationOnDowngrade`, which is again destructive ([Room](https://developer.android.com/training/data-storage/room/migrating-db-versions)).
- **EAS Update:** `eas update:rollback` republishes a previous update, or tells clients to run the embedded one ([Rollbacks](https://docs.expo.dev/eas-update/rollbacks/)). Automatic error recovery only rolls back if the update crashes *before content first appears*. After that it only moves forward, because the code "may… have modified persistent state". Rollback "is only safe" if the broken update didn't change persistent state in a non-backwards-compatible way. Test "in a staging environment that closely matches an end user's device state", both when loading the bad update and when rolling back. ([Error recovery](https://docs.expo.dev/eas-update/error-recovery/))
- **Inference (synthesis):** rollback is only safe when no deploy combines "new code" with "irreversible data change". The established way to get there is **expand → migrate → contract**, the same order PowerSync documents (allow the new shape, migrate data, then tighten the schema; [implementing schema changes](https://docs.powersync.com/maintenance-ops/implementing-schema-changes)):
  1. Release N adds the new schema and keeps reading/writing the old one.
  2. Release N+1 switches over.
  3. A later release removes the old schema, once N-1 is below the minimum supported version.

  With this, any OTA, web, or server rollback by one step lands on code that understands the data on disk.

## 6. Backup and export as the safety net

- **Android Auto Backup:**
  - On by default (`allowBackup=true`). Includes `getDatabasePath()` files. Limit is 25 MB per app; if exceeded, nothing is backed up.
  - Runs roughly daily, and only when idle, on Wi-Fi, and enabled. "a device might never back up". Only the latest backup is kept.
  - Restore happens on reinstall, before first launch. ([Android Auto Backup](https://developer.android.com/identity/data/autobackup))
  - **Inference:** a restored database may be from an older schema version, so the migration path from every past version must keep working.
- **iOS iCloud Backup:** includes app data. Caches and tmp are excluded. `isExcludedFromBackup` is "not a mechanism to guarantee" exclusion. Don't exclude user-created data that "might be difficult, even impossible, for the user to re-create". ([Apple, optimizing app data for iCloud backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup))
- **Web storage can be evicted:**
  - Default storage is "best-effort". `navigator.storage.persist()` opts in to being evicted only by the user, but Chromium and Safari grant or deny it silently, based on how the user engages with the site. ([MDN, storage quotas and eviction](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria))
  - Safari deletes all script-writable storage (IndexedDB, Cache, SW registrations) "after seven days of Safari use without user interaction on the site". Home-screen web apps "have their own counter of days of use", and WebKit does "not expect" their first-party data to be deleted. ([WebKit blog](https://webkit.org/blog/10218/full-third-party-cookie-blocking-and-more/))
  - **Inference:** on the web, local-only data is not durable. The synced server copy is the real backup, so unsynced web writes are the main data-loss risk.
- **Inference:** OS backups are opportunistic, per-device, and opaque to the user. A user-triggered export in an open, versioned format (with a matching import) is the only safety net the app fully controls, and it doubles as a recovery path if a migration bug ships. Android 16 QPR2 adds a `contentVersion` to cross-platform transfers so data formats can be versioned ([Auto Backup](https://developer.android.com/identity/data/autobackup)), which is the same idea.

---

## Inputs for the later policy decision (not the decision)

Questions the update/migration ADR will need to answer, with the facts above as constraints:

1. **Minimum supported version window.** How long must the backend accept old clients' reads *and queued writes*? Facts: rollouts take ≥7 days, Play can't recall a version, and offline clients may upload late.
2. **Schema/protocol version on the wire from day one?** Replicache and PowerSync both recommend it, and retrofitting it is costly.
3. **Expand/contract as a rule.** Should every breaking data change take ≥2 releases (expand, then contract) so any single-step rollback is safe?
4. **What may ship OTA.** Fixes and small changes only, versus features through store review (Apple §3.3.1(B) and 2.5.2, Expo FAQ). Should the runtime version use the `fingerprint` policy?
5. **Forced-update mechanism.** Android immediate in-app update; iOS app-built; sync server returns "version not supported". Rule: never drop unsynced local writes when forcing.
6. **Migration test bar.** Exported schema snapshots per version in VCS; a test per step plus an all-versions-to-latest test with seeded data, on each platform's storage (SQLite on mobile, IndexedDB/OPFS on web). A restore-from-old-backup test.
7. **Destructive fallbacks banned?** E.g. lint or forbid `fallbackToDestructiveMigration`-style options and "reset local DB on error" handlers.
8. **Web durability.** Request `navigator.storage.persist()`, nudge install-to-home-screen on iOS, and surface "unsynced changes" state to the user.
9. **Backup/export.** Whether v1 ships a user export, in which format, versioned and importable. This is listed under "Not yet specified" on the map.
10. **Choice of sync engine.** Its schema-change model (view-over-schemaless vs. client migrations) shapes questions 1–3. It feeds into the data storage & sync ADR.

## Gaps / not verified

- No first-party Apple API for forcing app updates was found. The claim is based on absence, not on an explicit Apple statement.
- Replicache's `VersionNotSupported` comes from published type definitions, not from a current prose reference page.
- Other sync vendors' migration guides (ElectricSQL, Triplit, Automerge, CouchDB/PouchDB, RxDB) were not reviewed. Do that once a shortlist exists.

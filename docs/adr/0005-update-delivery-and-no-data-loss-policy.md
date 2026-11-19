# Update delivery and no-data-loss policy

Old app versions stay in use on every channel: store releases can't be recalled, web tabs stay open, and an offline phone uploads writes it queued under an old version weeks later. So the backend never assumes clients are current. Instead, it accepts every **data version** at or above a minimum supported one, and nothing on any path is ever discarded: writes it can't apply are parked, never dropped. We rejected a single-release breaking change (simpler, but it loses queued offline writes) and a fixed calendar window (it cuts off devices regardless of whether they are still in use). Supabase Free has no backups ([ADR 0003](./0003-server-authoritative-sync-with-powersync-and-postgres.md)), so we run our own. Research: [delivering updates without data loss](https://github.com/nicolasbiscotti/economic-analysis/blob/research/update-delivery-no-data-loss/docs/research/update-delivery-no-data-loss.md).

## Version compatibility

- **Data version**: every upload and sync connection carries one integer, the shape of the domain records, starting at `1`. It is separate from the app version and the Expo runtime version, and rises only when old clients can no longer read or write the records as they are.
- **Minimum supported data version**: the server accepts writes from any data version at or above it and upcasts them to the current shape in the domain package. Writes it cannot apply are **parked** on the server, never discarded, so they can be replayed later.
- **Raising the minimum** is a manual decision by a developer, never automatic. Checklist: a saved query over the sync logs shows no device below the new minimum has connected in the last 90 days, the upcasters being retired have replay tests, and the change is noted in the release.
- **Below the minimum**: the backend answers "update required" in the sync handshake and in the response to its uploads. The app becomes **read-only**: the person can still see and export their data, queued writes are still uploaded (and parked), and a banner points to the update (Play's immediate in-app update on Android, the App Store page on iOS, a reload on web). The person is never locked out of their data.

## Changing the data shape

- **Expand → migrate → contract** for every breaking change, across separate releases: add the new shape and accept both, backfill, and remove the old shape only once the minimum supported data version is past the expand release.
- **Wire rules** (after Google's AIP-180): never remove or rename a field in place, never add a new required field, never change a field's meaning, type or default in place. Add a new field instead.
- **Every release is safe to roll back**: going back to the previous OTA update or web deploy must not break data the bad release wrote. A contract step ships alone, in a release with nothing else in it.

## On the device

- Synced tables need no migrations: PowerSync stores synced rows schemaless and the client schema is a view over them.
- Local-only tables get one non-destructive migration per version step.
- **Destructive resets are banned**: no "drop and recreate the local database" fallback. A local replica may be rebuilt from the server only once its upload queue is empty; otherwise the pending writes are exported first.

## Delivery channels

- **OTA (EAS Update)** carries JavaScript only. `runtimeVersion` uses the `fingerprint` policy, so any native change needs a new store build and an update is only offered to builds it fits. OTA may carry bug fixes and features within the app's existing purpose; new permissions, native modules and Expo SDK upgrades go through the stores.
- **Channels**: `preview` (developers' devices) and `production`. Production updates roll out in stages (for example 10% → 100%).
- **Store binaries** can't be rolled back; a bad one is fixed with an OTA patch or a new build.
- **Web** deploys on every merge to `main`. An open old tab notices the new version and offers a reload; it never reloads on its own. Unsynced writes survive a reload because they live in the local database.

## Safety nets

- **Server backups**: a daily `pg_dump` from a scheduled GitHub Action, encrypted with age, stored off-site in Cloudflare R2. Keep 30 daily and 12 monthly dumps. A weekly CI **restore drill** restores the latest dump into a throwaway Postgres and checks row counts and the latest change-history timestamp; a failed drill is an alert. The append-only change history from ADR 0003 covers logical mistakes without a full restore.
- **Export**: v1 lets the person export one versioned JSON file per Ledger, with a format version and every record including soft-deleted ones and their ids, so a later import can read it. Import is not in v1.

## Required release tests

1. Every Postgres migration runs against seeded data from the previous version.
2. A fixture of queued writes from every supported data version is replayed against the new server and must apply or park, never fail silently.
3. The restore drill passes.
4. Once a second data version exists: an old-build-against-new-backend smoke test using the in-process spec adapter pinned to the previous data version.

## Consequences

- Each data version bump costs an upcaster plus replay fixtures, kept until the minimum passes it.
- Parked writes need a developer tool to inspect and replay them.
- The sync logs must record each device's data version and last connection, from v1.

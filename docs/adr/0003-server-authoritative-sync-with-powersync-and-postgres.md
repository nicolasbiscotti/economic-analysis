# Server-authoritative sync with PowerSync and Postgres

Every device (phone and web) holds a full local SQLite replica of the person's data and works offline. Writes queue on the device and drain through PowerSync into our own write endpoint, which validates them and applies them to Postgres, the single source of truth (hosted on Supabase). We chose this over Firestore (per-document last-write-wins, high lock-in, paid export), CouchDB/PouchDB (one database per share, no React Native SDK) and CRDTs (no access control yet, which sharing needs), because it is the only option that combines offline writes, a server we control, SDKs for every candidate client stack, and portable data. Research: [local-first storage and sync options](https://github.com/nicolasbiscotti/economic-analysis/blob/research/local-first-sync-options/docs/research/local-first-sync-options.md).

## Rules

- **Conflicts**: per-field last-write-wins, applied by the server. A database trigger appends every change to an append-only change history, so an overwritten value can always be recovered and no code path can change data without leaving history. The history is not shown to the person in v1.
- **Deletes** are soft (the row is marked deleted, never removed), so a delete never silently discards an edit made offline elsewhere.
- **Ids** are generated on the device. Records the person creates (Fixed Expense, Card, Charge, Installment Purchase) get random UUIDv7 ids and are never merged automatically. Records identified by their parent get a deterministic UUIDv5: a Payment from (Fixed Expense, Month), a Statement from (Card, Month), a Statement Balance from (Statement, currency), an Installment from (Installment Purchase, number). The same record created on two devices therefore becomes one record with two edits. Payment and Statement rows are only written once something happens to them; until then they are derived.
- **Rejected writes are never dropped silently**: they are kept on the device and logged on the server, and the person sees what couldn't be saved, with an option to retry or dismiss it. The write endpoint is a Supabase Edge Function that runs the same TypeScript domain rules as the clients, so a rejection only happens on a genuine race, never because client and server disagree.
- **Web** also keeps a replica, but shows unsynced writes as not yet synced and asks for persistent storage where the browser allows it. Mobile is where full offline use is guaranteed.
- **Ownership**: every record belongs to exactly one Ledger, and sync and access rules are written per Ledger. Sharing later means granting a second person access to a Ledger, with no data migration.

## Hosting and portability

- **Hosting**: Supabase Free and PowerSync Cloud Free, kept awake by a scheduled keep-alive (both free tiers pause after about a week of inactivity). **Supabase Free has no backups.** Backups are owned by the update-delivery and no-data-loss decision, not by this one.
- **Own domain**: clients reach the backend only through our own domain (`sync.` / `api.`), never through provider URLs. Old app builds linger, and with our own domain a provider move is a DNS change rather than a forced update.
- **What the core may use**: Postgres, the PowerSync service, our TypeScript write endpoint, and auth. Any other Supabase-specific feature needs its own decision.
- **Exit path**: `pg_dump` into any Postgres, plus self-hosted PowerSync (Apache-2.0, Docker; needs logical replication), on a VPS or a home server. Auth is the stickiest piece, so portability is a criterion for the identity decision.

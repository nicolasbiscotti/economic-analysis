# Research: local-first storage and sync options

Ticket: [#4](https://github.com/nicolasbiscotti/economic-analysis/issues/4) · Map: [#1](https://github.com/nicolasbiscotti/economic-analysis/issues/1) · Researched 2026-11-14

**Question.** What storage + sync options let one person use the app offline on several devices, with free-tier or near-zero hosting, without ruling out sharing between users later?

**Constraints from the map.** One user with phone + web, fully offline on mobile, sharing between users is the first future module, free-tier / near-zero hosting, **no data loss across updates/migrations**, TypeScript preferred, client stack still open (Expo/RN, Capacitor/PWA, Flutter, KMP).

This document gathers comparison inputs. It does not make the decision (that is the stack/sync ADR, #9).

---

## TL;DR

- **Out on hard requirements:**
  - **Zero.** Its docs say it does not support offline writes.
  - **Replicache.** In maintenance mode; the vendor tells users to move to Zero.
  - **InstantDB Cloud.** Signups closed; all cloud apps shut down 2027-08-31.
  - **Triplit.** Dormant: last commit Sep 2025, and the founder joined Supabase in Oct 2025.
- **Strongest fit for "SQL + offline + several SDKs + room to share later": PowerSync on top of Postgres (e.g. Supabase).**
  - Offline writes go into a local SQLite upload queue, and your own backend applies them, so the server has the final say.
  - Client SDKs cover Web, React Native/Expo, Capacitor (beta), Flutter, Kotlin and Swift.
  - The service is Apache-2.0 and self-hostable.
  - On the device, schema changes need no client-side migrations.
  - Caveat: both free tiers (PowerSync Cloud and Supabase) pause or deactivate after about a week of inactivity, and Supabase Free has no backups.
- **Electric** (Apache-2.0, Postgres) only syncs reads. Offline writes are something you build yourself. Its official client is TypeScript only, so there is no Flutter or KMP SDK.
- **Firestore** is the easiest offline setup on native and has a generous free tier. Against it: last-write-wins per document, offline persistence is off by default on web, a 100 MB default cache that evicts old documents, managed export needs the paid Blaze plan, and strong lock-in.
- **CouchDB/PouchDB** never silently loses a conflicting version (all revisions are kept) and has a native replication protocol. Against it: the app must resolve conflicts itself, sharing usually means one database per user or per share, there is no first-party RN adapter, and it is not free to host.
- **CRDT libraries (Automerge, Yjs)** are building blocks, not a database. Automerge's access control ("keyhive") is still "Coming Soon". Yjs targets collaborative text editing. They make sense later, for specific fields such as shared notes, not as the main store for ledger-like data.
- **Also seen, worth a look in the decision ticket:** RxDB (backend-agnostic replication, including Supabase, CouchDB and Firestore), Jazz (built-in permissions/groups), Evolu (end-to-end encrypted SQLite with relays). This research covered them only lightly.

---

## Comparison table

Legend: ✅ good fit · ⚠️ caveat · ❌ blocker for this project.

| Option | Offline model | Conflicts | Multi-user / sharing | Migrations (device / server) | SDKs | Hosting cost (personal) | Lock-in / export |
|---|---|---|---|---|---|---|---|
| **PowerSync** (+ Postgres/Supabase) | ✅ Full local SQLite. Writes queue offline and replay through your backend API | Server-authoritative. The default is field-level LWW with deletes winning, and it can be customised in your backend. CRDT (Yjs) for document fields | ✅ Sync Streams decide which rows each user gets. Writes go through your own API and Postgres RLS | Device: no migration step, because the client schema is a view over schemaless JSON. Server: ordinary Postgres migrations, with caveats on renames/type changes and keeping old clients working | Web, RN/Expo, Capacitor (beta), Flutter, Kotlin, Swift, .NET/Rust (beta), Tauri (alpha) | Cloud Free: 2 GB synced/mo, 500 MB hosted, 50 concurrent clients, **deactivated after about 1–2 weeks inactive**. Pro from $49/mo. Self-host is Apache-2.0 via Docker | ⚠️ Low. Data lives in your own Postgres, and the service is open source |
| **ElectricSQL** | ⚠️ Read-path sync only (Postgres to client "Shapes"). Offline writes are up to you: optimistic state, or a local DB plus change log (PGlite) | You implement it in your write API | Shapes filter rows. Auth through your own proxy/API | Server: Postgres. Device: up to you (PGlite or your own store) | Official TypeScript and Elixir clients. ❌ No Flutter/KMP | Cloud: pay-as-you-go, bills under $5/mo waived, reads/egress free. Self-host Apache-2.0 | Low (Postgres). Repo now lives under the `neondatabase` org |
| **Zero** (Rocicorp) | ❌ "Zero does not support offline writes". Writes are rejected while disconnected | Server-authoritative | Query-level permissions on the server | Postgres | React, React Native | Cloud Zero or self-hosted `zero-cache`. Apache-2.0 | Low (Postgres) |
| **Replicache** | Offline-capable | Server-authoritative (rebase) | Up to you | Up to you | JS | Free, open-sourced | ❌ Maintenance mode: "won't add new features… migrate to Zero" |
| **Triplit** | Offline mode, client DB | Property-level, CRDT-based | Server-enforced authorization | Schemas | JS, React, Svelte | Self-host (AGPL-3.0). Cloud status unclear | ❌ Dormant since Sep 2025. Founder joined Supabase, which says it will not integrate Triplit |
| **InstantDB** | Local cache with optimistic writes | Not documented on the pages read | Permission rules | `instant-cli push`. Backfills are manual | Web, React, RN | ❌ Cloud signups closed. **Cloud shuts down 2027-08-31**. Self-host is Apache-2.0 | Team joined OpenAI |
| **Firestore (offline)** | ✅ Native: persistence on by default. ⚠️ Web: off by default, single-tab unless configured | ⚠️ LWW per document | ✅ Security rules. Sharing through shared docs/collections | Schemaless. Migration is app code on both sides | Web, Android, iOS, Flutter (first party). RN via community `@react-native-firebase` | ✅ Spark (free): 1 GiB stored, 50K reads / 20K writes per day | ❌ High lock-in. Managed export needs Blaze. 100 MB cache evicts old docs (can be set to unlimited) |
| **PouchDB / CouchDB** | ✅ Full local DB that replicates both ways | ✅ Keeps every conflicting revision and picks the same winner on every device. The app merges the rest, so nothing is silently lost | ⚠️ Per-database permissions, so sharing usually means one DB per user or per share | Schemaless documents. Migrations are app code | Browser (IndexedDB), Node, Cordova SQLite adapter. ⚠️ No first-party RN or Flutter | ⚠️ Self-hosted CouchDB (VPS) or a paid managed service. No obvious free tier | ✅ Open protocol, Apache-2.0, easy to export |
| **Supabase + custom sync** | You build it (e.g. RxDB's Supabase replication, or your own pull/push) | You choose (RxDB default: server wins, custom handler possible) | ✅ Postgres RLS | Postgres migrations. The device side is yours | Supabase: JS, Flutter, Swift, Kotlin | Free: 500 MB DB, 50K MAU, 2 projects, **pauses after 1 week inactive**, **no backups** (the docs advise your own `db dump`). Pro $25/mo | Low (plain Postgres) |
| **Automerge** | ✅ Full local copy of each document, network-agnostic | ✅ CRDT auto-merge with history | ❌ Access control ("keyhive") still "Coming Soon" | ⚠️ Schema evolution of CRDT documents is on you | JS/WASM, Rust, C API (iOS). Repo storage: IndexedDB, NodeFS, or a custom adapter (none for RN) | Any relay (self-host) | MIT. Data is in Automerge's binary format |
| **Yjs** | ✅ Local doc plus providers | ✅ CRDT auto-merge | Up to the provider | On you | JS (plus ports) | Self-host or Liveblocks/Y-Sweet | MIT-style. Built for text/collab editing, not relational ledgers |

---

## Per-option notes (with sources)

### PowerSync
- **Backends.** Postgres, MongoDB, MySQL (beta), SQL Server (beta), others. **SDKs:** JS Web, React Native & Expo, Node, Capacitor (beta), Tauri (alpha), Dart/Flutter, Kotlin, Swift, .NET (beta), Rust (beta). [overview](https://docs.powersync.com/intro/powersync-overview)
- **Writes.** Client changes go into an ordered upload queue that "must be sequentially drained against backend API endpoints configured by the developer". Operations must be idempotent. The typical rule is that deletes win and concurrent updates resolve per field, last write wins. Custom resolution is possible. [handling update conflicts](https://docs.powersync.com/usage/lifecycle-maintenance/handling-update-conflicts)
- **Migrations.** The client schema is a view over schemaless JSON: "Updating this client-side schema is immediate when the new version of the app runs", and "Nothing in PowerSync will fail hard if there are incompatible schema changes."
  - Backward compatibility for old clients is your job. Versioned streams can serve different data to different client versions.
  - Postgres DDL is not tracked, so renames look like a drop plus a create, and type changes may require rewriting rows.
  - [implementing schema changes](https://docs.powersync.com/maintenance-ops/implementing-schema-changes.md)
- **CRDTs.** Yjs data can be stored and synced through PowerSync "where last-write-wins is not sufficient". [CRDTs](https://docs.powersync.com/client-sdks/advanced/crdts.md)
- **Pricing.**
  - Free: 2 GB synced/mo, 500 MB hosted, 50 peak concurrent clients.
  - The pricing page says free projects are "deactivated after 1 week of inactivity". Elsewhere on the same page it says 2 weeks. Deactivated instances can be reactivated by hand.
  - Pro from $49/mo.
  - [pricing](https://www.powersync.com/pricing)
- **Licence.** `powersync-service` and `powersync-js` are Apache-2.0 (GitHub API, 2026-11-14). Self-hosting uses the `journeyapps/powersync-service` Docker image, without the hosted dashboard. [self-hosting](https://docs.powersync.com/intro/self-hosting.md)

### ElectricSQL
- A "read-path sync engine for Postgres" built on Shapes, delivered over HTTP. [intro](https://electric.ax/docs/intro)
- **Writes.** Four patterns, all built by you: online writes, optimistic state, shared persistent optimistic state, and through-the-database sync with PGlite plus a change log. Only the last gives full offline support, and it makes rollbacks harder. [writes guide](https://electric.ax/docs/guides/writes)
- **Pricing.** Pay-as-you-go at $1 per 1M writes and $0.10 per GB-month, with bills under $5/mo waived. Reads, egress and fan-out are free. Apache-2.0. [pricing](https://electric.ax/pricing)
- The GitHub repo now lives under `neondatabase/electric`. Neither the repo nor the docs say what that means for governance.

### Zero / Replicache
- Zero: "Zero does not support offline writes… Zero is not designed for long periods offline." [offline](https://zero.rocicorp.dev/docs/offline). Stable since 1.0, latest 1.12. [release notes](https://zero.rocicorp.dev/docs/release-notes)
- Replicache: "now in maintenance mode… won't add new features… Existing users should migrate to Zero." [replicache.dev](https://replicache.dev/)

### Triplit
- The README offers offline mode, property-level conflict resolution, server-enforced authorization, and pluggable storage (SQLite/IndexedDB). AGPL-3.0. [repo](https://github.com/aspen-cloud/triplit)
- Last commit 2025-09-11 (GitHub API). Supabase (2025-10-08): the co-founder joins Supabase, "Our focus isn't to directly integrate Triplit into our platform". [blog](https://supabase.com/blog/triplit-joins-supabase)

### InstantDB
- "the Instant team is joining OpenAI… New signups are closed… On August 31st, 2027, all cloud apps will shut down." Backups stay available until 2028-08-31. Open source, with a self-host guide. [pricing page](https://www.instantdb.com/pricing)

### Firestore
- Native offline persistence is on by default. Web is off by default and single-tab unless you use `persistentMultipleTabManager()`.
- Conflicts are last write wins. The default cache is 100 MB and evicts old documents (`CACHE_SIZE_UNLIMITED` turns that off). Offline queries scan every cached document unless indexing is enabled.
- [offline docs](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- Spark (free): 1 GiB stored, 10 GiB/mo egress, 50K reads / 20K writes / 20K deletes per day. [pricing](https://firebase.google.com/pricing)
- "Firebase projects must be on the Blaze plan to use the managed export and import service." [export](https://firebase.google.com/docs/firestore/manage-data/export-import)

### CouchDB / PouchDB
- CouchDB keeps every conflicting revision, chooses a winner deterministically "so that the same choice will be made on all peers", and leaves merging to the app (`?conflicts=true`, `_bulk_docs`). [conflicts](https://docs.couchdb.org/en/stable/replication/conflicts.html)
- PouchDB adapters: IndexedDB (browser), LevelDB (Node), and Cordova SQLite. React Native is not mentioned. [adapters](https://pouchdb.com/adapters.html)

### Supabase (+ custom sync)
- Free: 500 MB DB per project, 50K MAU, 2 active projects, "Projects pause after 1 week of inactivity". Pro from $25/mo. [pricing](https://supabase.com/pricing)
- No daily backups on Free. The docs advise free projects to "regularly export their data using the Supabase CLI `db dump`". [backups](https://supabase.com/docs/guides/platform/backups)
- PowerSync documents a first-class Supabase integration (auth, RLS, connector). [PowerSync llms.txt](https://docs.powersync.com/llms.txt)
- **RxDB** as a custom-sync layer: backend-agnostic pull/push/stream replication, with plugins for Supabase, CouchDB, Firestore, GraphQL and HTTP. The default conflict handler "will always drop the fork state and use the master state". [replication](https://rxdb.info/replication.html). Not checked: which storages, e.g. RN SQLite, are premium.

### CRDT libraries
- Automerge: "a pure data structure library that does not care about what kind of network you use". JS/WASM, Rust, C API for iOS. Access control (keyhive) is "Coming Soon". [hello](https://automerge.org/docs/hello/). Repo storage: IndexedDB, NodeFS, or a custom `StorageAdapter`. [storage](https://automerge.org/docs/reference/repositories/storage/)
- Yjs: shared types "automatically merge without merge conflicts". The docs frame it around editors (ProseMirror, Tiptap, etc.). [docs](https://docs.yjs.dev/)

### Lightly checked
- **Jazz.** Relational DB with per-table permission policies. A local-first client adds offline support (about 3.2 MB Wasm). Migrations are generated. Has a React Native client. MIT. [docs](https://jazz.tools/docs). The docs seem to describe a newer architecture than the earlier CoValue-based Jazz. Check again before relying on it.
- **Evolu.** SQLite, end-to-end encrypted by default, self-hosted or cloud relays, MIT, "no vendor lock-in". [docs](https://www.evolu.dev/docs). Sharing between users is not documented on the page read.

---

## Inputs for the decision (#9)

1. **Requirement → eliminations.**
   - Offline writes rule out Zero.
   - Long-term viability rules out Replicache, Triplit and InstantDB Cloud. InstantDB self-hosted remains possible.
   - A Flutter/KMP stack rules out Electric's official client and narrows CRDT options. PowerSync and Firestore cover Flutter.
2. **"No data loss" angle.**
   - Server-authoritative LWW (PowerSync, Firestore, RxDB default) can silently overwrite a concurrent edit to the same field. For one user on several devices that is rare but possible.
   - CouchDB keeps every revision. CRDTs merge.
   - Whatever we pick, a separate export/backup path is needed: Supabase Free has no backups, and Firestore's managed export needs Blaze. This ties into the map's "Backup/export" open item.
3. **Migration angle.**
   - PowerSync's schemaless client storage avoids on-device migrations, but compatibility across client versions has to be designed (versioned streams).
   - Schemaless doc stores (Firestore, CouchDB) push migrations into app code on both sides.
4. **Sharing angle.**
   - Postgres + RLS + sync-stream/Shape filtering (PowerSync, Electric, Supabase) models "share this ledger with user B" as rows and policies.
   - CouchDB tends towards one database per share.
   - Automerge has no access control yet.
5. **Cost angle.**
   - Free tiers that pause on inactivity (Supabase 1 week, PowerSync Cloud 1–2 weeks) are a real risk for a personal app used occasionally. Options: a keep-alive, a small paid plan ($25 Supabase Pro), or self-hosting PowerSync/Postgres on a cheap VPS.
   - Firestore Spark does not pause.
6. **Lock-in angle.**
   - Postgres-based options keep the data portable.
   - Firestore is the most locked-in.
   - CouchDB and Automerge are open formats.

## Open questions (not resolved here)
- PowerSync's free-tier inactivity period: 1 week or 2? The pricing page states both.
- Whether RxDB's React Native SQLite storage is a paid add-on.
- How Jazz's current architecture handles sharing and offline in practice, and Evolu's sharing model.
- Electric's governance after the move to the `neondatabase` org.

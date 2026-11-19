# Expo (React Native + React Native Web) as the client stack

Android, iOS and web are built from one TypeScript codebase on Expo. TypeScript was effectively fixed by [ADR 0003](./0003-server-authoritative-sync-with-powersync-and-postgres.md): the write endpoint runs the same domain rules as the clients, so Flutter (Dart) and Compose Multiplatform (Kotlin) would mean writing those rules twice. Between the two TypeScript options we chose Expo over Capacitor because mobile is where full offline use is guaranteed, and that is where Capacitor is weakest: PowerSync's Capacitor SDK is beta, its SQLite plugin's web support is a weaker sql.js-in-IndexedDB setup, and Ionic Appflow no longer takes new customers, so over-the-air updates would depend on Capgo. Expo has a fully supported PowerSync SDK, SQLite on every platform, and first-party OTA through EAS Update. Research: [cross-platform client stack options](https://github.com/nicolasbiscotti/economic-analysis/blob/research/client-stack-options/docs/research/client-stack-options.md).

## Rules

- **Domain package**: the domain rules live in one pure TypeScript package with no platform imports (no React, React Native, Node or Deno built-ins), enforced in CI. It must run on Hermes, Node and Deno. The app and the Supabase Edge Function both import it. Storage, sync and UI depend on it, never the other way round.
- **Specs**: the required v1 adapter for the driver port from [ADR 0002](./0002-english-gherkin-specs-with-generated-spanish-twin.md) runs in-process: the domain package plus a local SQLite replica, with no UI. UI adapters (Playwright for web, Maestro or Appium for mobile) are added later behind the same port.
- **Web**: an Expo Router static export, hosted on Cloudflare Pages behind our own domain. The host sends the COOP/COEP headers that wasm SQLite needs.
- **Native**: Continuous Native Generation. `ios/` and `android/` are build output generated from `app.config.ts` and config plugins, never committed. Binaries are built with EAS Build.
- **Updates**: EAS Update is the update channel. How it is used (channels, when an update has to go through the store, compatibility with old builds) is decided separately.

## Considered Options

- **Capacitor**: real DOM and CSS everywhere, and the most direct path to desktop, but a beta sync SDK, weaker web storage, a webview mobile UI and third-party OTA.
- **Flutter / Compose Multiplatform**: the widest first-party platform reach, but not TypeScript, and Compose web is Beta.
- **Separate web app (Next.js/Vite)**: a full web UI toolkit, at the cost of a second UI codebase.
- **Bare workflow (committed native folders)**: full native control, but every Expo SDK upgrade means hand-merging native project changes. It can still be adopted later if a native need forces it.

## Consequences

- The web UI is limited to React Native primitives through React Native Web, which is community-maintained.
- **Desktop** is not in v1. The expected path is a Tauri shell around the static web build (Windows, macOS, Linux). The fallback, react-native-windows/macos, has no Linux, so it would only apply if Linux were dropped. Tauri's PowerSync SDK is alpha today, so the choice is left to whoever starts desktop.

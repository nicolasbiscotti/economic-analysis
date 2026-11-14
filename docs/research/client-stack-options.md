# Research: cross-platform client stack options

Ticket: [#3](https://github.com/nicolasbiscotti/economic-analysis/issues/3). Map: [#1](https://github.com/nicolasbiscotti/economic-analysis/issues/1).
Researched 2026-11-14 against primary sources (official docs, first-party repos, store policies). This file gathers inputs for the stack decision; it does not make it.

**Question:** Which client stacks can ship one codebase to web + Android + iOS (without ruling out desktop), fully offline, with TypeScript preferred if competitive?

## Summary comparison

| | Expo / React Native (+ RN Web) | Capacitor (+ Ionic or any web UI) | PWA only | Flutter | Kotlin / Compose Multiplatform | Tauri 2 |
|---|---|---|---|---|---|---|
| Language | TypeScript | TypeScript | TypeScript | Dart | Kotlin | TS front end + Rust core |
| Web | Yes (react-native-web) | Yes (it is a web app) | Yes | Yes (JS or Wasm) | Compose web on Wasm is **Beta** | Front end deploys as a plain web app; Tauri itself does not target web |
| Android / iOS | Yes | Yes | Install from the browser only; no store | Yes | Stable | Yes since 2.0 (Oct 2024); team admits rough developer experience |
| Desktop | Out of tree: react-native-windows / -macos (Microsoft) | Electron (community) | Installable PWA | Windows / macOS / Linux, first party | JVM desktop, Stable | Main target |
| OTA (JS/Dart, no store review) | EAS Update (first party) | Capgo (OSS plugin + SaaS); Ionic Appflow closed to new customers | Always (it is the web) | Shorebird (third party, Dart only) | None (compiled native) | None documented |
| Local DB | expo-sqlite (Android, iOS, macOS, tvOS, web via wasm) | @capacitor-community/sqlite (web uses sql.js in IndexedDB) | IndexedDB / OPFS + wasm SQLite | drift (web stable: OPFS, falls back to IndexedDB) | SQLDelight (Android, native, JVM, JS) | Tauri SQL plugin (desktop + mobile) |
| i18n / locale formatting | Hermes `Intl` on all platforms + expo-localization | Browser / WebView `Intl` | Browser `Intl` | `intl` package (Dart) | No built-in `Intl` (kotlinx libs / expect-actual) | WebView `Intl` |
| UI-test drivers | Maestro (Expo-documented), Detox; Playwright on web | Playwright/WebDriver on web; Appium/Maestro on device | Playwright | integration_test (all platforms, web via ChromeDriver); Maestro | Compose common UI test (**Experimental**, runs on all 4 targets) | WebDriver on desktop only (no mobile) |

## Cross-cutting facts

- **Store fees (any store-shipped stack):** Apple Developer Program costs $99 a year ([Apple](https://developer.apple.com/programs/)). Google Play charges a "US$25 one-time registration fee" ([Google](https://support.google.com/googleplay/android-developer/answer/6112435)).
- **OTA policy:** Apple guideline 2.5.2 forbids downloaded code that "introduces or changes features or functionality of the app" ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)). OTA vendors rely on Apple's licence allowing interpreted code that "does not change the primary purpose of the Application." They also rely on Google Play's exemption for "code that runs in a virtual machine or an interpreter" ([Shorebird FAQ](https://docs.shorebird.dev/code-push/faq/)). Expo tells developers to "follow the rules of the platforms and app stores" ([EAS Update FAQ](https://docs.expo.dev/eas-update/faq/)). In practice, OTA covers bug fixes and small UI changes. Feature changes still go through store review.
- **Data-loss risk for web-only storage on iOS:** WebKit's Intelligent Tracking Prevention (ITP) deletes "all of a website's script-writable storage after seven days of Safari use without user interaction on the site". This covers IndexedDB, LocalStorage and the Service Worker cache. Home Screen web apps keep their own counter, and WebKit says "we do not expect" their data to be deleted ([WebKit, 2020](https://webkit.org/blog/10218/full-third-party-cookie-blocking-and-more/)). All origins are "best-effort" by default. `navigator.storage.persist()` is granted by heuristics such as being opened as a Home Screen web app ([WebKit storage policy](https://webkit.org/blog/14403/updates-to-storage-policy/)). Since **no data loss** is a hard requirement, a browser-only client on iOS can't be the only copy of the data. Sync or export must back it up.
- **wasm SQLite on web** (expo-sqlite, drift) needs COOP/COEP headers for `SharedArrayBuffer`/OPFS ([expo-sqlite](https://docs.expo.dev/versions/latest/sdk/sqlite/), [drift web](https://drift.simonbinder.eu/platforms/web/)). Most static hosts can set custom headers, but the hosting choice has to support this.

## Per-stack notes

### Expo / React Native (+ React Native Web)

- **Coverage:** Expo builds web from the same code through react-native-web, and `npx expo export --platform web` produces a static site ([Expo web](https://docs.expo.dev/workflow/web/)). Desktop is not part of Expo. React Native lists macOS and Windows as "out-of-tree" platforms maintained by partners (Microsoft), and React Native Web as a community project (necolas) ([RN out-of-tree platforms](https://reactnative.dev/docs/out-of-tree-platforms)). Current Expo SDK is 58.
- **OTA:** EAS Update ships "non-native pieces (such as JS, styling, and images) over-the-air". Native code, permissions and SDK upgrades need a new binary. Runtime versions keep updates matched to compatible builds ([EAS Update](https://docs.expo.dev/eas-update/introduction/)).
- **Local DB:** expo-sqlite runs on Android, iOS, macOS, tvOS and Web. On web it uses a prebuilt wasm SQLite without full-text search. It needs Metro wasm config plus COOP/COEP headers, and a few APIs are unavailable ([expo-sqlite](https://docs.expo.dev/versions/latest/sdk/sqlite/)).
- **i18n:** "The Intl API works on all platforms when you use Hermes." expo-localization reports the device's locales, currency and calendar. Per-app language is supported on iOS and Android. Expo recommends the standard `Intl` APIs for numbers and dates ([Expo localization](https://docs.expo.dev/guides/localization/)). This covers multi-currency formatting (`Intl.NumberFormat` with `currency`).
- **UI tests:** Expo documents Maestro E2E tests on EAS Workflows. These run against a built .apk or .app ([Expo E2E](https://docs.expo.dev/build-reference/e2e-tests/)). Maestro offers "full support" on Android emulators and devices and on iOS simulators, with web "functional with ongoing development" ([Maestro platforms](https://docs.maestro.dev/get-started/supported-platform)). Detox is an alternative for React Native. Playwright can drive the web build.
- **Ecosystem health (GitHub, 2026-11-14):** expo/expo 53.5k stars, react/react-native 127k (v0.88.1, Oct 2026), react-native-web 22k. All MIT licensed and active this week.
- **Solo-dev cost:** EAS Free plan includes "up to 15 Android and 15 iOS builds" and 1,000 update MAUs at $0. Starter costs $19/month ([Expo pricing](https://expo.dev/pricing)). Local or CI builds avoid EAS build limits.

### Capacitor (Ionic or any web UI) / PWA

- **Coverage:** Capacitor (v8 current, 8.6.2 released 2026-11-12) runs a web app natively on iOS and Android, and on web ([Capacitor docs](https://capacitorjs.com/docs)). Desktop is only through community Electron support; for example, @capacitor-community/sqlite lists Electron ([repo](https://github.com/capacitor-community/sqlite)). The UI is plain web, so any TS framework works and the web build is the app itself.
- **OTA:** Ionic stopped selling Appflow to new customers on 2025-02-11. Existing users keep access until 2027-12-31. Capacitor itself stays OSS ([Ionic announcement](https://ionic.io/blog/important-announcement-the-future-of-ionics-commercial-products)). The main live-update option left is Capgo: a hosted service ([Capgo docs](https://capgo.app/docs/)) backed by the MPL-2.0 open-source `Cap-go/capacitor-updater` plugin (888 stars, active).
- **Local DB:** @capacitor-community/sqlite supports Android, iOS, Electron and Web. On web, "SQLite databases are backed by `jeep-sqlite` and stored in IndexedDB" (sql.js), with fewer methods (no encryption). The repo is smaller (663 stars) and last pushed 2026-08 ([repo](https://github.com/capacitor-community/sqlite)). Alternatively, use wasm SQLite with OPFS directly on web.
- **i18n:** Platform `Intl` in the WebView or browser.
- **UI tests:** Playwright on the web build covers the shared UI. Appium or Maestro ("other hybrid frameworks") cover the device shell.
- **PWA-only variant:** zero store cost and always up to date, but the iOS storage rules above make the browser copy best-effort. No app-store presence.
- **Health:** ionic-team/capacitor 17k stars, MIT, active.

### Flutter

- **Coverage:** Flutter 3.50 supports Android 24–37, iOS 15–27, Windows, macOS, Linux and web (JS, plus opt-in Wasm). All are first-party ([supported platforms](https://docs.flutter.dev/reference/supported-platforms)). It has the widest first-party coverage of the options.
- **Language:** Dart. This fails the TypeScript preference.
- **OTA:** Shorebird (third party) patches Dart code only. Native code, assets and Flutter upgrades need a store release. Web doesn't need it ([Shorebird FAQ](https://docs.shorebird.dev/code-push/faq/)).
- **Local DB:** drift's web support "is now stable". It uses wasm SQLite with OPFS and falls back to IndexedDB, and has caveats for Firefox private windows and Android Chrome without headers ([drift web](https://drift.simonbinder.eu/platforms/web/)).
- **UI tests:** `integration_test` runs on desktop, Android and iOS, and on web via `flutter drive` + ChromeDriver ([integration tests](https://docs.flutter.dev/testing/integration-tests)). Tests are written in Dart, so the spec adapter would be Dart or would go through Maestro (supports Flutter).
- **Health:** flutter/flutter 181k stars, BSD-3, very active.

### Kotlin Multiplatform / Compose Multiplatform

- **Coverage:** KMP core is Stable on Android, iOS, JVM desktop and Kotlin/JS, and Beta on Wasm. The Compose Multiplatform UI is Stable on Android, iOS and desktop, but **web (Wasm) is Beta** ([supported platforms](https://kotlinlang.org/docs/multiplatform/supported-platforms.html)). This puts v1's web target on a Beta UI layer.
- **Language:** Kotlin. Fails the TS preference.
- **OTA:** none. The app is compiled native or JVM code, so every change goes through the stores (an inference from the compile model; no first-party OTA exists).
- **Local DB:** SQLDelight targets Android, Native (iOS/macOS/Linux/Windows), JVM, and the browser through a sql.js worker. Wasm isn't mentioned ([SQLDelight](https://sqldelight.github.io/sqldelight/latest/)).
- **UI tests:** the Compose common UI test API runs on iOS simulator, Android, JVM and Wasm, but is **Experimental** ([Compose tests](https://kotlinlang.org/docs/multiplatform/compose-test.html)).
- **Health:** JetBrains/compose-multiplatform 19.5k stars (v1.12.2, Oct 2026), Apache-2.0.

### Tauri 2 (desktop reach)

- **Coverage:** Tauri targets "all major desktop and mobile platforms", with a web front end built by any framework that "compiles to HTML, JavaScript, and CSS" ([Tauri](https://v2.tauri.app/start/)). Mobile arrived in 2.0 (2024-10-02). The team says "We are not completely happy about the developer experience" and "On mobile not all of the official plugins are supported" ([Tauri 2.0](https://v2.tauri.app/blog/tauri-20/)). Tauri 3.0 is in alpha (v3.0.0-alpha.6, 2026-11-06), so a major-version migration lies ahead.
- **OTA:** Tauri has a desktop updater for binaries, but no documented mobile OTA for the web bundle.
- **Local DB:** the SQL plugin supports Windows, Linux, macOS, Android and iOS (SQLite/MySQL/Postgres) ([SQL plugin](https://v2.tauri.app/plugin/sql/)). On web, the front end would need its own storage.
- **UI tests:** WebDriver is desktop only. The WebdriverIO service covers Windows, Linux and macOS; raw `tauri-driver` covers Windows and Linux. Mobile isn't covered ([Tauri WebDriver](https://v2.tauri.app/develop/tests/webdriver/)).
- **Fit:** it works best as a later **desktop shell** around a TS web build, for example the Expo web export or a Capacitor web app, rather than as the v1 mobile stack.
- **Health:** tauri-apps/tauri 113k stars, Apache-2.0/MIT, active.

## Inputs for the decision (not the decision)

1. **TypeScript + first-party OTA + one UI codebase across web/iOS/Android:** only Expo/RN and Capacitor meet all three. Expo has a first-party OTA service with a free tier. Capacitor's first-party OTA (Appflow) is closed to new customers, which leaves Capgo.
2. **Web fidelity:** Capacitor's web build *is* the app. Expo's web goes through react-native-web, a community-maintained project, which works but can drift from native behaviour. Compose web is Beta.
3. **Offline storage parity:** every TS option needs SQLite on native and wasm SQLite (OPFS + COOP/COEP) or IndexedDB on web. Pick the hosting and the sync engine with that in mind. On iOS web, data is best-effort only.
4. **Executable-spec seam:** Maestro (YAML, external process) can drive Android/iOS builds from RN, Flutter or Capacitor. Playwright drives any web build. A stack-agnostic driver probably wraps Playwright (web) + Maestro or Appium (mobile). Flutter and Compose in-process tests would tie adapters to Dart or Kotlin.
5. **Desktop later:** Flutter and Compose are first-party. TS stacks get there via Tauri (or Electron) around the web build, or via react-native-windows/macos.
6. **Fixed cost floor:** $99/yr Apple + $25 once for Google for any store-shipped stack. Hosting a static web build plus OTA can stay at $0 within free tiers (EAS: 1,000 update MAUs).

## Open / not verified

- Shorebird pricing and its desktop patching status weren't confirmed from the fetched pages.
- Capgo's ongoing free tier and self-hosting were not confirmed (the docs page shows only a 14-day trial).
- No hands-on check of expo-sqlite web performance or of the react-native-web behaviour gaps.

# UI text and formatting go through our own i18n module, backed by FormatJS on forced polyfills

The UI ships in Spanish and English in v1, with more languages later, and shows money in several currencies side by side. All UI text, formatting and amount parsing go through one pure-TS `i18n` package that we own. It is the only code that imports FormatJS and the `Intl` polyfills, so swapping the library rewrites that package and at most converts the catalogue files' layout; screens and messages stay as they are. Hermes only implements `NumberFormat`, `DateTimeFormat` and `Collator`, and formats with each OS's own locale data. So we force FormatJS polyfills on every platform, and the app renders identically everywhere from one CLDR dataset.

## Locale

- The setting is one BCP 47 tag with a region (`es-AR`, `en-US`). The **language** picks the message catalogue. The **region** drives number, date and money formatting and the pinned currency ([Grilling: multi-currency rules in v1](https://github.com/nicolasbiscotti/economic-analysis/issues/7)).
- The base `es` catalogue uses the glossary's es-AR words. A regional override catalogue (such as `es-MX`) is added only when a region names something differently; there are none in v1. In v1, `es-MX` shows es-AR wording with Mexican formatting and MXN pinned.
- **Default**: on first launch, the app takes the first language it supports from the device's locale list, with that entry's region, or the device region if the entry has none. If no device language is supported, it falls back to **English**, keeping the device's region. A message missing at runtime also falls back to English. A phone set to Spanish always gets Spanish, so the app stays Spanish-first for Spanish speakers, and anyone else gets the language they are more likely to read.
- **Per-device in v1**: stored locally, not synced. It only affects display, and it shouldn't wait on the identity decision. Syncing it per person later is an additive change, a synced preference that devices use instead of their local default, and needs no data migration.

## Messages

- Explicit semantic ids (`payment.markPaid.button`), not source-text keys.
- Written in ICU MessageFormat (plurals such as "3 cuotas", selects). It is a standard that Lingui and i18next-icu read too, which keeps the catalogues portable.
- CI fails if a shipped language is missing a key, has an extra one, or has a mismatched placeholder. There is no machine translation, as in [ADR 0002](./0002-english-gherkin-specs-with-generated-spanish-twin.md). Using the glossary's words in UI text is checked in review, not by tooling.
- The server never returns user-facing text. The Edge Function and the sync layer return stable error codes with parameters, and the client turns them into messages. That includes rejected and parked writes and "update required" ([ADR 0005](./0005-update-delivery-and-no-data-loss-policy.md)).

## Formatting and parsing

- Money uses the locale's `currencyDisplay: 'symbol'` and each currency's own number of decimals, so currencies shown together stay distinct: in es-AR, `$ 1.500,00` (ARS) and `US$ 1.500,00`; in en-US, `ARS 1,500.00` and `$1,500.00`. Never hand-format.
- Typed amounts accept only the region's decimal separator (es-AR `1500,50`). Grouping separators are optional and ignored, and an ambiguous separator is rejected, never guessed. Amounts can't have more decimals than the currency allows. Parsing lives in the `i18n` package; the domain package stays free of i18n and deals in amounts as values.
- Months are formatted as month and year ("marzo de 2026"), Closing and Due Dates in the region's short date format. Both are calendar values with no time zone, so formatting never shifts a date.
- Currency names come from the `DisplayNames` polyfill, and picker sorting uses the native `Collator`.
- Polyfills, forced on every platform with es and en data only: `Locale`, `PluralRules`, `DisplayNames`, `NumberFormat`, `DateTimeFormat`.

## Specs

Executable specs never assert on visible copy. The driver port speaks domain values, and the v1 in-process adapter has no UI ([ADR 0004](./0004-expo-react-native-client-stack.md)). Later UI adapters find elements by stable test ids, never by text. So a spec runs the same in every UI language, and the Spanish spec twin translates the specs' prose, not app strings. The CI catalogue checks and unit tests of the `i18n` package in each shipped locale cover copy and formatting. Because of the forced polyfills, these tests run once in Node and match every device.

## Considered options

- **Lingui**: ICU and compiled catalogues with a small runtime, but it needs the same polyfills and has less documentation for Hermes. **i18next**: the most popular, but ICU is a plugin and it still needs `PluralRules`.
- **The OS's native formatting**: no bundle cost, but output differs between Android, iOS, the web and OS versions. Formatting tests would have to be snapshotted per platform, and on iOS `narrowSymbol` and number `formatToParts` don't work.
- **Spanish fallback**: it matches "Spanish first", but someone whose device language isn't supported is more likely to read English.

## Consequences

- The `Intl` polyfills and their locale data add to the bundle; adding a language means adding its polyfill locale data as well as its catalogue.
- Research: [Hermes Intl support](https://github.com/nicolasbiscotti/economic-analysis/issues/12) (findings in the resolution comment).

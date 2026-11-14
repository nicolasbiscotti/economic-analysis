# Research: executable-spec tooling and stack-agnostic drivers

Ticket: [#2](https://github.com/nicolasbiscotti/economic-analysis/issues/2) · Map: [#1](https://github.com/nicolasbiscotti/economic-analysis/issues/1) · Researched 2026-11-14

This note collects facts to feed the decision. It doesn't make the decision. Repo stats come from the GitHub API on the research date.

## 1. Candidate spec formats and runners

| Tool | Spec format | TS support | Maintenance (GitHub API, 2026-11-14) | Notes |
|---|---|---|---|---|
| **Cucumber.js** (`@cucumber/cucumber`) | Gherkin `.feature` | Step code in TS via `tsx` loader; config file can be `.ts` ([transpiling.md](https://github.com/cucumber/cucumber-js/blob/main/docs/transpiling.md), [configuration.md](https://github.com/cucumber/cucumber-js/blob/main/docs/configuration.md)) | v13.3.0 released 2026-10-05; last push 2026-11-13; ~5.4k stars ([repo](https://github.com/cucumber/cucumber-js)) | Official Cucumber implementation. Built-in `parallel`, `retry`, `tags`, sharding, dry-run, and `message`/HTML formatters ([docs/](https://github.com/cucumber/cucumber-js/tree/main/docs)). Not tied to any UI driver. |
| **playwright-bdd** | Gherkin `.feature` | Native TS | v9.2.1 released 2026-09-06; last push 2026-11-13; ~830 stars ([repo](https://github.com/vitalets/playwright-bdd)) | Runs Gherkin on the Playwright Test runner. Supports `language: 'es'` and `# language:` ([i18n.md](https://github.com/vitalets/playwright-bdd/blob/main/docs/writing-features/i18n.md)). Strong for web, but it couples the spec runner to Playwright, so it doesn't fit native mobile. |
| **QuickPickle** | Gherkin `.feature` | Native TS/ESM through Vitest | Last push 2026-07-12; ~50 stars ([repo](https://github.com/dnotes/quickpickle)) | Runs feature files as Vitest tests with the official Gherkin parser. Covers most of the Cucumber.js API, but attachments aren't supported ([README](https://github.com/dnotes/quickpickle#readme)). A good fit for a fast domain-level loop, but it's a small single-maintainer project. |
| **Gauge** (+ `gauge-js`) | Markdown (`.spec`/`.md`): H1 = spec, H2 = scenario, bullet = step ([docs](https://docs.gauge.org/writing-specifications.html)) | gauge-js v5.0.8 released 2026-09-01 | gauge v1.6.43 released 2026-11-09 ([repo](https://github.com/getgauge/gauge)); gauge-js has ~80 stars ([repo](https://github.com/getgauge/gauge-js)) | Free-form step text with no keywords, so there are no localized keywords to rely on. The docs say nothing about i18n. Needs a separate Go binary plus a language runner, and the JS ecosystem is small. |
| **Concordion** | HTML/Markdown instrumented specs | Java only (a .NET port exists) | Latest release 4.0.1 on 2023-07-16; last push 2025-05 ([repo](https://github.com/concordion/concordion)) | Doesn't fit a TypeScript stack, and the project is close to dormant. |
| **Plain TS test DSL** (Vitest/Jest + named scenario functions) | TS code | Native | n/a | Easy to refactor, but the specs are code, not prose. Producing a bilingual twin would require a hand-built doc generator. |

The Gherkin parser itself is under heavy maintenance: `cucumber/gherkin` v43.0.0 was released 2026-11-13 ([repo](https://github.com/cucumber/gherkin)). It publishes a cross-language AST and "pickles" through `cucumber/messages` (v35.0.0, [repo](https://github.com/cucumber/messages)), so any custom tooling, such as translation or alignment checks, can use the official parser.

## 2. Stack-agnostic driver seam

Gherkin and its runners don't impose a driver. Step definitions are plain code, so the seam is whatever the step definitions call. Two established shapes exist:

- **Screenplay pattern** ([Serenity/JS handbook](https://serenity-js.org/handbook/design/screenplay-pattern/)):
  - *Actors* have *Abilities*, which wrap an integration library such as `BrowseTheWeb` or `CallAnApi`.
  - Actors perform *Interactions* and *Tasks*, which are business-meaningful groups of interactions, and they ask *Questions*.
  - "Tasks hide interface details behind domain language." A spec's steps call Tasks, and the Ability wired into the actor decides which interface runs.
  - Serenity/JS v3.49.0 was released 2026-10-10 ([repo](https://github.com/serenity-js/serenity-js)). It integrates with Cucumber.js, Playwright Test, Mocha, Jasmine and WebdriverIO.
  - Its packages are `core`, `cucumber`, `web`, `rest`, `playwright`, `webdriverio`, and others ([packages/](https://github.com/serenity-js/serenity-js/tree/main/packages)). There is **no dedicated mobile package**. Mobile goes through `@serenity-js/webdriverio`, where WebdriverIO drives Appium (`uiautomator2` for Android, `xcuitest` for iOS) ([WDIO Appium service](https://webdriver.io/docs/appium-service)). The WebdriverIO handbook page shows only web setups ([handbook](https://serenity-js.org/handbook/test-runners/webdriverio/)).
- **Ports/drivers, hand-rolled**: define a small TS interface in domain language, for example `ExpenseTrackerDriver { addFixedExpense(...); markPaid(month, expense, amount); balanceFor(month) }`. Write one implementation per target:
  - an in-process domain driver that calls the core directly and runs fast;
  - a web driver on Playwright;
  - a mobile driver on Appium/WebdriverIO, Maestro or Detox.
  
  The step definitions choose the driver from an environment variable or a Cucumber profile ([profiles.md](https://github.com/cucumber/cucumber-js/blob/main/docs/profiles.md)). This is Screenplay without the library. It has less vocabulary to learn, but it has none of Serenity's reporting.

Mobile UI driver options, in TS terms:

| Driver | Platforms | Driven from TS? | Status (2026-11-14) |
|---|---|---|---|
| Appium via WebdriverIO | Android, iOS (and web via WDIO) | Yes, a native JS/TS API | WebdriverIO v10.2.0 released 2026-11-06 ([repo](https://github.com/webdriverio/webdriverio)); Appium last pushed 2026-11-14 ([repo](https://github.com/appium/appium)) |
| Maestro | Android, iOS, web | **No.** Flows are YAML that the CLI runs ([README](https://github.com/mobile-dev-inc/maestro#readme)). A TS driver would have to generate YAML flows or shell out to the CLI | cli-2.12.1 released 2026-11-02. "Expo supports Maestro as its preferred E2E testing platform" ([README](https://github.com/mobile-dev-inc/maestro#readme)) |
| Detox | Android, iOS, **React Native only** ([README](https://github.com/wix/Detox#readme)) | Yes (JS) | Latest release 20.51.3 on 2026-05-30 |

Which mobile driver fits depends on the stack decision. Detox works only with React Native. Maestro and Appium work with any stack.

## 3. Bilingual specs (English and Spanish)

What Gherkin provides natively:
- **Localized keywords.** 80 dialects are defined in [`gherkin-languages.json`](https://github.com/cucumber/gherkin/blob/main/gherkin-languages.json) ([list](https://cucumber.io/docs/gherkin/languages/)). The Spanish (`es`) keywords:
  - Feature: `Característica` / `Necesidad del negocio` / `Requisito`
  - Rule: `Regla`
  - Background: `Antecedentes`
  - Scenario: `Escenario` / `Ejemplo`
  - Scenario Outline: `Esquema del escenario`
  - Examples: `Ejemplos`
  - Given: `Dado/Dada/Dados/Dadas`
  - When: `Cuando`
  - Then: `Entonces`
  - And: `Y/E`
  - But: `Pero`
- **Language selection.** Each file can declare `# language: es`, or the runner sets a default (`language` option in Cucumber.js [configuration.md](https://github.com/cucumber/cucumber-js/blob/main/docs/configuration.md); `language: 'es'` in [playwright-bdd](https://github.com/vitalets/playwright-bdd/blob/main/docs/writing-features/i18n.md)).

What it does **not** provide:
- **Translated step text.** Steps bind to code by matching text ([Cucumber Expressions](https://github.com/cucumber/cucumber-expressions)), so a Spanish file needs Spanish step expressions. Each step function can be registered twice, with one expression in each language.
- **A translation tool.** No maintained tool was found that translates or cross-checks feature files between natural languages. A web search turned up only keyword-dialect and IDE plugins, so this would be custom work.
- **Stable scenario IDs.** The IDs in `cucumber/messages` are assigned per parse ([messages](https://github.com/cucumber/messages)). Alignment needs a convention, such as a tag like `@id:fixed-expense-001` on every scenario.

**A feasible automation, assembled from official pieces.** No single tool does this end to end. Pick one canonical language (say English) and treat the other as a derived file:
1. **Generate.** Parse the canonical `.feature` with `@cucumber/gherkin` and swap the keywords using `gherkin-languages.json`. Then translate each step's text through a **catalogue keyed by step-definition expression**: each English Cucumber Expression maps to one Spanish expression with the same parameters, so the parameter values (amounts, dates, currencies) carry over unchanged. Free text (feature and scenario titles, descriptions) goes in a catalogue keyed by `@id`. It can be machine-translated, then reviewed.
2. **Check in CI.** Run Cucumber.js `--dry-run` ([dry_run.md](https://github.com/cucumber/cucumber-js/blob/main/docs/dry_run.md)) with the `message` formatter ([formatters.md](https://github.com/cucumber/cucumber-js/blob/main/docs/formatters.md)) on both language trees. For every `@id`, compare the sequence of matched step-definition IDs and arguments, and fail on any undefined or ambiguous step, or any mismatch. This catches drift without hand-maintained twins.
3. Executing one tree, usually the canonical one, is enough. The other tree is proven equivalent at the binding level.

Gauge has no keywords to localize, and its docs don't mention i18n. A Gauge setup would need the same catalogue approach, but without an official AST or dry-run message stream to build the check on.

## 4. Maturity, CI ergonomics, readability

- **Cucumber.js:**
  - Officially maintained, with a steady release cadence.
  - CI-friendly: parallel workers, sharding, retry, tag filters, HTML and NDJSON message output, and publishing to reports.cucumber.io ([docs/](https://github.com/cucumber/cucumber-js/tree/main/docs)).
  - Gherkin is the most widely recognised spec format for newcomers.
  - Caveat: the TS setup goes through a loader such as `tsx`, and the ESM vs CommonJS choice matters ([transpiling.md](https://github.com/cucumber/cucumber-js/blob/main/docs/transpiling.md)).
- **playwright-bdd:** excellent web DX (Playwright UI mode, traces), but tied to the Playwright runner.
- **QuickPickle:** zero-config TS through Vite and fast. Its bus factor is low.
- **Serenity/JS:** rich reporting and a well-documented Screenplay vocabulary. It adds a learning curve and abstraction weight, and it has no first-class mobile package.

## Inputs for the decision

- **Gherkin** is the only candidate with official localized keywords, an official parser and AST, and a dry-run message stream. Those three make the "one canonical language, the other generated and checked" requirement buildable. The step-text translation and alignment check are still **custom code** (roughly a small script plus a catalogue).
- **Cucumber.js** is the runner-neutral choice. It can drive a domain driver, Playwright and WebdriverIO/Appium from the same features through a driver interface chosen per profile. playwright-bdd and QuickPickle are faster per layer but each binds to one runner.
- **Seam options:** Serenity/JS Screenplay (more structure and reporting, plus a dependency) or a hand-rolled TS driver interface (lighter). Both keep the specs unchanged when the stack changes.
- **The mobile driver depends on the stack:** Appium/WebdriverIO works with any stack and is TS-native, Maestro works with any stack but is YAML, and Detox is React Native only.
- **Gauge and Concordion** look weak for this project. Gauge has no i18n story and a small JS ecosystem. Concordion is Java-only and nearly dormant.
- **Required conventions** if Gherkin is chosen: a mandatory `@id` tag per scenario, and step expressions written as domain phrases ("marco pagado el gasto … por …") rather than UI actions.

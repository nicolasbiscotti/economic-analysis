# Executable specs are English Gherkin with a generated Spanish twin

Behaviour is specified in Gherkin and run with Cucumber.js, and every spec must exist in English and Spanish without two hand-maintained copies drifting apart. English is the canonical source, even though the app is Spanish-first: it matches the glossary, which names every term in English first, and it suits a future team and the tooling. The Spanish tree (`specs/es/`) is generated from the English one (`specs/en/`) and committed so it can be read on GitHub. Nobody edits it by hand; CI regenerates it and fails on any difference. Gherkin keywords come from the official `gherkin-languages.json`. Step text and titles come from a checked-in catalogue whose domain words use the glossary's Spanish names. There is no machine translation, and a missing catalogue entry fails CI.

## Considered Options

- **Spanish canonical**: matches the UI language, but it would split spec vocabulary from the glossary's canonical English terms. "Spanish first" is a rule for the UI, not for how specs are written.
- **Hand-written twins with a binding check**: a dry-run check catches steps that no longer match, but not wording that drifts, and it doubles the writing effort.
- **Generated on demand, not committed**: Spanish readers and reviewers couldn't see the twin without running a script.
- **Other formats (Gauge, Concordion) or UI-tied runners (playwright-bdd)**: no documented i18n, Java-only, or limited to the web.

## Consequences

- Every Feature and Scenario needs a stable, never-reused `@id` tag (for example `@id:fixed-expenses.mark-paid.partial-amount`). Catalogue titles are keyed by it, and it pairs the two trees, because Gherkin message ids aren't stable between parses.
- Adding or rewording an English step means adding its catalogue entry in the same change.

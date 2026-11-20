# Research: community Gherkin/BDD agent skills for writing our specs

Researched 2026-11-20. This note compares community Claude Code / agent skills (`SKILL.md`) for writing Gherkin and ends with a recommendation. Repo stats come from the GitHub API (`gh api repos/<owner>/<repo>`) on the research date. Skill content was read from each repo's own files, not from directory summaries. Nothing from these repos was run.

## TL;DR

**Write our own project skill.** None of the candidates knows about the three things that make our specs ours:

- the `@id:` tag on every Feature and Scenario;
- the step catalogue that ADR 0002 requires in the same change;
- a `GLOSSARY.md` with `_Avoid_` lists.

Several candidates also teach templates that clash with our files. Examples are the As-a/I-want/So-that header, "should" phrasing, generic `@smoke` tags and "at most one When". A few even break their own declarative rule in their examples. Borrow the workflow ideas from **tsipotu/gherkin-skill** (scan existing files, match their style, detect conflicts, ask before proposing, glossary check). Borrow the read-only reviewer pattern from **testland/qa `gherkin-style-reviewer`**, which is MIT. Take the syntax facts straight from cucumber.io. Details are in the [Recommendation](#recommendation).

## What our specs need from a skill

Taken from the repo, not from any skill:

| Property of our specs | Evidence |
|---|---|
| Declarative, first person, domain verbs | `When I create a Fixed Expense "Rent" in ARS from March 2026 expecting 500000` (`specs/en/fixed-expenses/create.feature`) |
| Glossary terms, capitalised, never the `_Avoid_` synonyms | `GLOSSARY.md`: Payment `_Avoid_: Occurrence, instance, installment, bill, charge` |
| Concrete, rule-relevant data | Months, ARS amounts and expense names in every step |
| Present-tense outcomes with no "should" | `Then it is refused because the name is blank`, `And nothing has changed` |
| Feature description states the rules in prose, with no As-a/I-want/So-that | `Feature: Create a Fixed Expense` / `A Fixed Expense is owed every Month from its Start Month, ...` |
| Stable `@id:` tags on Feature and every Scenario | `@id:fixed-expenses.create.open-ended`; required by ADR 0002 ("Every Feature and Scenario needs a stable, never-reused `@id` tag") |
| Section comments instead of `Rule:` | `# Start Month`, `# Reopening` (`range.feature` lines 10, 91) |
| Warn-then-confirm flows with two When/Then pairs | `payments.feature` lines 74–79: `When I mark ... as Pending` / `Then I am warned ...` / `When I confirm` / `Then ...` |
| Short Background, Scenario Outline only for real data variation | `payments.feature` Background is one line; the Outline covers `0` / `-1` amounts |
| English only, no `# language:` header; the Spanish twin is generated, committed and never hand-edited; every new step needs a catalogue entry | `docs/adr/0002-english-gherkin-specs-with-generated-spanish-twin.md` |
| No step definitions yet | No step code in the repo |

So the skill we need writes **scenarios only**, in the house style, and keeps the glossary, the `@id` tags and the catalogue in step. Generating step code is out of scope for now.

## Baseline: what Cucumber itself says

Every best-practice claim below is checked against these:

- "Your scenarios should describe the intended behaviour of the system, not the implementation." Declarative style "describes the behaviour of the application, rather than the implementation details". The page also says "Imperative tests communicate details, and in some contexts this style of test is appropriate." It gives no rule on step count, on one When, or on first person ([Better Gherkin](https://cucumber.io/docs/bdd/better-gherkin/)).
- "we recommend 3-5 steps per example"; "Keep your `Background` section **short**"; "Don't use `Background` to set up **complicated states**"; "The purpose of the `Rule` keyword is to represent one _business rule_"; "An outcome _should_ be on an **observable** output"; "A `# language:` header on the first line of a feature file tells Cucumber what spoken language to use", with English as the default; "You can only have a single `Feature` in a `.feature` file" ([Gherkin reference](https://cucumber.io/docs/gherkin/reference/)). The reference says nothing about multiple When steps.
- **Is there an official skill?** I found no `SKILL.md` or `AGENTS.md` in the `cucumber` GitHub org: `gh api "search/code?q=filename:SKILL.md+org:cucumber"` returned 0 results. The only `SKILL.md` in the SmartBear org is for `swaggerhub-cli` ([SmartBear/swaggerhub-cli](https://github.com/SmartBear/swaggerhub-cli/tree/main/skills/swaggerhub-cli)). A web search turned up only community skills. Conclusion: **no Cucumber/SmartBear Gherkin skill exists as of 2026-11-20** (code search only covers default branches, so this isn't fully exhaustive).

## Overview

| Candidate | Stars / last push / license | Scope | Glossary | `# language:` | Ships scripts/hooks | Verdict |
|---|---|---|---|---|---|---|
| melodic-software `gherkin-authoring` | 32 / 2026-11-20 / MIT | **unverified**: the skill isn't in the repo | ? | ? | the repo has many hooks | Can't evaluate |
| tsipotu `gherkin` | 2 / 2026-02-23 / **none** | Scenarios only | Yes, but a fixed YAML path | Yes | No | Best workflow, can't be copied |
| migueldialpad `bdd` | 0 / 2026-03-14 / **none** | Scenarios + pytest/TDD | Conceptual | Yes (es example) | No | Generic, assumes Cursor |
| rysweet amplihack `gherkin-expert` | 76 / 2026-07-26 / **none**, **archived** | Scenarios via an agent | Conceptual | No | The framework sets `bypassPermissions` and hooks | Avoid |
| LambdaTest `cucumber-skill` | 392 / 2026-11-17 / MIT | Step defs + cloud runner | No | No | Not in this skill (other skills in the repo do) | Wrong scope, imperative |
| el-feo `cucumber-gherkin` | 12 / 2026-07-22 / MIT | Ruby step defs + syntax | No | Yes | No | Ruby, accurate syntax |
| testland `gherkin-from-stories` / `cucumber-testing` / reviewer agent | 15 / 2026-11-18 / MIT | Scenarios; separate step-def skills | Step-library reuse | No | No | Best reviewer pattern |
| pantheon-org `bdd-testing` | 10 / 2026-11-16 / MIT | Scenarios + Cucumber.js runs | Reference file (not linked) | No | No | Thin |
| Tyler-R-Kendrick `gherkin` | 13 / 2026-06-09 / MIT | Syntax + style reference | No | No | No | Generic reference |
| ehdez73 `gherkin-generator-skill` | 0 / 2026-03-13 / **none** | Scenarios via a generator/reviewer loop | No | **Wrong** (no header) | No | Avoid |

"none" means GitHub reports no license (`gh api repos/<r>/license` returns 404), so the code is all rights reserved. We could borrow ideas, but not copy text.

None of the `SKILL.md` files declares `allowed-tools`, so each one runs with whatever permissions the session already has. testland's agents are the only ones that restrict their tools.

---

## Candidates

### 1. melodic-software/claude-code-plugins: `gherkin-authoring`, **unverified**

- **Provenance.** Org-owned, 32 stars, pushed 2026-11-20, MIT ([repo](https://github.com/melodic-software/claude-code-plugins)).
- **Not found.** No path in the current tree (42,476 entries) contains `gherkin`. A blobless clone with `git log --all -- '*gherkin*'` over all 10,749 commits found nothing either. The history starts at 2026-06-22, so it may have been rewritten. Commit search finds only one commit that mentions Gherkin, an EARS/planning change ([cfdd736](https://github.com/melodic-software/claude-code-plugins/commit/cfdd736189)). The org's other repos (`agent-plugins`, `codex-plugins`, `cursor-plugins`, `standards`) have no Gherkin files either.
- **What the directory shows.** The skills.sh page has a one-line description ("Gherkin/BDD acceptance criteria authoring for executable specifications"), 31 installs, and `npx skills add https://github.com/melodic-software/claude-code-plugins --skill gherkin-authoring` ([skills.sh](https://www.skills.sh/melodic-software/claude-code-plugins/gherkin-authoring)). Everything else about it is **unverified**. The listing probably points at a skill that has since been removed.
- **Safety note.** The repo ships many hook scripts under `.claude/hooks/` (for example `check-affected-pre-push.test.sh`), so installing the whole marketplace brings far more than one skill.

### 2. tsipotu/gherkin-skill: `gherkin`

- **Provenance.** User `tsipotU` ("Emiel" in `plugin.json`). 2 stars, last commit 2026-02-23. **No license** ([repo](https://github.com/tsipotU/gherkin-skill)).
- **Scope.** Scenarios only, through an interactive flow: understand, scan, write, present, append, glossary check, summary ([SKILL.md](https://github.com/tsipotU/gherkin-skill/blob/main/skills/gherkin/SKILL.md)).
- **Conventions.**
  - Ask 2–3 questions before proposing, then show a scenario checklist.
  - Glob `**/*.feature` and "**Match the project's existing style** — if they use `Scenario` instead of `Example`, ... specific tag conventions, or particular step phrasing patterns, follow those conventions."
  - Conflict detection by "**behavioral equivalence**, not identical wording".
  - Show the file before writing it.
  
  The best-practices reference covers:
  - "Keep Scenarios to 3-5 Steps … Aim for: 1-2 `Given`, 1 `When`, 1-2 `Then`", which matches the Cucumber reference;
  - Background "ideally under 4 steps";
  - Outline only "when the variations meaningfully test different cases";
  - `Rule` to group scenarios;
  - "Then Steps Observe Outcomes, Not Internals" ([best-practices.md](https://github.com/tsipotU/gherkin-skill/blob/main/skills/gherkin/references/best-practices.md)).
- **Glossary.** Yes, but only at `glossary/glossary.config.yml` with a `core.glossary.yml` that has `name`/`aliases`/`code_name`/`ui_label` fields ([SKILL.md §6](https://github.com/tsipotU/gherkin-skill/blob/main/skills/gherkin/SKILL.md)). It skips silently when that file is missing, so it would **never read our `GLOSSARY.md`**. A commit titled "Remove cross-repo glossary reference from marketplace" suggests it was split out of a companion glossary skill ([commit db2cfa46](https://github.com/tsipotU/gherkin-skill/commit/db2cfa46)).
- **Language.** It documents `# language: xx` and "Default to English when the user doesn't specify a language", and lists `es` ([gherkin-syntax.md](https://github.com/tsipotU/gherkin-skill/blob/main/skills/gherkin/references/gherkin-syntax.md)). For us, this is the part to switch off: under ADR 0002 nothing hand-writes Spanish.
- **Safety.** Markdown only. `plugin.json`/`marketplace.json` declare no hooks or commands. No `allowed-tools`.
- **Red flags.**
  - Tiny and young, with one author.
  - No license, so it can't be vendored.
  - Its examples use UI-ish, "should"-style outcomes: `Then they should see "Check your email for reset instructions"`, `And they should be redirected to the login page` ([SKILL.md example](https://github.com/tsipotU/gherkin-skill/blob/main/skills/gherkin/SKILL.md)).
  - Its tag examples are generic (`@smoke`, `@wip`, `@regression`).
- **Fit.**
  - *Agrees:* "Match the project's existing style" would keep `Then it is refused because the End Month is before the Start Month` and our `@id:` tags. The 1-line Background in `payments.feature` passes "Keep Background short".
  - *Clashes:* "1 `When`" against our confirm flows (`When I mark the April 2026 Payment of "Rent" as Pending` … `When I confirm`). It pushes `Rule` blocks where we use `# Start Month` comments. It doesn't know `@id` or the catalogue.

### 3. migueldialpad/skills: `bdd`

- **Provenance.** User, 0 stars, a single commit "Initial skills collection" on 2026-03-14. **No license**. Part of a grab-bag of 20+ unrelated skills (Astro, webOS TV, ...) ([repo](https://github.com/migueldialpad/skills)).
- **Scope.** Scenarios plus TDD, mocking, coverage and pytest-bdd/Cucumber.js examples ([SKILL.md](https://github.com/migueldialpad/skills/blob/master/skills/bdd/SKILL.md), [framework-examples.md](https://github.com/migueldialpad/skills/blob/master/skills/bdd/references/framework-examples.md)).
- **Conventions.** "**Declarative language** — what, not how"; "Keep scenarios **3-7 steps**", which is looser than Cucumber's 3–5; a Feature template with `As a [role] / I want [feature] / So that [benefit]`; a `Rule` example.
- **Glossary.** Conceptual only: "Maintain a Glossary" with a sample list ([collaboration.md](https://github.com/migueldialpad/skills/blob/master/skills/bdd/references/collaboration.md)). It reads no file.
- **Language.** A `# language: es` example ([gherkin-reference.md](https://github.com/migueldialpad/skills/blob/master/skills/bdd/references/gherkin-reference.md)).
- **Safety.** Markdown only.
- **Red flags.**
  - It says "Ask **1-2 critical questions** via AskQuestion tool". That isn't a Claude Code tool name, so it was written for another agent (Cursor).
  - It says "**No emojis** in feature files" but uses ❌/✅ in its own Gherkin samples.
  - Its "Good" example ends with `And a session should be created`, an internal detail that Cucumber's "observable output" rule argues against ([reference](https://cucumber.io/docs/gherkin/reference/)).
- **Fit.** Its declarative stance agrees with ours. The As-a template and the "should" phrasing clash with `Feature: Payments and their Payment Status` plus our prose-rule description.

### 4. rysweet/amplihack: `gherkin-expert`

- **Provenance.** User, 76 stars, pushed 2026-07-26, **archived**, **no license** ([repo](https://github.com/rysweet/amplihack)).
- **Scope.** The skill is a stub that "delegates to the `gherkin-expert` agent" ([SKILL.md](https://github.com/rysweet/amplihack/blob/main/.claude/skills/gherkin-expert/SKILL.md), [agent](https://github.com/rysweet/amplihack/blob/main/.claude/agents/amplihack/specialized/gherkin-expert.md)). Its frontmatter uses fields Claude Code doesn't define (`activation_keywords`, `agent: amplihack:specialized:gherkin-expert`), so it depends on the amplihack framework.
- **Conventions.** Declarative over imperative, "ubiquitous language from the bounded context", an As-a template, "more than 7-8 steps … Split it". Under "Incidental Details" it rates `Given a registered user` as GOOD, over specific data.
- **Glossary / language.** Conceptual; no `# language:` guidance.
- **Safety.** The framework's `.claude/settings.json` sets `"defaultMode": "bypassPermissions"`, allows `Bash`, `Write`, `WebFetch` and more, and registers `SessionStart`, `Stop` and `PostToolUse` (`matcher: "*"`) hooks that run Python from `$HOME/.amplihack/...` ([settings.json](https://github.com/rysweet/amplihack/blob/main/.claude/settings.json)). The skill alone is harmless text, but adopting it "as designed" means installing that framework.
- **Red flags.**
  - The agent claims "Gherkin-only prompts outperform English by +26%", with `gherkin_only` at 0.898. The repo's own findings doc reports the opposite: `english (baseline) 0.903`, `gherkin_only 0.792`, "Gherkin-only is unreliable" ([findings](https://github.com/rysweet/amplihack/blob/main/docs/gherkin_v2_experiment_findings.md)).
  - It's archived.
- **Fit.** The "only what matters" advice clashes with our deliberately concrete `Given a Fixed Expense "Gym" in ARS from January 2026 to March 2026 expecting 20000`. Here the data *is* the rule.

### 5. LambdaTest/agent-skills: `cucumber-skill`

- **Provenance.** Org (TestMu AI, formerly LambdaTest), 392 stars, pushed 2026-11-17, MIT. The skill was last touched 2026-02-23 ([repo](https://github.com/LambdaTest/agent-skills)).
- **Scope.** **Step definitions and test code** in Java/JS/Ruby, plus TestMu cloud execution (`LT_USERNAME`, `LT_ACCESS_KEY`, `https://hub.lambdatest.com/wd/hub`) ([SKILL.md](https://github.com/LambdaTest/agent-skills/blob/main/cucumber-skill/SKILL.md)).
- **Conventions.** Its anti-pattern table says "Imperative steps → Declarative steps", yet its core example is imperative: `When I enter "user@test.com" in the email field` / `And I click the login button` ([SKILL.md](https://github.com/LambdaTest/agent-skills/blob/main/cucumber-skill/SKILL.md)).
- **Glossary / language.** None.
- **Safety.** This skill folder holds only Markdown. Other skills in the same repo ship scripts (`cypress-skill/scripts/scaffold-project.sh`, `*/scripts/detect.py`, `api-skill/installer/testmu-skill-installer_code.sh`), so installing the whole repo needs a review.
- **Fit.** Poor. Its example is the UI-coupled style Cucumber's Better Gherkin argues against, and it steers toward a vendor cloud.

### 6. el-feo/ai-context: `cucumber-gherkin`

- **Provenance.** User, 12 stars, MIT. The skill was last changed 2026-03-13 ("reduce cucumber-gherkin SKILL.md and trim oversized references"). It's part of a `ruby-rails` plugin ([repo](https://github.com/el-feo/ai-context), [SKILL.md](https://github.com/el-feo/ai-context/blob/main/plugins/ruby-rails/skills/cucumber-gherkin/SKILL.md)).
- **Scope.** Gherkin syntax plus **Ruby step definitions**, hooks and Capybara.
- **Conventions.** It's accurate and compact on syntax: `Rule` (Gherkin 6+), tags on Rule/Examples, tag inheritance, "One behavior per scenario, 3-5 steps", "Keep Background short (≤4 lines)", and a declarative good/avoid pair ([SKILL.md](https://github.com/el-feo/ai-context/blob/main/plugins/ruby-rails/skills/cucumber-gherkin/SKILL.md), [gherkin-syntax.md](https://github.com/el-feo/ai-context/blob/main/plugins/ruby-rails/skills/cucumber-gherkin/references/gherkin-syntax.md)).
- **Glossary.** None.
- **Language.** It documents `# language:` and 70+ languages.
- **Safety.** Markdown only. The plugin also adds Rails commands and an agent.
- **Fit.** The Ruby half is irrelevant to us. Its syntax reference is a decent model of brevity. The fact that tags can sit on `Rule` matters if we ever turn `# Start Month` into `Rule:` blocks with `@id`s.

### 7. testland/qa: `qa-bdd` plugin (`gherkin-from-stories`, `cucumber-testing`, agents)

- **Provenance.** Org, 15 stars, pushed 2026-11-18, MIT. Plugin v1.9.8. `gherkin-from-stories` was last changed 2026-11-10. The mirror `testland/qa-skills` (0 stars) is what tessl.io packages ([repo](https://github.com/testland/qa), [plugin.json](https://github.com/testland/qa/blob/main/plugins/qa-bdd/.claude-plugin/plugin.json)).
- **Scope.**
  - `gherkin-from-stories` "Writes .feature files only, not step code" ([SKILL.md](https://github.com/testland/qa/blob/main/plugins/qa-bdd/skills/gherkin-from-stories/SKILL.md)).
  - `cucumber-testing` covers runners and step definitions ([SKILL.md](https://github.com/testland/qa/blob/main/plugins/qa-bdd/skills/cucumber-testing/SKILL.md)).
  - The `bdd-scenario-author` agent (tools `Read, Grep, Glob, Write`) scaffolds step definitions.
  - The `gherkin-style-reviewer` agent (tools `Read, Grep, Glob`) only reviews ([agent](https://github.com/testland/qa/blob/main/plugins/qa-bdd/agents/gherkin-style-reviewer.md)).
  
  This is the only candidate that ships evals (`skills/cucumber-testing/evals/*`).
- **Conventions.** "Flag implicit Givens … Flag-and-ask is the load-bearing pattern"; rewrite rule R5, "Preserve the project's existing vocabulary"; "at most one `When` per scenario"; cites both cucumber.io pages ([SKILL.md](https://github.com/testland/qa/blob/main/plugins/qa-bdd/skills/gherkin-from-stories/SKILL.md), [manual-step-rules.md](https://github.com/testland/qa/blob/main/plugins/qa-bdd/skills/gherkin-from-stories/references/manual-step-rules.md)). The reviewer "refuses to … Auto-rewrite scenarios. Recommendation only" and defers to a team `gherkin-conventions.md` ("team conventions override defaults").
- **Glossary.** No glossary file. It has a step-library-reuse discipline instead (`bdd-step-library-curator`), which is close in spirit to our catalogue.
- **Language.** No `# language:` guidance in these files.
- **Safety.** No scripts or hooks in `plugins/qa-bdd`. The agents' `tools` lists are the only explicit restrictions among all the candidates.
- **Red flags.**
  - Its own examples are imperative: `When I enter "WELCOME10" in the promo input` / `And I click "Apply"`. That sits next to its anti-pattern row "Imperative steps ("click button #foo")".
  - It says to replace vague Thens with "a visible `data-testid`, a response status", which is implementation leakage by Cucumber's definition ([Better Gherkin](https://cucumber.io/docs/bdd/better-gherkin/)).
  - It lists "Skipping the As-a / I-want / So-that header" as an anti-pattern ([SKILL.md](https://github.com/testland/qa/blob/main/plugins/qa-bdd/skills/gherkin-from-stories/SKILL.md)).
- **Fit.**
  - *Agrees:* flag-and-ask and R5 vocabulary reuse match `docs/agents/domain.md` ("Don't drift to synonyms the glossary explicitly avoids"). A read-only reviewer that defers to a conventions file is exactly the shape we want.
  - *Clashes:* it would flag our feature headers for the missing As-a triple, and our confirm scenarios for having two `When`s. Its "Vague Then" check (`Then the data is correct`) may misfire on `And nothing has changed`, which is precise in our domain.

### 8. pantheon-org/tekhne: `bdd-testing` (tessl `pantheon-ai/bdd-testing` 0.2.1)

- **Provenance.** Org, 10 stars, MIT. The skill was last changed 2026-10-21 ([repo](https://github.com/pantheon-org/tekhne), [SKILL.md](https://github.com/pantheon-org/tekhne/blob/main/skills/testing/bdd-testing/SKILL.md)).
- **Scope.** Scenarios plus running Cucumber.js (`npx cucumber-js --dry-run features`).
- **Conventions.** Short hard constraints: "Use business-facing language", "one behavior", "Reuse step phrases only when semantics are identical".
- **Glossary.** There's a 451-line [principles-ubiquitous-language.md](https://github.com/pantheon-org/tekhne/blob/main/skills/testing/bdd-testing/references/principles-ubiquitous-language.md), but the SKILL.md's reference list never links it, so an agent may never load it.
- **Language.** None.
- **Safety.** Markdown only. It tells the agent to run `pantheon-skill-auditor evaluate bdd-testing --json`, a tool we don't have.
- **Red flags.** Its GOOD example is `Then I should see "Order confirmed"`, which is UI phrasing. Several dated `.audits/` folders are self-graded.
- **Fit.** Thin. Nothing here that our own skill wouldn't say better.

### 9. Tyler-R-Kendrick/agent-skills: `specs/documentation/gherkin`

- **Provenance.** User, 13 stars, MIT. The skill was last changed 2026-02-11 ([repo](https://github.com/Tyler-R-Kendrick/agent-skills), [SKILL.md](https://github.com/Tyler-R-Kendrick/agent-skills/blob/main/skills/specs/documentation/gherkin/SKILL.md)).
- **Scope.** Syntax and style reference across runners. A separate `dotnet/testing/bdd-cheatsheet` covers SpecFlow.
- **Conventions.**
  - "Write declarative, not imperative scenarios"; "Use Rules (Gherkin 6+)"; "aim for 3-7 steps"; "Avoid conjunctive steps".
  - "Tag strategically … not for test management metadata".
  - The sibling cheatsheet has a rule "limit scenarios to one when step".
- **Glossary / language.** None. No `# language:` at all.
- **Safety.** Markdown/JSON only.
- **Red flags.** The `rules/*.md` files are 10-line stubs that just repeat the bullet ([example](https://github.com/Tyler-R-Kendrick/agent-skills/blob/main/skills/specs/documentation/gherkin/rules/gherkin-use-rules-gherkin-6.md)). Its step table uses `When the user clicks "Checkout"` as the When example.
- **Fit.** It's generic. "Not for test management metadata" could be read as arguing against our `@id:` tags, which ADR 0002 makes mandatory.

### 10. ehdez73/agent-skills: `gherkin-generator-skill`

- **Provenance.** User, 0 stars, last commit 2026-03-13. **No license** ([repo](https://github.com/ehdez73/agent-skills)).
- **Scope.** Scenarios through a generator agent and a reviewer agent that loop "until approved (score ≥85)", up to 5 iterations ([SKILL.md](https://github.com/ehdez73/agent-skills/blob/main/skills/gherkin-generator-skill/SKILL.md)).
- **Conventions.** "no UI coupling". It requires tags from a fixed set (`@smoke, @happy-path, @edge-case, @error-handling, @regression`) and "100% functional coverage".
- **Glossary.** None.
- **Language.** "Detect the language of the original requirements … `ES: Característica: Gestión de Usuarios`" ([gherkin-rules.md](https://github.com/ehdez73/agent-skills/blob/main/skills/gherkin-generator-skill/references/gherkin-rules.md)). None of its files ever mentions the `# language:` header. Without it, Cucumber parses as English and Spanish keywords fail ([reference](https://cucumber.io/docs/gherkin/reference/)). That's a correctness bug.
- **Safety.** Markdown only. The loop spends up to 10 subagent calls per feature.
- **Red flags.** Its "Approved" example output is imperative: `Given I am on the registration page` / `When I enter the email ...` / `And I submit the form`. The score threshold is arbitrary.
- **Fit.** Poor. Its forced tags clash with `@id:` and its language handling contradicts ADR 0002.

### Others noticed

- `sickn33/antigravity-awesome-skills` mirrors LambdaTest's `cucumber-skill` (it came up in search, [raw](https://raw.githubusercontent.com/sickn33/antigravity-awesome-skills/main/skills/cucumber-skill/SKILL.md)). It isn't independent work, so I didn't evaluate it.
- No skill from Cucumber/SmartBear was found (see [Baseline](#baseline-what-cucumber-itself-says)).

## Patterns across all candidates

1. **None handles our must-haves.** I found no mention of stable per-scenario ID tags, a step/translation catalogue, or a generated twin that must not be hand-edited in any of the files read.
2. **Glossary support is weak.** Only tsipotu actually reads a glossary, and only at a fixed YAML path. testland reuses vocabulary through a step library. The rest only describe the idea.
3. **Their examples break their own rules.** LambdaTest, testland and ehdez73 all call for declarative steps and then show `I enter ... / I click ...`. A skill's examples steer the agent more than its rules do, so adopting any of them as-is would pull our specs toward UI steps.
4. **Several rules go further than Cucumber, and they clash with us.** "One When" (tsipotu, testland, Tyler's cheatsheet), the As-a header (migueldialpad, rysweet, testland, ehdez73) and "should" outcomes. Cucumber recommends none of these ([reference](https://cucumber.io/docs/gherkin/reference/), [Better Gherkin](https://cucumber.io/docs/bdd/better-gherkin/)). Our warn/confirm scenarios use two When/Then pairs on purpose, and so far they stay at 5–6 steps.

## Recommendation

**Write our own project skill**, for example `.claude/skills/writing-specs/SKILL.md`. Write it with the installed `mattpocock-skills:writing-for-agents` skill. Don't adopt or vendor any candidate:

- The license-free ones (tsipotu, migueldialpad, rysweet, ehdez73) can't legally be copied.
- The MIT ones (testland, el-feo, Tyler, pantheon, LambdaTest) are either step-definition oriented or would need most of their examples rewritten.

What the skill should contain, and where each idea comes from:

| Idea | Borrow from | Adapt for us |
|---|---|---|
| Glob existing `.feature` files, match their style, and check for **behavioural** duplicates before writing | tsipotu §2 ([SKILL.md](https://github.com/tsipotU/gherkin-skill/blob/main/skills/gherkin/SKILL.md)); ideas only, in our own words | Point it at `specs/en/**` only, and never at `specs/es/` |
| Ask 2–3 questions, then show a scenario checklist before drafting | tsipotu §1 | Fits the "approved live with the human" rule in `docs/agents/domain.md` |
| Flag-and-ask on implicit Givens instead of making them up | testland `gherkin-from-stories` (MIT) | As is |
| Preserve existing vocabulary (R5) and reuse existing step phrasings | testland [manual-step-rules.md](https://github.com/testland/qa/blob/main/plugins/qa-bdd/skills/gherkin-from-stories/references/manual-step-rules.md) | Reuse matters doubly for us: every new phrasing costs a catalogue entry |
| Glossary check after drafting | tsipotu §6 | Read `GLOSSARY.md`. Fail on any `_Avoid_` synonym and on lowercase glossary terms. Unknown nouns get noted for `/domain-modeling` |
| Read-only reviewer that recommends and never rewrites, with a house conventions file overriding the defaults | testland `gherkin-style-reviewer` (MIT; tools `Read, Grep, Glob`) | Run it as a second pass or subagent. Our conventions live in the skill itself |
| Syntax facts (Rule, Background scope, tags on Rule, `# language:`) | cucumber.io [reference](https://cucumber.io/docs/gherkin/reference/); el-feo's compact layout | Keep it short and link cucumber.io rather than copying it |

House rules to write down. None of the candidates has them:

1. Every Feature and Scenario gets `@id:<area>.<feature>.<slug>`. IDs are never reused or renamed (ADR 0002).
2. Any new or reworded step, or a new title, means a catalogue entry in the same change (ADR 0002). Never touch `specs/es/`, and never add `# language:` to English files.
3. The Feature description states the rules in prose (as in `create.feature`). No As-a/I-want/So-that.
4. Use first-person domain verbs and present-tense outcomes. Refusals read `it is refused because …`, and the no-op check is `nothing has changed`. Don't use "should".
5. Keep the concrete data that carries the rule (Months, currency, amounts). Use a Payments table when several Months matter.
6. Aim for one When. The warn → confirm/decline flow is the only allowed exception: `When … / Then I am warned … / When I confirm|decline / Then …`.
7. Background holds only setup that every scenario in the file shares, ideally one or two lines. Use Scenario Outline only when the rows test the same rule.
8. No generic suite tags (`@smoke`, `@wip`) until we decide on a tagging scheme.

One open question for a human, which the skill shouldn't settle by itself: should the `# Start Month` / `# Reopening` comment sections in `range.feature` become `Rule:` blocks? Cucumber defines `Rule` as "one _business rule_" ([reference](https://cucumber.io/docs/gherkin/reference/)), and tags can sit on a Rule. But these sections group operations, not rules, and each Rule would need an `@id` and catalogue key under ADR 0002.

If we want an off-the-shelf piece anyway, the least-bad option is to **vendor testland's `gherkin-style-reviewer` agent** (MIT, read-only tools, no scripts). We'd override its As-a, one-When and data-testid defaults through the conventions file it already respects. Don't install the whole `qa-bdd` plugin: its `bdd-scenario-author` agent has `Write` and scaffolds step definitions we don't want yet.

## Unverified

- The content, tool permissions and conventions of melodic-software `gherkin-authoring`. I couldn't find it in the repo or its history, and only the skills.sh summary exists.
- Install counts and directory descriptions (skills.sh, tessl.io) beyond what's quoted above.
- That no official Cucumber/SmartBear skill exists outside their GitHub orgs' default branches.

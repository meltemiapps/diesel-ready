# Content schema (version 2)

All learning content lives in `DieselReady/Resources/Content/` as UTF-8 JSON.
The format is platform-neutral: the iOS app decodes it with `Codable`, and the
Android app will read the same files. Use plain JSON types only; no
platform-specific fields.

## `manifest.json`

```json
{ "schemaVersion": 2, "modules": ["01-how-a-diesel-engine-works.json"], "faults": "faults.json",
  "safety": "safety.json", "checklists": "checklists.json",
  "contentInfo": { "version": "1.2", "status": "draft", "reviewDate": "2026-11-20",
  "engineerApproval": "pending", "changeLog": [{ "version": "1.2", "date": "2026-11-20", "summary": "..." }] } }
```

| Field | Type | Notes |
|---|---|---|
| `schemaVersion` | integer | Apps refuse content with a higher version than they support. Version 2 added the safety file, action levels, stop cards and content info. |
| `modules` | string[] | File names under `modules/`, in display order. |
| `faults` | string (optional) | Fault finder file, relative to the content folder. |
| `safety` | string (optional) | Safety notices, action levels and applicability tags, relative to the content folder. Required for the bundled course. |
| `checklists` | string (optional) | Pre-start and post-start checklists (Checks tab), relative to the content folder. Required for the bundled course. Added in content 1.2 as an optional field, so schema version 2 is unchanged. |
| `contentInfo` | object (optional) | Shown on the About tab. Required for the bundled course. See below. |

### `contentInfo`

| Field | Type | Notes |
|---|---|---|
| `version` | string | Content version, e.g. `"1.1"`. |
| `status` | string | `"draft"` until a qualified marine engineer has approved the content. |
| `reviewDate` | string | Date of the latest technical review, `yyyy-MM-dd`. |
| `engineerApproval` | string | `"pending"`, or the approving engineer once approved. |
| `changeLog` | `{ "version", "date", "summary" }[]` | Newest first. The first entry must have the current `version`. Dates are `yyyy-MM-dd`. |

## `safety.json`

Wording shared by lessons, quiz feedback and the Fault finder, so every surface says the same thing.

| Field | Type | Notes |
|---|---|---|
| `notices` | Notice[] | Notice = `{ "id", "level": "stop" or "warning", "title", "text" }`. `text` may use `**bold**` for emphasis and no other markup. Must include `wet-exhaust-waterlock`, `high-pressure-fuel`, `oil-pressure-stop` and `overheating-stop`, whose wording is approved and must not be edited. |
| `actionLevels` | `{ "id", "label", "description" }[]` | Exactly `observe` (look and check only), `owner` (owner maintenance, handbook required) and `engineer` (qualified engineer only). The app shows `label` on each step. |
| `tags` | `{ "id", "group", "label" }[]` | Installation types: `mechanical-injection`, `common-rail`; `direct-cooling`, `heat-exchanger`, `keel-cooling`; `packed-gland`, `shaft-seal`; `lead-acid`, `lithium`. |

## `modules/NN-slug.json`

| Field | Type | Notes |
|---|---|---|
| `id` | string | `m01`, `m02`, ... Stable; progress is keyed on it. |
| `number` | integer | Must equal the module's position in the manifest (1-based). |
| `title`, `summary` | string | |
| `lessons` | Lesson[] | 3 to 6 per module. |
| `questions` | Question[] | All questions for this module. |

### Lesson

| Field | Type | Notes |
|---|---|---|
| `id` | string | `m01-l01`. Stable. |
| `title`, `intro` | string | |
| `estimatedMinutes` | integer | Greater than 0. Module time is the sum. |
| `diagram` | Diagram or null | Drawn natively from shapes; all text comes from the JSON. |
| `safetyNoticeIds` | string[] (optional) | Notices from `safety.json`, shown **before the steps**. |
| `caution` | string or null | Hazard warning, shown as a caution callout **before the steps**. |
| `appliesTo` | string[] (optional) | Tags from `safety.json`: the installation types the lesson is written for. Shown as "Applies to". |
| `steps` | Step[] | At least one. Step = `{ "title": string or null, "text": string, "action": "observe", "owner" or "engineer" }`. Shown numbered, with the action level's label. `action` is required on every step of a hands-on lesson and optional elsewhere. Steps never contain warnings. |
| `handsOn` | boolean | True for a procedure. Every step then needs an `action`, and the app ends the lesson with the reminder to follow the engine manufacturer's handbook. |
| `reviewStatus` | `"draft"` or `"reviewed"` | |
| `reviewNote` | string (optional) | What the expert reviewer should check. Never shown in the app; exported to `docs/content-review.md`. |
| `checklistIds` | string[] (optional) | Checklists from `checklists.json` this lesson teaches. Shown as buttons that open the Checks tab. Each checklist's `lessonId` must point back. |

### Diagram

| Field | Type | Notes |
|---|---|---|
| `kind` | string | Which drawing to use. Unknown kinds are skipped, so older apps can read newer content. |
| `caption` | string or null | Shown under the drawing. |
| `labels` | DiagramLabel[] | Text drawn with the diagram, in the order the kind defines. DiagramLabel = `{ "title": string, "detail": string or null }`. |
| `description` | string | Full description read by screen readers in place of the drawing. |

Known kinds and their label counts:

| Kind | Labels | Order |
|---|---|---|
| `compression-ignition` | 3 | Panels left to right: air in, compression, ignition |
| `four-stroke-cycle` | 4 | Induction, compression, power, exhaust |
| `engine-layout` | 7 | Numbered parts: head, injectors, block and pistons, crankshaft, sump, flywheel, injection pump |
| `flow` | 2 to 7 | Numbered stages joined by arrows, top to bottom (for circuits and sequences) |

### Question

| Field | Type | Notes |
|---|---|---|
| `id` | string | `m01-q001`. Stable. |
| `moduleId` | string | Must match the containing module. |
| `lessonId` | string | Must be a lesson in this module. |
| `difficulty` | integer | 1 (easy) to 3 (hard). |
| `prompt` | string | |
| `options` | string[4] | Exactly four, all different. |
| `correctIndex` | integer | 0-based index into `options`. Apps shuffle options when displaying them. |
| `explanation` | string | One or two sentences. |
| `safetyNoticeIds` | string[] (optional) | Notices from `safety.json`, shown first in the answer feedback. |
| `categories` | string[] (optional) | Any of `"safety-critical"` (keeps people, the boat or the engine safe; required on every question with a safety notice), `"scenario"` (built around a situation) and `"unsafe-distractor"` (a wrong answer is an unsafe action, so the explanation must say why it is dangerous). Mock tests and the results screen use the first two. |
| `reviewStatus` | `"draft"` or `"reviewed"` | |
| `reviewNote` | string (optional) | What the expert reviewer should check. Never shown in the app; exported to `docs/content-review.md`. |

## `faults.json` (Fault finder tab)

| Field | Type | Notes |
|---|---|---|
| `intro` | string | Shown at the top of the tab. |
| `reminder` | string | Shown at the end of every symptom. Must not be empty. Tells the reader to follow the engine manufacturer's handbook and to ask a qualified marine engineer. |
| `stopCards` | StopCard[] | Shown first, before the symptom chips. StopCard = `{ "id", "title", "stop", "doNotRestart", "getAssistance" }`, all non-empty. One card each is required for `low-oil-pressure`, `overheating`, `water-ingress`, `suspected-waterlock`, `fuel-spray`, `smoke-or-fire` and `shaft-seal-leak`. |
| `symptoms` | Symptom[] | In chip order. |

### Symptom

| Field | Type | Notes |
|---|---|---|
| `id` | string | Stable. All six must be present: `exhaust-smoke`, `wont-start`, `overheating`, `stops-suddenly`, `low-oil-pressure`, `not-charging`. |
| `title`, `summary` | string | |
| `safetyNoticeIds` | string[] (optional) | Notices shown first, before anything else. `low-oil-pressure` must open with `oil-pressure-stop`, `overheating` with `overheating-stop` and `wont-start` with `wet-exhaust-waterlock`. |
| `stopCardIds` | string[] (optional) | Stop cards shown next. `low-oil-pressure`, `overheating` and `wont-start` must include `low-oil-pressure`, `overheating` and `suspected-waterlock` respectively. |
| `possibleCauses` | `{ "title": string, "detail": string }[]` | At least one. **Not ranked**: the app shows them as an unordered list, and no fault text may rank causes by frequency. |
| `checkFirst` | string[] | At least one, in the order to do them. |
| `lessonIds` | string[] | At least one, no duplicates. **Every id must be an existing lesson**, or loading fails. |
| `reviewStatus` | `"draft"` or `"reviewed"` | |
| `reviewNote` | string (optional) | What the expert reviewer should check. Never shown in the app; exported to `docs/content-review.md`. |

Icons for the chips are chosen by the app from the symptom id; they are not content.

## `checklists.json` (Checks tab)

| Field | Type | Notes |
|---|---|---|
| `mnemonic` | `{ "name", "summary", "letters": [{ "letter", "word" }] }` | The mnemonic the checklists follow (WOBBLE), introduced as a widely used memory aid and attributed to no one. The letters spell `name`. |
| `reminder` | string | Shown at the end of each checklist: follow the handbook. |
| `checklists` | Checklist[] | Exactly `pre-start` then `post-start`. |

Checklist = `{ "id", "title", "subtitle", "intro", "banner" (optional), "engineRunning", "lessonId", "sections", "reviewStatus", "reviewNote" (optional) }`.
`engineRunning: true` means every item must be `observe` and the `banner` (shown first) is required.
`lessonId` must exist and list this checklist in its `checklistIds`.

Section = `{ "id", "letter" (optional), "title", "items" }`. Read in order across both checklists, the sections with a `letter` must spell the memory aid, and their titles must equal its words.

Item = `{ "id", "title", "detail", "action": "observe" or "owner", "lessonId", "safetyNoticeIds" (optional), "symptomId" (optional), "reviewStatus" }`.
Safety wording is referenced by notice id, never copied. `symptomId` links to a Fault finder symptom. Ticks are held in memory by the app for the session only; nothing is stored.

## Validation

Volume rules for the bundled course:

- 3 to 6 lessons per module.
- At least 3 questions per lesson, so "Check your knowledge" always works.
- Every module has questions at each difficulty, 1 to 3.
- At least 150 questions in total.
- No two questions with the same text (ignoring case, spacing and punctuation).

Question rules:

- Categories are known values, listed once each, and every question with a safety notice is safety-critical.
- The course has enough safety-critical and scenario questions to build a mock test (at least 6 of each).

Mock tests (built by the app, not stored): 30 questions balanced across all modules (each module's share differs by at most one), at least 6 safety-critical, at least 6 scenario and at least 5 of each difficulty, never repeating a question, in a shuffled order with shuffled options. The results list missed safety-critical questions first.

Safety rules:

- Every step of a hands-on lesson has an action level.
- A hazardous procedure (a hands-on lesson with any `owner` or `engineer` step) has a warning before its steps: a `caution` or at least one safety notice.
- No step contains a warning, because it would come after the steps before it. A step whose text or title starts with "Warning", "Caution" or "Danger", or contains WARNING, CAUTION, DANGER or STOP in capitals, fails.
- Every referenced notice, tag and stop card exists, and each is listed once.
- Every STOP condition has a complete card, and the three dangerous symptoms open with their notice and card.
- No content ranks causes by frequency ("most common", "most likely", "commonest", "most often", "in order of likelihood"; in the Fault finder also "less common", "more common", "less likely", "more likely", "likely first").
- Checklists: both lists present in order, ids unique, sections spell the memory aid, every lesson, notice and symptom link resolves, no engineer-only items, running-engine lists are observe only with a banner, and each list's lesson links back to it (and every lesson's `checklistIds` resolve).
- `contentInfo` has a valid review date, a non-empty approval entry and a change log that starts with the current version.

The iOS loader (`ContentLoader.validate`) enforces every rule above, and the
unit tests run it against the bundled files. `scripts/export-content-review.py`
writes the review pack (`docs/content-review.md`) and the question-level QA
sheet (`docs/quiz-review.csv`).

# Content schema (version 1)

All learning content lives in `DieselReady/Resources/Content/` as UTF-8 JSON.
The format is platform-neutral: the iOS app decodes it with `Codable`, and the
Android app will read the same files. Use plain JSON types only; no
platform-specific fields.

## `manifest.json`

```json
{ "schemaVersion": 1, "modules": ["01-how-a-diesel-engine-works.json"], "faults": "faults.json" }
```

| Field | Type | Notes |
|---|---|---|
| `schemaVersion` | integer | Apps refuse content with a higher version than they support. |
| `modules` | string[] | File names under `modules/`, in display order. |
| `faults` | string (optional) | Fault finder file, relative to the content folder. Optional so older content still loads. |

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
| `steps` | Step[] | At least one. Step = `{ "title": string or null, "text": string }`. Shown numbered. |
| `caution` | string or null | Shown as a caution callout. |
| `handsOn` | boolean | If true, the app ends the lesson with the reminder to follow the engine manufacturer's handbook. |
| `reviewStatus` | `"draft"` or `"reviewed"` | |
| `reviewNote` | string (optional) | What the expert reviewer should check. Never shown in the app; exported to `docs/content-review.md`. |

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
| `reviewStatus` | `"draft"` or `"reviewed"` | |
| `reviewNote` | string (optional) | What the expert reviewer should check. Never shown in the app; exported to `docs/content-review.md`. |

## `faults.json` (Fault finder tab)

| Field | Type | Notes |
|---|---|---|
| `intro` | string | Shown above the symptom chips. |
| `reminder` | string | Shown at the end of every symptom. Must not be empty. Tells the reader to follow the engine manufacturer's handbook and to ask a qualified marine engineer. |
| `symptoms` | Symptom[] | In chip order. |

### Symptom

| Field | Type | Notes |
|---|---|---|
| `id` | string | Stable. All six must be present: `exhaust-smoke`, `wont-start`, `overheating`, `stops-suddenly`, `low-oil-pressure`, `not-charging`. |
| `title`, `summary` | string | |
| `stopFirst` | `{ "title": string, "text": string }` or null | Shown before any diagnosis. **Required** for `overheating` and `low-oil-pressure`, with the title exactly `"Stop the engine"`. Null for the others. |
| `causes` | `{ "title": string, "detail": string }[]` | At least one. **Most likely first**; the app numbers them in this order. |
| `checkFirst` | string[] | At least one, in the order to do them. |
| `lessonIds` | string[] | At least one, no duplicates. **Every id must be an existing lesson**, or loading fails. |
| `reviewStatus` | `"draft"` or `"reviewed"` | |
| `reviewNote` | string (optional) | What the expert reviewer should check. Never shown in the app; exported to `docs/content-review.md`. |

Icons for the chips are chosen by the app from the symptom id; they are not content.

## Validation

Volume rules for the bundled course:

- 3 to 6 lessons per module.
- At least 3 questions per lesson, so "Check your knowledge" always works.
- Every module has questions at each difficulty, 1 to 3.
- At least 150 questions in total.
- No two questions with the same text (ignoring case, spacing and punctuation).

The iOS loader (`ContentLoader.validate`) enforces every rule above, and the
unit tests run it against the bundled files.

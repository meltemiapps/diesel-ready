# Content schema (version 1)

All learning content lives in `DieselReady/Resources/Content/` as UTF-8 JSON.
The format is platform-neutral: the iOS app decodes it with `Codable`, and the
Android app will read the same files. Use plain JSON types only; no
platform-specific fields.

## `manifest.json`

```json
{ "schemaVersion": 1, "modules": ["01-how-a-diesel-engine-works.json"] }
```

| Field | Type | Notes |
|---|---|---|
| `schemaVersion` | integer | Apps refuse content with a higher version than they support. |
| `modules` | string[] | File names under `modules/`, in display order. |

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
| `diagram` | object or null | `{ "kind": string, "caption": string or null }`. Drawn natively; unknown kinds are skipped. |
| `steps` | Step[] | At least one. Step = `{ "title": string or null, "text": string }`. Shown numbered. |
| `caution` | string or null | Shown as a caution callout. |
| `handsOn` | boolean | If true, the app ends the lesson with the reminder to follow the engine manufacturer's handbook. |
| `reviewStatus` | `"draft"` or `"reviewed"` | |

Diagram kinds used so far: `compression-ignition`, `four-stroke-cycle`, `engine-layout`.

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

The iOS loader (`ContentLoader.validate`) enforces every rule above, and the
unit tests run it against the bundled files.

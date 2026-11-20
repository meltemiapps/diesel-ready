# Build brief: Diesel Ready (Unofficial Marine Diesel Study Guide), iOS v1

---

You are building a native iOS app called **Diesel Ready** for **Meltemi Apps** (independent app studio, https://meltemiapps.co.uk). It sits alongside the studio's other apps, such as Callsign Ready, and follows the same model: free, no data collected, no tracking, and open source. Its App Store name is **"Diesel Ready: Marine Diesel"** and its subtitle is **"Unofficial engine revision aid"**. It is an independent, offline study guide for leisure boaters learning basic marine diesel engine care and fault-finding.

## Non-negotiable constraints

1. **Unofficial and unaffiliated.** The app must never use the name, logo, colours, course titles, syllabus wording or certificate names of any training body, sailing association, awarding organisation or engine manufacturer. Do not write the name or abbreviation of any training organisation, sailing association or awarding body anywhere: in code, strings, asset names, bundle ID, metadata, keywords or comments. The one exception is the generic statement "not affiliated with any training organisation", with no organisation named.
2. **Original content only.** Write every lesson, diagram label and quiz question from scratch in plain British English. Do not copy or paraphrase any published course book, handbook or manufacturer manual.
3. **No data collection.** No accounts, analytics, ads, crash-reporting SDKs, tracking or network calls. The app works fully offline. Progress is stored on the device only.
4. **No third-party dependencies.** Use Apple frameworks only.
5. **Safety framing.** Content is general guidance. Every lesson that involves hands-on work ends with a reminder to follow the engine manufacturer's handbook.

## Tech stack

- Swift 6, SwiftUI, iOS 17.0 minimum, iPhone first (iPad supported in portrait and landscape, no special layout needed).
- Architecture: simple MVVM with `@Observable` view models.
- Persistence: SwiftData for progress, quiz attempts and bookmarks.
- Content: bundled JSON files in `Resources/Content/`, decoded at launch into `Codable` models. No content is hard-coded in views.
- Bundle ID: `uk.co.meltemiapps.dieselready`. Leave the Team setting for the developer to choose in Xcode.
- Keep all content JSON and its schema platform-neutral (no Swift-specific fields), so the Android version can reuse the same files unchanged.

## Open source and repository

- Public repo: `github.com/meltemiapps/diesel-ready`. Initialise git from the first commit, with a sensible `.gitignore` for Xcode (exclude `xcuserdata`, `DerivedData`, `.DS_Store`).
- Code licence: **MIT** (`LICENSE`). Do not use GPL; it conflicts with App Store distribution terms.
- Content licence: **CC BY-NC-SA 4.0** for everything under `Resources/Content/` (`CONTENT-LICENSE`), so others can learn from and adapt it but not sell it.
- `README.md`: what the app is, the unofficial and unaffiliated statement, the privacy stance, a build guide, licences, links to the App Store page and https://meltemiapps.co.uk/diesel-ready/.
- No secrets, API keys or personal data anywhere in the repo. Keep the Team ID out of committed files where Xcode allows.

## Distribution

- Free, with no in-app purchases.
- Available in every App Store territory **except China mainland**. Record this in `docs/app-store-metadata.md` so it is set in App Store Connect under Pricing and Availability.

## Design system (match the approved preview)

- Colours: Navy `#0F2A3D` (hero surfaces), Deep blue `#163A52`, Accent amber `#F2A33A` (primary buttons, with navy text on top, never white text), Link blue `#1F4E6B`, Ink `#13212B`, Secondary text `#4A5A66`, Background `#F4F6F7`, Surface `#FFFFFF`, Divider `#DCE3E8`, Success `#1E7A4C` on `#E6F4EC`, Error `#B3261E` on `#FBE9E7`, Caution text `#6B3A00` on `#FFF4E3`.
- Type: SF Pro (system) for body; headings use the system rounded or default design in bold. Support Dynamic Type throughout.
- Corner radius 14–22pt on cards and buttons. Touch targets at least 44pt.
- Icons: SF Symbols only.
- Full Dark Mode support with equivalent contrast. Text contrast must meet WCAG AA (4.5:1).
- VoiceOver labels on every icon-only control.

## Screens

1. **First-launch disclaimer.** Shown once before anything else. App name, the subtitle "Unofficial marine diesel engine study guide", and a card stating: this is an independent revision aid; it is not an official course; it awards no certificate; it is not affiliated with, endorsed by or connected to any training body, sailing association or engine manufacturer; follow your engine handbook and a qualified engineer's advice. Include a required checkbox ("I understand this app is unofficial and for study purposes only"), an "Agree and continue" button (disabled until ticked) and a link to the privacy policy. Store acceptance with a version number so the screen reappears if the disclaimer text changes.
2. **Home / Learn tab.** Header with "Unofficial" badge. Progress card showing modules completed, a progress bar, "Continue lesson" (resumes the last unfinished lesson) and "Quick quiz" (10 random questions). A module list showing number, title, lesson count and estimated minutes, with a completed tick.
3. **Module → lesson list → lesson reader.** Each lesson has a title, an intro paragraph, optional simple diagrams built in SwiftUI (no images needed for v1), numbered steps, an optional caution callout and a "Check your knowledge" button that launches a 3–5 question quiz for that lesson. Show progress through the module ("3 / 5"). Mark the lesson complete when the reader reaches the end.
4. **Quiz.** One question per screen, four options, instant feedback (correct option turns green, wrong pick turns red) and an explanation. Score summary at the end, with a list of missed questions to review. Modes: per lesson, per module, quick quiz (10 random) and mock test (30 questions across all modules, results by module).
5. **Fault finder tab.** Filter chips for symptoms (Exhaust smoke, Won't start, Overheating, Stops suddenly, Low oil pressure, Not charging). Each symptom shows likely causes in order of likelihood, what to check first, and a link to the relevant lesson.
6. **About tab.** The unofficial and unaffiliated statement, a privacy summary (no account; progress stays on device; no ads, analytics or tracking; deleting the app removes all data), safety and trademark notice ("Any third-party names belong to their respective owners and are used only to describe subject matter"), the full privacy policy on its own screen, a "Reset progress" action with confirmation, app version, support email `support@meltemiapps.co.uk`, and links to the website, the GitHub repo and both licences.

Tab bar: Learn, Quiz, Faults, About.

## Content to write (original)

Modules:
1. How a diesel engine works (four-stroke cycle, compression ignition, main components)
2. Fuel system and bleeding (tank, filters, water separation, lift pump, injection pump, injectors, bleeding sequence, diesel bug)
3. Cooling systems (raw water circuit, seacock, strainer, impeller, heat exchanger, fresh water circuit, thermostat, direct versus indirect cooling)
4. Lubrication (oil checks, oil and filter change, oil pressure warnings)
5. Electrics and starting (batteries, alternator, starter motor, glow plugs, warning lights, basic checks)
6. Drive belts and stern gear (belt tension and inspection, gearbox oil, stern gland, shaft and propeller)
7. Routine maintenance (daily pre-start checks, service intervals, winterising and recommissioning, spares and tool kit)
8. Fault finding (systematic approach, linked to the Fault finder tab)

Volume for v1: 3–6 lessons per module and **at least 150 quiz questions** in total, each with one correct answer, three plausible distractors and a one or two sentence explanation. Tag each question with module, lesson and difficulty (1–3).

Put a `"reviewStatus": "draft"` field on every lesson and question. A qualified marine engineer will review the content before release.

## Privacy and App Store requirements

- Include `PrivacyInfo.xcprivacy` declaring no data collected and no tracking. Declare the `UserDefaults` required-reason API if it is used.
- No App Tracking Transparency prompt (nothing is tracked).
- Generate website pages in `docs/site/diesel-ready/`, following the same structure as the studio's other apps:
  - `index.html` (About): `https://meltemiapps.co.uk/diesel-ready/`
  - `privacy/index.html`: `https://meltemiapps.co.uk/diesel-ready/privacy/`. Plain English and UK GDPR aware. It states that no personal data is collected, stored off the device or transmitted, and includes the full unofficial and unaffiliated statement.
  - `support/index.html`: `https://meltemiapps.co.uk/diesel-ready/support/`. FAQs, the support email and a link to GitHub Issues.
  - Keep the markup plain and self-contained so I can drop it into the existing site.
- Generate `docs/app-store-metadata.md` with name, subtitle, a description of up to 4,000 characters, a 100-character keyword list (generic terms only, such as marine diesel, boat engine, outboard, inboard, fuel bleeding, impeller, sailing, maintenance, quiz, study; no organisation names), promotional text, privacy URL and support URL (as above), copyright "© 2026 Meltemi Apps", availability (all territories except China mainland), price (free), age rating answers (4+) and the privacy "Data Not Collected" answers.
- Generate an app icon set: a simple geometric amber cog on navy, with no text and no resemblance to any organisation's logo.

## Delivery in phases

Work in this order. Stop at the end of each phase, summarise what was built, and wait for my go-ahead.

1. **Phase 1, skeleton:** Xcode project, design tokens, tab bar, first-launch disclaimer, About and privacy screens, JSON content models and loader, with one sample module.
2. **Phase 2, learning flow:** module list, lesson reader, progress tracking with SwiftData, continue-where-you-left-off.
3. **Phase 3, quizzes:** all quiz modes, results, review of missed questions.
4. **Phase 4, fault finder.**
5. **Phase 5, full content:** all modules, lessons and 150+ questions as JSON.
6. **Phase 6, polish:** Dark Mode, Dynamic Type, VoiceOver pass, icon, unit tests for content decoding, progress logic and quiz scoring, App Store metadata and privacy docs.

7. **Phase 7, Android (after the iOS release):** a separate `android/` module in the same repo. Kotlin and Jetpack Compose, minSdk 26, the same screens and design tokens, reading the same JSON content files. Progress is stored locally with Room or DataStore. No Google Play Services, Firebase, analytics or network permission. Prepare the Google Play Data safety answers ("No data collected or shared") and a store listing in `docs/play-store-metadata.md`. Package name `uk.co.meltemiapps.dieselready`.

At each phase, run a build and the tests, and fix all warnings before reporting back.

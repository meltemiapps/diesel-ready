# Diesel Ready

**Diesel Ready: Marine Diesel Study Guide** is a free, offline iOS study guide for
leisure boaters learning basic marine diesel engine care and fault-finding. It is
made by [Meltemi Apps](https://meltemiapps.co.uk), an independent app studio.

- Website: https://meltemiapps.co.uk/diesel-ready/
- App Store: link to follow at release

> **Status:** in development (Phase 4, fault finder). All lesson and quiz content is
> marked `"reviewStatus": "draft"` until it has been reviewed by a qualified
> marine engineer.

## Unofficial and unaffiliated

Diesel Ready is an independent, unofficial revision aid. It is not an official
course and it awards no certificate. It is not affiliated with, endorsed by or
connected to any training organisation, sailing association, awarding body or
engine manufacturer. Any third-party names belong to their respective owners and
are used only to describe subject matter.

The content is general guidance. Always follow your engine manufacturer's
handbook and the advice of a qualified marine engineer.

## Privacy

- No account, no sign-in.
- No ads, analytics, crash reporting, tracking or network calls of any kind.
- Progress is stored on the device only, using SwiftData and `UserDefaults`.
- Deleting the app removes all of its data.

The app ships a `PrivacyInfo.xcprivacy` declaring no data collected and no tracking.

## Building

Requirements: Xcode 16 or later, iOS 17 SDK or later. No third-party dependencies.

```bash
open DieselReady.xcodeproj          # then pick a simulator and Run
```

From the command line:

```bash
xcodebuild -project DieselReady.xcodeproj -scheme DieselReady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build test
```

**Signing for a device.** Copy `Config/Local.xcconfig.example` to
`Config/Local.xcconfig` and enter your Apple Developer Team ID. That file is
git-ignored, so your Team ID stays out of the repository.

**Debug launch argument.** In Debug builds, `-openLesson <lessonID>` (for
example `-openLesson m01-l02`) opens that lesson at launch, which helps with
screenshots and manual testing. It is compiled out of Release builds.

**Project file.** `DieselReady.xcodeproj` is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen). If you add, move or remove
files, run `xcodegen generate` and commit both `project.yml` and the regenerated
project.

## Project layout

```
DieselReady/
  App/               App entry, root view, app facts and legal text
  DesignSystem/      Colour, type and spacing tokens; shared components
  Content/           Codable content models, loader/validator, ContentStore
  Persistence/       SwiftData models for progress, quiz attempts, bookmarks
  Features/          Disclaimer, Learn, Quiz, Faults, About
  Resources/
    Content/         Bundled JSON content (CC BY-NC-SA 4.0)
    PrivacyInfo.xcprivacy
DieselReadyTests/    Unit tests (Swift Testing)
DieselReadyUITests/  UI test that runs a mock test end to end
docs/                Content schema and, later, store metadata and web pages
```

Content is plain, platform-neutral JSON so the planned Android version can read
the same files unchanged. See [docs/content-schema.md](docs/content-schema.md).

## Contributing

Corrections to the content are welcome through GitHub Issues and pull requests.
All content must be original: please do not copy or paraphrase course books,
handbooks or manufacturer manuals.

## Licences

- Source code: [MIT](LICENSE)
- Content in `DieselReady/Resources/Content/`:
  [CC BY-NC-SA 4.0](CONTENT-LICENSE). You may share and adapt it with credit,
  for non-commercial purposes, under the same licence.

© 2026 Meltemi Apps

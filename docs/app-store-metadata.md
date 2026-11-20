# App Store metadata: Diesel Ready

Everything to enter in App Store Connect for version 1.0. Each text field is in
its own code block so it can be copied exactly. Check the limits and the
organisation-name rule before submitting:

```sh
python3 scripts/check-app-store-metadata.py
```

## Name

Limit 30 characters.

```text
Diesel Ready: Marine Diesel
```

## Subtitle

Limit 30 characters.

```text
Unofficial engine revision aid
```

## Promotional text

Limit 170 characters. Can be changed at any time without a new version.

```text
Learn how your boat's diesel engine works, how to look after it and what to check when it goes wrong. Free, offline, no account and no tracking.
```

## Keywords

Limit 100 characters including commas. Generic terms only. Words already in the
name and subtitle are indexed anyway, so they are not repeated here.

```text
boat engine,inboard,outboard,fuel bleeding,impeller,sailing,yacht,maintenance,quiz,study,mechanic
```

## Description

Limit 4,000 characters.

```text
Diesel Ready is a free, independent study guide for leisure boaters who want to understand and look after a small marine diesel engine.

Work through short, plain-English lessons, test yourself with quizzes, tick off your engine checks before and after starting, and use the Fault finder when something is not right. Everything works offline, so it is there when you need it, in harbour or at sea.

LEARN
• 8 modules and 35 short lessons, from how a diesel works to finding faults
• Fuel systems, filters, water in fuel and bleeding out air
• Cooling: seacocks, strainers, impellers, heat exchangers and thermostats
• Lubrication, oil checks and what the oil pressure warning means
• Batteries, charging, starter motors and glow plugs
• Drive belts, gearbox, stern gland, shaft and propeller
• Daily checks, servicing, winter lay-up and spares to carry
• Simple diagrams of the four-stroke cycle, the fuel path and the cooling circuits

TEST YOURSELF
• Check your knowledge at the end of each lesson
• Quizzes for each module, a 10-question quick quiz and a 30-question mock test
• Instant feedback with an explanation for every answer
• Review the questions you missed and retry them
• Over 150 original questions

CHECKLISTS
• Pre-start checks with the engine off, built on the widely used WOBBLE memory aid: water, oil, belts, bilges, leaks and levels
• Post-start checks with the engine running: water from the exhaust, warning lights, temperature, noise and smoke, observing only
• Tick items off as you go and reset for next time; ticks are never saved or sent anywhere
• Every check links to the lesson that explains it

FAULT FINDER
Stop cards come first, with what to do at once for low oil pressure, overheating, water coming in, suspected water in the engine, fuel spray, smoke or fire, and a leaking shaft seal. Then pick a symptom (exhaust smoke, won't start, overheating, stops suddenly, low oil pressure or not charging) to see the possible causes, what to check first, and links to the lessons that explain more.

PRIVATE BY DESIGN
• No account, no sign-in
• No adverts, analytics or tracking
• Your progress stays on your device; deleting the app removes it
• Works fully offline

UNOFFICIAL AND INDEPENDENT
Diesel Ready is an independent revision aid. It is not an official course and does not award any certificate. It is not affiliated with, endorsed by or connected to any training organisation, sailing association or engine manufacturer. The content is general guidance for typical small marine diesels: always follow your engine manufacturer's handbook, and ask a qualified marine engineer if you are unsure.

OPEN SOURCE
The app's code and content are open source. The lessons and questions are original, written for the app, and shared under a Creative Commons licence so others can learn from them.

Made by Meltemi Apps, an independent app studio.
```

## What's New (version 1.0)

```text
First release.
```

## URLs

| Field | Value |
|---|---|
| Support URL | https://meltemiapps.co.uk/diesel-ready/support/ |
| Marketing URL | https://meltemiapps.co.uk/diesel-ready/ |
| Privacy Policy URL | https://meltemiapps.co.uk/diesel-ready/privacy/ |

## General information

| Field | Value |
|---|---|
| Bundle ID | `uk.co.meltemiapps.dieselready` |
| SKU | `dieselready-ios` (suggested; any unique string) |
| Primary language | English (U.K.) |
| Primary category | Education |
| Secondary category | Reference |
| Copyright | © 2026 Meltemi Apps |
| Version | 1.0 (build 3) |
| Content rights | Does not contain, show or access third-party content |

## Pricing and Availability

| Field | Value |
|---|---|
| Price | Free (no in-app purchases) |
| Availability | All countries and regions **except China mainland** |

In App Store Connect: Pricing and Availability → Availability → select all
countries or regions, then deselect **China mainland**. (Apps in China mainland
also need a government licence, which this app does not have.)

## Age rating

Expected result: **4+**. Answers to the age rating questionnaire:

| Question | Answer |
|---|---|
| Parental controls | No |
| Age assurance | No |
| Unrestricted web access | No |
| User-generated content | No |
| Messaging and chat | No |
| Advertising | No |
| Cartoon or fantasy violence | None |
| Realistic violence | None |
| Prolonged graphic or sadistic realistic violence | None |
| Profanity or crude humour | None |
| Mature or suggestive themes | None |
| Horror or fear themes | None |
| Medical or treatment information | None |
| Alcohol, tobacco or drug use or references | None |
| Simulated gambling | None |
| Sexual content or nudity | None |
| Graphic sexual content and nudity | None |
| Contests | None |
| Gambling | No |
| Loot boxes | No |
| Health or wellness topics | No |

The app opens web links (website, GitHub, licences, email) in the system
browser or mail app only; it has no built-in web browser.

## App Privacy

| Field | Answer |
|---|---|
| Do you or your third-party partners collect data from this app? | **No** |
| Result shown on the App Store | **Data Not Collected** |
| Tracking | None; no App Tracking Transparency prompt |
| Privacy manifest | `DieselReady/Resources/PrivacyInfo.xcprivacy`: no data collected, no tracking, UserDefaults reason CA92.1 |

## Export compliance

`ITSAppUsesNonExemptEncryption` is set to `NO` in the Info.plist (the app makes
no network connections and uses no encryption), so no export compliance
documents are needed.

## App Review information

| Field | Value |
|---|---|
| Sign-in required | No |
| Contact email | support@meltemiapps.co.uk |
| Notes | See below |

```text
Diesel Ready is an offline study guide. It has no account, no network access and no in-app purchases. On first launch, tick the checkbox on the disclaimer screen and tap "Agree and continue". The app is unofficial and not affiliated with any organisation; this is stated on the first-launch screen and in the About tab.
```

## Screenshots

6.9-inch iPhone screenshots (1320 × 2868) are generated into
`docs/screenshots/app-store/` by `scripts/capture-screenshots.sh store`. The
screenshots are not committed (the folder is git-ignored); run the script to
recreate them. Upload them in this order:

1. `1-learn.png`: Learn tab with progress
2. `2-lesson-diagram.png`: a lesson with a diagram
3. `3-quiz-feedback.png`: a quiz question with feedback
4. `4-fault-finder.png`: the Fault finder
5. `5-about.png`: About and privacy
6. `6-checks.png`: the pre-start checklist

App Store Connect scales these down for smaller iPhones. A 6.3-inch set
(1206 × 2622) of the same six screens is in `docs/screenshots/app-store-6.3/`
(`scripts/capture-screenshots.sh store63`) for anyone who prefers to upload
that size as well.

The app also runs on iPad (`TARGETED_DEVICE_FAMILY` 1,2), so App Store Connect
requires iPad screenshots too. 13-inch iPad screenshots (2064 × 2752) of the
same six screens are in `docs/screenshots/app-store-ipad/`
(`scripts/capture-screenshots.sh ipad`).

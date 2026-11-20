# Review ledger: content 1.1

This ledger records how each finding of the independent technical content audit
of 20 November 2026 was handled. Findings are referred to by the audit's own
IDs: **S01–S20** (priority defects) and **notes 1–32** (the author's review
notes, numbered as in the review pack's "All review notes" list). The audit
itself is not part of this repository.

Every item below has the status **revised, awaiting engineer approval**. Nothing
is approved until a qualified marine engineer signs it off; all lessons,
questions and Fault finder entries remain `reviewStatus: "draft"`.

File paths are relative to `DieselReady/Resources/Content/`. Item IDs are lesson
(`m03-l02`), question (`m05-q006`), symptom (`wont-start`), stop card or notice
IDs. Section 6 replacement wording A–D is held once, verbatim, in `safety.json`
as notices `wet-exhaust-waterlock` (A), `high-pressure-fuel` (B),
`oil-pressure-stop` (C) and `overheating-stop` (D), and every surface refers to
it by ID, so the wording cannot drift. Wording E is in `m03-l02` step 6. A unit
test (`SafetyContentTests`) fails if any of the five changes.

## Priority findings S01–S20

| ID | Severity | Disposition | Change made (file: items) | Status |
|---|---|---|---|---|
| S01 | P0 | Applied: wording A verbatim | `safety.json`: notice `wet-exhaust-waterlock`. `modules/08-fault-finding.json`: `m08-l02` (notice before the steps; seacock-closing advice removed from step 5; step 6 "do not crank again", engineer only), `m08-q009`, `m08-q010` (notice in feedback), new `m08-q022` (old advice as a wrong answer). `modules/05-electrics-and-starting.json`: `m05-l03` (notice before the steps). `modules/02-fuel-system-and-bleeding.json`: `m02-l04` (notice for prolonged cranking). `faults.json`: `wont-start` (notice first, stop card `suspected-waterlock`, cranking check rewritten). | revised, awaiting engineer approval |
| S02 | P0 | Applied: wording B verbatim | `safety.json`: notice `high-pressure-fuel`. `modules/02-fuel-system-and-bleeding.json`: `m02-l04` (notice before the steps; low-pressure-only steps; injector-pipe loosening removed; new engineer-only step 7), `m02-l03` (caution no longer implies pipes may be loosened when stopped; common-rail boundary), `m02-l01` step 3, `m02-q014` and new `m02-q023` (notice in feedback), new `m02-q022` (fuel spray). `faults.json`: stop card `fuel-spray`. | revised, awaiting engineer approval |
| S03 | P0 | Applied: wording C verbatim | `safety.json`: notice `oil-pressure-stop`. `modules/04-lubrication.json`: `m04-l04` (notice before the steps; now a procedure with action levels; step 3 "do not restart to test"; causes unranked), `m04-q016`, `m04-q018` (rewritten from "most common cause"), new `m04-q021` (notice in feedback). `modules/08-fault-finding.json`: `m08-l04` (notice before the steps), `m08-q016`. `faults.json`: `low-oil-pressure` (notice first, stop card, first check "do not restart", causes unranked, normal level does not prove pressure). | revised, awaiting engineer approval |
| S04 | P0 | Applied: wording D verbatim | `safety.json`: notice `overheating-stop`. `modules/03-cooling-systems.json`: `m03-l05` (notice before the steps, replacing the closing caution), `m03-l02` step 2 ("one possible cause", not "most common"), `m03-q020` and new `m03-q022` (notice in feedback). `modules/08-fault-finding.json`: `m08-l04` (notice; step 2 checks only after cooling; "most overheating starts on the raw water side" removed), `m08-q016`, `m08-q017`, `m08-q020`. `faults.json`: `overheating` (notice first, stop card, strainer no longer "the most common cause", checks only after cooling). | revised, awaiting engineer approval |
| S05 | P1 | Applied | `modules/03-cooling-systems.json`: `m03-l01` steps 2, 4 and 5 ("in common raw-water and heat-exchanger installations"; keel cooling and dry exhaust explained separately); tags `direct-cooling`, `heat-exchanger`, `keel-cooling`. | revised, awaiting engineer approval |
| S06 | P1 | Applied: wording E verbatim | `modules/03-cooling-systems.json`: `m03-l02` step 6 (wording E replaces "ideally two stainless clips"), new `m03-q021`. | revised, awaiting engineer approval |
| S07 | P1 | Applied | `modules/03-cooling-systems.json`: `m03-l03` step 4 (maker's direction and lubricant; not every impeller is handed), new step 5 (inspect cover, cam, wear plate and missing vanes), intro. | revised, awaiting engineer approval |
| S08 | P1 | Applied | `modules/03-cooling-systems.json`: `m03-l04` step 3 ("The circuits are normally separate; internal leakage or failure can allow mixing."), `m03-q001` explanation ("in normal operation"). | revised, awaiting engineer approval |
| S09 | P1 | Applied | `modules/05-electrics-and-starting.json`: `m05-l02` step 4 ("indicates a charging-system fault or failure to excite; verify with the handbook and voltage checks"), `m05-q006` (key and distractors). `modules/08-fault-finding.json`: `m08-l04` step 4, `m08-q019`. `faults.json`: `not-charging` summary. | revised, awaiting engineer approval |
| S10 | P1 | Applied | `modules/05-electrics-and-starting.json`: `m05-l05` step 3 (conventional negative-earth lead-acid systems; vessel isolation procedure; starter and house banks; lithium battery management systems), tags `lead-acid`, `lithium`; `m05-q018`. | revised, awaiting engineer approval |
| S11 | P1 | Applied | `modules/06-drive-belts-and-stern-gear.json`: `m06-l03` steps 1–4 (product-specific drip and venting; new or increasing leakage urgent with bilge pumping check; never adjust around a rotating shaft), tags `packed-gland`, `shaft-seal`; `m06-q012`, `m06-q014`, new `m06-q021`. `faults.json`: stop cards `shaft-seal-leak`, `water-ingress`. | revised, awaiting engineer approval |
| S12 | P1 | Applied | `modules/08-fault-finding.json`: `m08-q012` (now a safe-inspection response, not a single cause), `m08-l03` step 2 (one important possibility; idle speed, gearbox and shaft binding; inspect only with the engine stopped and unable to start). `faults.json`: `stops-suddenly` (cause detail and check 2). | revised, awaiting engineer approval |
| S13 | P1 | Applied | `modules/08-fault-finding.json`: `m08-q006` ("a sensible first check"; stop control, fuel, pre-heat, electronic inhibit, air intake, compression), `m08-l02` intro and step 3. `modules/05-electrics-and-starting.json`: `m05-l03` step 3. `faults.json`: `wont-start` (engine inhibit, blocked intake and low compression causes; check 4). | revised, awaiting engineer approval |
| S14 | P1 | Applied | `modules/01-how-a-diesel-engine-works.json`: `m01-l01` step 5, `m01-l02` step 5, `m01-l03` step 5 and diagram caption ("typical mechanically injected diesel"), `m01-l04` step 4. `modules/02-fuel-system-and-bleeding.json`: `m02-l01` step 3 and caption, `m02-l02` step 5, `m02-l03` new step 4 (common-rail overview, ECU and sensors, no owner work on the high-pressure side). Tags `mechanical-injection`, `common-rail`. | revised, awaiting engineer approval |
| S15 | P1 | Applied in part | `modules/07-routine-maintenance.json`: `m07-l01` step 1 (water ingress), new step 6 (air intake, engine space ventilation, exhaust condition, propeller clear where safe and practicable), diagram labels and description, new `m07-q021`. Not applied: aligning with a named organisation's published pre-start guidance, which the project brief does not allow. | revised, awaiting engineer approval |
| S16 | P1 | Applied | Schema version 2 (`docs/content-schema.md`). Warnings render before the steps in every lesson (`caution` and `safetyNoticeIds`); every step of a hands-on lesson has an action level (`observe`, `owner`, `engineer`) shown as a badge; applicability tags shown as "Applies to"; seven Fault finder stop cards shown before the symptoms. `ContentLoader.validate` fails on a missing action level, a hazardous procedure with no warning before its steps, a warning inside the steps, a missing stop card, an unknown notice, tag or card, or a frequency ranking. | revised, awaiting engineer approval |
| S17 | P2 | Applied | `modules/01-how-a-diesel-engine-works.json`: `m01-l01` step 2 (typical range, not a specification), `m01-q004` (now tests what the ratio means). | revised, awaiting engineer approval |
| S18 | P2 | Applied | `modules/02-fuel-system-and-bleeding.json`: `m02-l05` step 4. `modules/07-routine-maintenance.json`: `m07-l03` step 3. Clean, dry fuel, water management, avoiding stale fuel and maker's guidance; no universal full-tank advice. | revised, awaiting engineer approval |
| S19 | P2 | Applied | `modules/07-routine-maintenance.json`: `m07-q010` ("where one is fitted"; log otherwise), `m07-l02` step 1. | revised, awaiting engineer approval |
| S20 | P2 | Applied | Distractors replaced with credible competing answers in 72 of the original 161 questions across all modules, and 86 of them changed in some way (see `docs/quiz-review.csv`). Ten new scenario and safety-first ordering questions: `m02-q022`, `m02-q023`, `m03-q021`, `m03-q022`, `m04-q021`, `m05-q021`, `m06-q021`, `m07-q021`, `m08-q021`, `m08-q022`. Every question and explanation containing always, never, only, most common, must or means was audited; overclaims were reworded and absolute wrong answers that gave the key away were replaced. The 33 questions with an unsafe action among their wrong answers are tagged `unsafe-distractor`, and each explanation now says why that action is dangerous. Questions are also tagged `safety-critical` (38) and `scenario` (51) so every mock test includes at least 6 of each. | revised, awaiting engineer approval |

## Author review notes 1–32

| Note | Item | Disposition | Change made (file: items) | Status |
|---:|---|---|---|---|
| 1 | Compression ratio, lesson 1.1 | Accept with qualification | `modules/01-how-a-diesel-engine-works.json`: `m01-l01` step 2 (typical range for many conventional small diesels, not a specification). | revised, awaiting engineer approval |
| 2 | `m01-q004` | Revise | `modules/01-how-a-diesel-engine-works.json`: `m01-q004` rewritten to test the meaning of the ratio. | revised, awaiting engineer approval |
| 3 | `m01-q019` | Accept with qualification | `modules/01-how-a-diesel-engine-works.json`: `m01-q019` prompt and explanation (common, not on every layout). | revised, awaiting engineer approval |
| 4 | Lesson 2.1 fuel path | Revise | `modules/02-fuel-system-and-bleeding.json`: `m02-l01` step 2 (one example configuration; order varies), diagram caption. | revised, awaiting engineer approval |
| 5 | `m02-q010` engine stop | Revise | `modules/02-fuel-system-and-bleeding.json`: `m02-q010` ("many mechanically injected"), `m02-l03` step 6. | revised, awaiting engineer approval |
| 6 | Lesson 2.4 bleeding | Safety revise (P0) | `modules/02-fuel-system-and-bleeding.json`: `m02-l04` (wording B before the steps; low-pressure, handbook-approved steps only; common rail distinguished). See S02. | revised, awaiting engineer approval |
| 7 | `m02-q016` dead lift-pump lever | Accept with qualification | `modules/02-fuel-system-and-bleeding.json`: `m02-q016` (cam-operated pumps; electric pumps differ), `m02-l04` step 5. | revised, awaiting engineer approval |
| 8 | Lesson 2.5 fuel care | Revise | `modules/02-fuel-system-and-bleeding.json`: `m02-l05` step 4. See S18. | revised, awaiting engineer approval |
| 9 | Lesson 3.1 direct, indirect and keel cooling | Revise | `modules/03-cooling-systems.json`: `m03-l01` steps 2, 4 and 5. See S05. | revised, awaiting engineer approval |
| 10 | `m03-q004` | Verify | `modules/03-cooling-systems.json`: `m03-q004` ("designed to"; credible distractor). Wording to be verified by the engineer against direct and indirect installations. | revised, awaiting engineer approval (verification required) |
| 11 | Lesson 3.2 anti-siphon and clips | Revise | `modules/03-cooling-systems.json`: `m03-l02` step 5 (anti-siphon per installation design), step 6 (wording E). | revised, awaiting engineer approval |
| 12 | Lesson 3.3 impeller | Revise | `modules/03-cooling-systems.json`: `m03-l03` steps 4 and 5. See S07. | revised, awaiting engineer approval |
| 13 | `m03-q012` winter impeller removal | Accept with qualification | `modules/03-cooling-systems.json`: `m03-q012` explanation (optional and engine-specific); absolute distractor replaced. `modules/07-routine-maintenance.json`: `m07-l03` step 4. | revised, awaiting engineer approval |
| 14 | Lesson 3.4 heat exchanger | Revise | `modules/03-cooling-systems.json`: `m03-l04` steps 1–3 (thermostat position varies; circuits normally separate). See S08. | revised, awaiting engineer approval |
| 15 | Lesson 4.3 oil change | Accept with qualification | `modules/04-lubrication.json`: `m04-l03` step 5 (immediate oil-pressure confirmation, leak check, stop and recheck after settling); disposal in step 6. | revised, awaiting engineer approval |
| 16 | Lesson 4.4 oil warnings | Accept with qualification | `modules/04-lubrication.json`: `m04-l04` step 2 (typical behaviour; panels differ). | revised, awaiting engineer approval |
| 17 | `m04-q020` | Verify | `modules/04-lubrication.json`: `m04-q020` (general tendency; no universal figure; absolute distractor replaced). Engineer to verify. | revised, awaiting engineer approval (verification required) |
| 18 | Lesson 5.1 batteries | Revise | `modules/05-electrics-and-starting.json`: `m05-l01` caution (hydrogen and acid for lead-acid; lithium hazards differ), tags. | revised, awaiting engineer approval |
| 19 | `m05-q004` | Revise | `modules/05-electrics-and-starting.json`: `m05-q004` (limited to lead-acid batteries). | revised, awaiting engineer approval |
| 20 | Lesson 5.2 isolator | Accept with qualification | `modules/05-electrics-and-starting.json`: `m05-l02` step 5 ("specifically designed and approved"). | revised, awaiting engineer approval |
| 21 | Lesson 5.4 glow plugs | Accept with qualification | `modules/05-electrics-and-starting.json`: `m05-l04` step 4 (symptoms are clues, not exclusive). | revised, awaiting engineer approval |
| 22 | Lesson 6.1 drive belts | Accept with qualification | `modules/06-drive-belts-and-stern-gear.json`: `m06-l01` step 5 (tension, re-tensioning and belt type follow the maker). | revised, awaiting engineer approval |
| 23 | Lesson 6.2 gearbox | Accept with qualification | `modules/06-drive-belts-and-stern-gear.json`: `m06-l02` step 3 (neutral pause where the gearbox handbook supports it), `m06-q007` explanation. | revised, awaiting engineer approval |
| 24 | `m06-q009` | Revise | `modules/06-drive-belts-and-stern-gear.json`: `m06-q009` (steady drive with a warm engine; normal slight cold drag distinguished), `m06-l02` step 4. | revised, awaiting engineer approval |
| 25 | Lesson 6.3 stern gland | Revise | `modules/06-drive-belts-and-stern-gear.json`: `m06-l03` steps 1–4. See S11. | revised, awaiting engineer approval |
| 26 | `m06-q012` | Accept with qualification | `modules/06-drive-belts-and-stern-gear.json`: `m06-q012` (may be normal for some packed glands; drip rates product-specific). | revised, awaiting engineer approval |
| 27 | Lesson 6.4 shaft and cutless bearing | Accept with qualification | `modules/06-drive-belts-and-stern-gear.json`: `m06-l04` step 3 (one clue; bearing maker's tolerances), `m06-q018`. | revised, awaiting engineer approval |
| 28 | `m07-q010` | Revise | `modules/07-routine-maintenance.json`: `m07-q010`. See S19. | revised, awaiting engineer approval |
| 29 | Lesson 7.3 winterising | Revise | `modules/07-routine-maintenance.json`: `m07-l03` steps 2–4 (raw water protection, antifreeze type and draining method follow the maker; tank level and impeller removal not universal). | revised, awaiting engineer approval |
| 30 | Lesson 8.2 wet-exhaust cranking | Safety revise (P0) | `modules/08-fault-finding.json`: `m08-l02` (wording A before the steps; no closed-seacock cranking advice). See S01. | revised, awaiting engineer approval |
| 31 | Fault finder "Won't start" | Safety revise (P0) | `faults.json`: `wont-start` (wording A first; stop card `suspected-waterlock`; consistent with `m08-l02`). See S01. | revised, awaiting engineer approval |
| 32 | Fault finder "Low oil pressure" | Safety revise (P0) | `faults.json`: `low-oil-pressure` (wording C first; stop card; no "most common cause"; causes unranked). See S03. | revised, awaiting engineer approval |

## Not done in this revision

- The audit's suggestion to display a statement naming the training body is not applied: the project brief does not allow any organisation to be named. The app keeps the generic statement that it is not affiliated with any training organisation.
- Technical approver name and credentials: shown as "Engineer approval: pending" on the About tab until an engineer approves the content.
- Section 8 (air and exhaust, spares and tools, failure underway) and the module 7 winterisation decision tree are deferred to Phase 5c.
- Checks that need people or engines rather than editing: a second reviewer answering the bank blind (the CSV shuffles options per question so the key column can be hidden), a novice UX test, empirical validation of difficulty labels, and checking diagrams against several engine families.

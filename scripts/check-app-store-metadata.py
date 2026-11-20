#!/usr/bin/env python3
"""Check docs/app-store-metadata.md against App Store limits and the naming rule.

    python3 scripts/check-app-store-metadata.py

Fails (exit 1) if:
  - the name or subtitle is over 30 characters, the promotional text over 170,
    the keywords over 100 (including commas) or the description over 4,000;
  - any required field or fact is missing;
  - any training organisation, sailing association, awarding body or engine
    manufacturer is named in the metadata or in the website pages.

The project rules forbid writing those names anywhere in the repository, so the
list is stored only as SHA-256 fingerprints of the lower-case name. Every word
and run of up to four words in the text is hashed and compared against it.
Standard library only.
"""

import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "docs" / "app-store-metadata.md"
SITE = ROOT / "docs" / "site" / "diesel-ready"

LIMITS = {
    "Name": 30,
    "Subtitle": 30,
    "Promotional text": 170,
    "Keywords": 100,
    "Description": 4000,
}

REQUIRED_TEXT = [
    "© 2026 Meltemi Apps",
    "except China mainland",
    "Free",
    "4+",
    "Data Not Collected",
    "https://meltemiapps.co.uk/diesel-ready/privacy/",
    "https://meltemiapps.co.uk/diesel-ready/support/",
]

# SHA-256 (first 20 hex digits) of each banned name or phrase, lower case.
BANNED = {
    "b5dcec23df8d9d669955",
    "117f97f1d0f00547be0a",
    "6e301a61c2b6ce479f86",
    "f8050a72a0008cfc3285",
    "b323ba8eb5a4df2f162b",
    "c852075f28c8fb506d77",
    "a155a1d15487fb371420",
    "2395c2189c09a3406a39",
    "23027bb269d2d6bc276c",
    "439f128ea83241621f0d",
    "0bee61011c1c6653611e",
    "d519494a85986760d37d",
    "be58e37dff7ee5955290",
    "0c3bfb258fed28e65061",
    "057b1e48a104e6403d55",
    "a3235f83e502433f354b",
    "0705e1308e77759852e0",
    "c34b610f50a5a73f29d8",
    "33ea2c50606fb8ac9b18",
    "22166f2fc29db3438416",
    "e08e0ec39445d3a0330d",
    "9aade1329c09430e5c53",
    "0de1cfe2cadeaf6b5ca3",
    "46518ae85f82bbcd98c4",
    "1d15cfcbb2ab56bddffc",
    "c148064fdab910026757",
    "319fe251a120d9456d34",
    "f9ddee9693a178651130",
    "bf3456206b89edee4898",
    "e7eceae55aeba313c03e",
    "bccae4ce7be65100a847",
    "7989e4a0d8282735301c",
    "558c92be02f9f70ab986",
    "6c799e0b6ed0a4d94401",
    "27b4f7a1a03637b0d716",
    "014e3f1f20764cc5dac7",
    "aa7d397c4ccf6faa6372",
    "b769a6983b42d565e79b",
    "d501a5214317082b315e",
    "49762afb5c3e8e4b6762",
    "baffdf37aa5d3961c77b",
    "e58c9634bf3a383fc169",
    "f36e9f2d32d713d8c07d",
    "587bf9b32f9a6634cadd",
    "782b9a67691cfdc3c3b5",
    "8e14a14b5b5452c2dbc1",
    "860f32f55146cf758828",
    "9ed6de0933b16c50776e",
    "af9d7f5c94154c517666",
    "4d13e1dbe7ab3f90f7cf",
    "09b7b4bebb61f3282b34",
    "63a964b33db7c643a1d4",
    "d222a18d6474d0819d8e",
    "8417659f46b5b43b2bb9",
    "a237bef830f24d0dbf65",
    "b3190fd933e4acd88e3f",
    "066d577ea443f2ccda01",
    "68a209dc212f3d931be0",
}


def fingerprint(text):
    return hashlib.sha256(text.encode()).hexdigest()[:20]


def banned_hits(text):
    words = re.findall(r"[a-z0-9]+", text.lower())
    hits = set()
    for size in range(1, 5):
        for i in range(len(words) - size + 1):
            phrase = " ".join(words[i:i + size])
            if fingerprint(phrase) in BANNED:
                hits.add(phrase)
    return hits


def fields(markdown):
    """The first fenced block after each '## Heading'."""
    found = {}
    for match in re.finditer(r"^## (.+?)\n(.*?)(?=^## |\Z)", markdown, re.S | re.M):
        block = re.search(r"```text\n(.*?)\n```", match.group(2), re.S)
        if block:
            found[match.group(1).strip()] = block.group(1)
    return found


def main():
    text = METADATA.read_text(encoding="utf-8")
    values = fields(text)
    problems = []

    for name, limit in LIMITS.items():
        value = values.get(name)
        if value is None:
            problems.append(f"{name}: missing")
            continue
        length = len(value)
        status = "ok" if length <= limit else "TOO LONG"
        print(f"{name:<17} {length:>5} / {limit:<5} {status}")
        if length > limit:
            problems.append(f"{name}: {length} characters, limit {limit}")

    keywords = values.get("Keywords", "")
    if ", " in keywords:
        problems.append("Keywords: remove spaces after commas (they count towards the limit)")
    terms = [k.strip().lower() for k in keywords.split(",")]
    if len(terms) != len(set(terms)):
        problems.append("Keywords: duplicate terms")

    for fact in REQUIRED_TEXT:
        if fact not in text:
            problems.append(f"Missing required information: {fact!r}")

    sources = {"docs/app-store-metadata.md": text}
    for page in sorted(SITE.rglob("*.html")):
        sources[str(page.relative_to(ROOT))] = re.sub(r"<[^>]+>", " ", page.read_text(encoding="utf-8"))
    for source, body in sources.items():
        for hit in sorted(banned_hits(body)):
            problems.append(f"{source}: names an organisation or manufacturer ({hit!r})")

    if problems:
        print("\nFAILED:")
        for problem in problems:
            print(f"  - {problem}")
        sys.exit(1)
    print(f"\nAll checks passed ({len(sources)} files scanned for organisation names).")


if __name__ == "__main__":
    main()

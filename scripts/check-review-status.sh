#!/bin/sh
# Fails if any bundled content is not engineer-approved: a lesson, question,
# checklist, checklist item or Fault finder entry still marked
# "reviewStatus": "draft", or manifest contentInfo not reviewed and approved.
#
# Run by the DieselReady target before every Release build (so archives fail
# on draft content), and by hand:  scripts/check-review-status.sh [content-dir]
set -u
dir="${1:-$(dirname "$0")/../DieselReady/Resources/Content}"
manifest="$dir/manifest.json"
status=0

if [ ! -r "$manifest" ]; then
    echo "error: cannot read $manifest"
    exit 1
fi

files="$manifest $dir/faults.json $dir/checklists.json"
for f in "$dir"/modules/*.json; do files="$files $f"; done

for f in $files; do
    if [ ! -r "$f" ]; then
        echo "error: cannot read $f"
        status=1
        continue
    fi
    drafts=$(grep -c '"reviewStatus": *"draft"' "$f")
    if [ "$drafts" -gt 0 ]; then
        echo "error: $(basename "$f"): $drafts item(s) still have \"reviewStatus\": \"draft\"; release content must be reviewed"
        status=1
    fi
done

if ! grep -q '"status": *"reviewed"' "$manifest"; then
    echo "error: manifest.json: contentInfo status is not \"reviewed\""
    status=1
fi
if ! grep -q '"engineerApproval": *"approved"' "$manifest"; then
    echo "error: manifest.json: contentInfo engineerApproval is not \"approved\""
    status=1
fi

if [ "$status" -eq 0 ]; then echo "Content review status: every item reviewed and approved."; fi
exit "$status"

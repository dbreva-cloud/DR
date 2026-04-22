#!/usr/bin/env bash
set -euo pipefail

# ── PATH bootstrap ────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ETSY_WORKSPACE:-$HOME/Desktop/etsy-art-factory/workspace}"

SLUG="${1:-}"
if [[ -z "$SLUG" ]]; then
  echo "Usage: $0 <product-slug>"
  echo "Example: $0 moody-desert-sun"
  exit 1
fi

# ── Sentinel checks ───────────────────────────────────────────────────────────
has_research()  { ls "$WORKSPACE/01_trend_research/"*-trend-report.md 2>/dev/null | head -1 | grep -q .; }
has_concept()   { [[ -f "$WORKSPACE/02_concept_briefs/$SLUG-concept.md" ]]; }
has_prompts()   { [[ -f "$WORKSPACE/03_midjourney_prompts/$SLUG-prompts.md" ]]; }
has_art()       { [[ -f "$WORKSPACE/04_generated_art/$SLUG.png" ]]; }
has_qc()        { [[ -f "$WORKSPACE/05_final_selected_art/$SLUG-qc-report.md" ]]; }
has_exports()   { [[ -f "$WORKSPACE/06_print_exports/$SLUG/export-manifest.json" ]]; }
has_listing()   { [[ -f "$WORKSPACE/08_listing_copy/$SLUG-listing.md" ]]; }
has_bundle()    { [[ -f "$WORKSPACE/09_upload_bundle/$SLUG/README.md" ]]; }

notify() {
  # macOS notification (silent fail if not supported)
  osascript -e "display notification \"$1\" with title \"Etsy Factory — $SLUG\"" 2>/dev/null || true
}

step() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

pause() {
  echo ""
  echo "⏸  MANUAL STEP REQUIRED"
  echo "   $1"
  echo ""
  echo "   Press ENTER when done, or Ctrl+C to stop here."
  read -r
}

# ── Pipeline ──────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "  Etsy Pipeline: $SLUG"
echo "╚══════════════════════════════════════╝"

# Stage 1 — Research
if has_research; then
  echo "✓ Stage 1: trend research already done"
else
  step "Stage 1: Trend Research"
  "$SCRIPT_DIR/run_stage.sh" research
fi

# Stage 2 — Concept
if has_concept; then
  echo "✓ Stage 2: concept brief already done"
else
  step "Stage 2: Concept Brief"
  "$SCRIPT_DIR/run_stage.sh" concept "$SLUG"
fi

# Stage 3 — Prompts
if has_prompts; then
  echo "✓ Stage 3: prompts already done"
else
  step "Stage 3: Midjourney Prompts"
  "$SCRIPT_DIR/run_stage.sh" prompts "$SLUG"
fi

# Stage 4 — Art (manual)
if has_art; then
  echo "✓ Stage 4: art file found"
else
  pause "Generate the image in Midjourney using the prompts in:
   $WORKSPACE/03_midjourney_prompts/$SLUG-prompts.md

   Save the result as: $SLUG.png
   Drop it into:       $WORKSPACE/04_generated_art/"

  if ! has_art; then
    echo "ERROR: $WORKSPACE/04_generated_art/$SLUG.png still not found."
    echo "  Add the file and re-run this script."
    exit 2
  fi
fi

# Stage 5 — QC
if has_qc; then
  echo "✓ Stage 5: QC report already done"
else
  step "Stage 5: QC Review"
  "$SCRIPT_DIR/run_stage.sh" qc "$SLUG"

  # Check if QC passed (look for PASS in the report)
  if grep -qi "BLOCKED\|FAIL" "$WORKSPACE/05_final_selected_art/$SLUG-qc-report.md" 2>/dev/null; then
    echo ""
    echo "✗ QC FAILED — fix the image and re-run this script."
    notify "QC failed — fix the image and re-run"
    exit 3
  fi
fi

# Stage 6 — Exports
if has_exports; then
  echo "✓ Stage 6: exports already done"
else
  step "Stage 6: Print Exports"
  "$SCRIPT_DIR/run_stage.sh" exports "$SLUG"
fi

# Stage 7 — Mockups (manual) — non-blocking
MOCKUPS_DIR="$WORKSPACE/07_mockups/$SLUG"
if [[ -d "$MOCKUPS_DIR" ]] && [[ -n "$(ls -A "$MOCKUPS_DIR" 2>/dev/null)" ]]; then
  echo "✓ Stage 7: mockups found"
else
  echo ""
  echo "⚠  Stage 7: No mockups yet."
  echo "   Add lifestyle/room images to: $MOCKUPS_DIR/"
  echo "   (Continuing — re-run bundle after adding mockups)"
fi

# Stage 8 — Listing
if has_listing; then
  echo "✓ Stage 8: listing copy already done"
else
  step "Stage 8: Listing Copy"
  "$SCRIPT_DIR/run_stage.sh" listing "$SLUG"
fi

# Stage 9 — Bundle (always re-run to pick up latest files)
step "Stage 9: Upload Bundle"
"$SCRIPT_DIR/run_stage.sh" bundle "$SLUG"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "  ✓ Pipeline complete: $SLUG"
echo "  Bundle: $WORKSPACE/09_upload_bundle/$SLUG/"
echo "╚══════════════════════════════════════╝"
notify "Pipeline complete — ready to upload"

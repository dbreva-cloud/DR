#!/usr/bin/env bash
set -euo pipefail

# ── PATH bootstrap ────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ETSY_WORKSPACE:-$HOME/Desktop/etsy-art-factory/workspace}"
ART_DIR="$WORKSPACE/04_generated_art"

# ── Check fswatch is installed ────────────────────────────────────────────────
if ! command -v fswatch &>/dev/null; then
  echo "ERROR: fswatch is not installed."
  echo "  Install it with: brew install fswatch"
  echo "  (If you don't have Homebrew: https://brew.sh)"
  exit 1
fi

notify() {
  osascript -e "display notification \"$1\" with title \"Etsy Factory\"" 2>/dev/null || true
}

handle_new_png() {
  local filepath="$1"
  local filename
  filename="$(basename "$filepath")"

  # Only handle .png files, ignore temp/hidden files
  [[ "$filename" == *.png ]] || return
  [[ "$filename" == .* ]] && return

  local slug="${filename%.png}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  New art detected: $filename"
  echo "  Slug: $slug"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  notify "New art detected: $slug — running QC..."

  # Wait briefly for the file to finish copying
  sleep 2

  # Verify file is a valid image (non-zero size)
  if [[ ! -s "$filepath" ]]; then
    echo "WARN: $filename is empty — skipping"
    notify "Warning: $slug — file was empty, skipped"
    return
  fi

  # Stage 5 — QC
  echo ">>> Running QC..."
  notify "$slug — Step 1/4: Running QC check..."
  "$SCRIPT_DIR/run_stage.sh" qc "$slug" || {
    echo "✗ QC stage failed for $slug"
    notify "ERROR: QC crashed for $slug — check Terminal"
    return
  }

  # Check QC result
  QC_REPORT="$WORKSPACE/05_final_selected_art/$slug-qc-report.md"
  if grep -qi "BLOCKED\|FAIL" "$QC_REPORT" 2>/dev/null; then
    echo "✗ QC FAILED for $slug — image resolution too low."
    echo "  Replace $filename with a higher-resolution version."
    echo "  Minimum: 3000px on the short side (ideally 4000px+)"
    notify "ACTION NEEDED: $slug — image too small. Replace with higher-res PNG."
    return
  fi
  echo "✓ QC passed"
  notify "$slug — QC passed ✓ Running exports..."

  # Stage 6 — Exports
  echo ">>> Running exports..."
  notify "$slug — Step 2/4: Resizing to all print formats..."
  "$SCRIPT_DIR/run_stage.sh" exports "$slug" || {
    echo "✗ Exports failed for $slug"
    notify "ERROR: Exports failed for $slug — check Terminal"
    return
  }
  echo "✓ Exports done"

  # Stage 8 — Listing
  echo ">>> Writing listing copy..."
  notify "$slug — Step 3/4: Writing Etsy listing copy..."
  "$SCRIPT_DIR/run_stage.sh" listing "$slug" || {
    echo "✗ Listing failed for $slug"
    notify "ERROR: Listing copy failed for $slug — check Terminal"
    return
  }
  echo "✓ Listing done"

  # Stage 9 — Bundle
  echo ">>> Packaging bundle..."
  notify "$slug — Step 4/4: Packaging upload bundle..."
  "$SCRIPT_DIR/run_stage.sh" bundle "$slug" || {
    echo "✗ Bundle failed for $slug"
    notify "ERROR: Bundle failed for $slug — check Terminal"
    return
  }
  echo "✓ Bundle done"

  echo ""
  echo "╔══════════════════════════════════════╗"
  echo "  ✓ Pipeline complete: $slug"
  echo "  $WORKSPACE/09_upload_bundle/$slug/"
  echo "╚══════════════════════════════════════╝"

  # Final notification with next action
  MOCKUPS_DIR="$WORKSPACE/07_mockups/$slug"
  if [[ -d "$MOCKUPS_DIR" ]] && [[ -n "$(ls -A "$MOCKUPS_DIR" 2>/dev/null)" ]]; then
    notify "DONE: $slug — bundle ready. Open 09_upload_bundle/$slug/ to upload to Etsy."
  else
    notify "DONE: $slug — bundle ready. ACTION: Add mockup photos to 07_mockups/$slug/ then re-run bundle."
  fi
}

# ── Start watching ────────────────────────────────────────────────────────────
echo "Watching for new art in:"
echo "  $ART_DIR"
echo ""
echo "Drop a PNG named <product-slug>.png into that folder."
echo "The pipeline (QC → exports → listing → bundle) will run automatically."
echo "You will receive Mac notifications at each step."
echo "Press Ctrl+C to stop."
echo ""
notify "Etsy Factory watcher started — drop a PNG into 04_generated_art/ to begin"

# fswatch -0 uses null bytes as delimiters (handles spaces in paths)
# --event Created fires only on new file creation, not modifications
fswatch -0 --event Created "$ART_DIR" | while IFS= read -r -d "" event; do
  handle_new_png "$event"
done

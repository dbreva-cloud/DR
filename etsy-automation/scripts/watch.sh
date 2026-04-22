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
  notify "New art detected: $slug — starting pipeline"

  # Wait briefly for the file to finish copying
  sleep 2

  # Verify file is a valid image (non-zero size)
  if [[ ! -s "$filepath" ]]; then
    echo "WARN: $filename is empty — skipping"
    return
  fi

  # Stage 5 — QC
  echo ">>> Running QC..."
  "$SCRIPT_DIR/run_stage.sh" qc "$slug" || {
    echo "✗ QC stage failed for $slug"
    notify "QC failed for $slug"
    return
  }

  # Check QC result
  QC_REPORT="$WORKSPACE/05_final_selected_art/$slug-qc-report.md"
  if grep -qi "BLOCKED\|FAIL" "$QC_REPORT" 2>/dev/null; then
    echo "✗ QC FAILED for $slug — image resolution too low."
    echo "  Replace $filename with a higher-resolution version."
    notify "QC failed — $slug needs higher-res image"
    return
  fi
  echo "✓ QC passed"

  # Stage 6 — Exports
  echo ">>> Running exports..."
  "$SCRIPT_DIR/run_stage.sh" exports "$slug" || {
    echo "✗ Exports failed for $slug"
    notify "Exports failed for $slug"
    return
  }
  echo "✓ Exports done"

  # Stage 8 — Listing
  echo ">>> Writing listing copy..."
  "$SCRIPT_DIR/run_stage.sh" listing "$slug" || {
    echo "✗ Listing failed for $slug"
    notify "Listing copy failed for $slug"
    return
  }
  echo "✓ Listing done"

  # Stage 9 — Bundle
  echo ">>> Packaging bundle..."
  "$SCRIPT_DIR/run_stage.sh" bundle "$slug" || {
    echo "✗ Bundle failed for $slug"
    notify "Bundle failed for $slug"
    return
  }
  echo "✓ Bundle done"

  echo ""
  echo "╔══════════════════════════════════════╗"
  echo "  ✓ Pipeline complete: $slug"
  echo "  $WORKSPACE/09_upload_bundle/$slug/"
  echo "╚══════════════════════════════════════╝"
  notify "Done: $slug — ready to upload to Etsy"
}

# ── Start watching ────────────────────────────────────────────────────────────
echo "Watching for new art in:"
echo "  $ART_DIR"
echo ""
echo "Drop a PNG named <product-slug>.png into that folder."
echo "The pipeline (QC → exports → listing → bundle) will run automatically."
echo "Press Ctrl+C to stop."
echo ""

# fswatch -0 uses null bytes as delimiters (handles spaces in paths)
# --event Created fires only on new file creation, not modifications
fswatch -0 --event Created "$ART_DIR" | while IFS= read -r -d "" event; do
  handle_new_png "$event"
done

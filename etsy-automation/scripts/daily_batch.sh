#!/usr/bin/env bash
set -euo pipefail

# ── PATH bootstrap ────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ETSY_WORKSPACE:-$HOME/Desktop/etsy-art-factory/workspace}"
TODAY=$(date +%Y-%m-%d)
IDEAS_DIR="$WORKSPACE/00_daily_ideas"
IDEAS_FILE="$IDEAS_DIR/$TODAY-ideas.txt"

notify() {
  osascript -e "display notification \"$1\" with title \"Etsy Factory\"" 2>/dev/null || true
}

echo ""
echo "╔══════════════════════════════════════╗"
echo "  Etsy Daily Batch — $TODAY"
echo "╚══════════════════════════════════════╝"
echo ""

mkdir -p "$IDEAS_DIR"

# ── Stage 1: Trend research (once per day) ────────────────────────────────────
RESEARCH_FILE="$WORKSPACE/01_trend_research/$TODAY-trend-report.md"
if [[ -f "$RESEARCH_FILE" ]]; then
  echo "✓ Today's trend research already done"
else
  echo ">>> Running trend research..."
  "$SCRIPT_DIR/run_stage.sh" research
fi

# ── Generate 3 ideas for today ────────────────────────────────────────────────
if [[ -f "$IDEAS_FILE" ]] && [[ -s "$IDEAS_FILE" ]]; then
  echo "✓ Today's ideas already generated"
else
  echo ">>> Generating 3 new product ideas..."
  "$SCRIPT_DIR/run_stage.sh" ideas
fi

# ── Verify ideas file exists and has content ──────────────────────────────────
if [[ ! -f "$IDEAS_FILE" ]] || [[ ! -s "$IDEAS_FILE" ]]; then
  echo ""
  echo "ERROR: Ideas file not created or empty: $IDEAS_FILE"
  echo "  Try running: ./scripts/run_stage.sh ideas"
  exit 1
fi

# ── Run concept + prompts for each slug ───────────────────────────────────────
echo ""
echo ">>> Processing today's products..."
echo ""

COUNT=0
while IFS= read -r SLUG; do
  # Skip empty lines and comments
  [[ -z "$SLUG" ]] && continue
  [[ "$SLUG" == \#* ]] && continue

  COUNT=$((COUNT + 1))
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  [$COUNT] $SLUG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  PROMPTS_FILE="$WORKSPACE/03_midjourney_prompts/$SLUG-prompts.md"
  CONCEPT_FILE="$WORKSPACE/02_concept_briefs/$SLUG-concept.md"

  if [[ -f "$PROMPTS_FILE" ]]; then
    echo "✓ Prompts already exist — skipping"
  else
    if [[ ! -f "$CONCEPT_FILE" ]]; then
      echo ">>> Writing concept brief..."
      "$SCRIPT_DIR/run_stage.sh" concept "$SLUG"
    else
      echo "✓ Concept brief already done"
    fi

    echo ">>> Writing Midjourney prompts..."
    "$SCRIPT_DIR/run_stage.sh" prompts "$SLUG"
    echo "✓ Prompts ready"
  fi

  echo "  → workspace/03_midjourney_prompts/$SLUG-prompts.md"
  echo ""
done < "$IDEAS_FILE"

# ── Done ──────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════╗"
echo "  ✓ Daily batch complete — $COUNT products"
echo ""
echo "  Open this folder to find your prompts:"
echo "  $WORKSPACE/03_midjourney_prompts/"
echo ""
echo "  For each product:"
echo "  1. Open the -prompts.md file"
echo "  2. Generate the image in Midjourney"
echo "  3. Save as <slug>.png and drop into:"
echo "     $WORKSPACE/04_generated_art/"
echo "  4. The pipeline runs automatically"
echo "╚══════════════════════════════════════╝"
notify "Daily batch done — $COUNT prompt files ready in 03_midjourney_prompts/"

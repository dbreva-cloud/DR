#!/usr/bin/env bash
set -euo pipefail

# ── PATH bootstrap — fixes macOS login-shell PATH gap ────────────────────────
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
CLAUDE="$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")"
PYTHON="$(command -v python3)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd "$SCRIPT_DIR/../.claude/agents" && pwd)"

# ── Workspace root (override with ETSY_WORKSPACE env var) ────────────────────
WORKSPACE="${ETSY_WORKSPACE:-$HOME/Desktop/etsy-art-factory/workspace}"

# ── Args ─────────────────────────────────────────────────────────────────────
STAGE="${1:-help}"
SLUG="${2:-}"

# ── Helper: run a Claude agent in non-interactive print mode ─────────────────
# Reads the agent .md file, strips YAML front matter, passes body as system prompt
run_agent() {
  local agent="$1"
  local prompt="$2"
  local agent_file="$AGENTS_DIR/$agent.md"

  if [[ ! -f "$agent_file" ]]; then
    echo "ERROR: Agent file not found: $agent_file"
    exit 1
  fi

  # Extract everything after the second --- (YAML front matter)
  local system_prompt
  system_prompt=$(awk 'BEGIN{n=0} /^---/{n++; next} n>=2{print}' "$agent_file")

  ETSY_WORKSPACE="$WORKSPACE" PRODUCT_SLUG="$SLUG" \
    "$CLAUDE" \
      --print \
      --system-prompt "$system_prompt" \
      --dangerously-skip-permissions \
      --add-dir "$WORKSPACE" \
      "$prompt"
}

# ── Stage dispatch ────────────────────────────────────────────────────────────
case "$STAGE" in

  research)
    echo ">>> Stage 1: Trend Research"
    run_agent "researcher" \
      "Run trend research. WORKSPACE_ROOT=$WORKSPACE. Write the report to 01_trend_research/."
    ;;

  concept)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 concept <product-slug>"; exit 1; }
    echo ">>> Stage 2: Concept Brief for $SLUG"
    run_agent "concept-creator" \
      "Create concept brief for product slug '$SLUG'. WORKSPACE_ROOT=$WORKSPACE. PRODUCT_SLUG=$SLUG."
    ;;

  prompts)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 prompts <product-slug>"; exit 1; }
    echo ">>> Stage 3: Midjourney Prompts for $SLUG"
    run_agent "prompt-writer" \
      "Write Midjourney prompts for '$SLUG'. WORKSPACE_ROOT=$WORKSPACE. PRODUCT_SLUG=$SLUG."
    ;;

  qc)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 qc <product-slug>"; exit 1; }
    echo ">>> Stage 5: QC Review for $SLUG"
    IMG="$WORKSPACE/04_generated_art/$SLUG.png"
    if [[ ! -f "$IMG" ]]; then
      echo "ERROR: Image not found: $IMG"
      echo "  Generate the image in Midjourney, name it '$SLUG.png', and drop it into:"
      echo "  $WORKSPACE/04_generated_art/"
      exit 2
    fi
    run_agent "qc-reviewer" \
      "QC review for '$SLUG'. Image is at $IMG. WORKSPACE_ROOT=$WORKSPACE. PRODUCT_SLUG=$SLUG."
    ;;

  exports)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 exports <product-slug>"; exit 1; }
    echo ">>> Stage 6: Print Exports for $SLUG"
    "$PYTHON" "$SCRIPT_DIR/export_prints.py" \
      --slug "$SLUG" \
      --workspace "$WORKSPACE" \
      --fit crop \
      --format jpg
    ;;

  listing)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 listing <product-slug>"; exit 1; }
    echo ">>> Stage 8: Etsy Listing Copy for $SLUG"
    run_agent "listing-writer" \
      "Write Etsy listing copy for '$SLUG'. WORKSPACE_ROOT=$WORKSPACE. PRODUCT_SLUG=$SLUG."
    ;;

  bundle)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 bundle <product-slug>"; exit 1; }
    echo ">>> Stage 9: Upload Bundle for $SLUG"
    run_agent "bundle-packager" \
      "Package the upload bundle for '$SLUG'. WORKSPACE_ROOT=$WORKSPACE. PRODUCT_SLUG=$SLUG."
    ;;

  status)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 status <product-slug>"; exit 1; }
    echo ">>> Pipeline Status for $SLUG"
    run_agent "orchestrator" \
      "Show full pipeline status for '$SLUG'. WORKSPACE_ROOT=$WORKSPACE. PRODUCT_SLUG=$SLUG."
    ;;

  auto)
    [[ -z "$SLUG" ]] && { echo "Usage: $0 auto <product-slug>"; exit 1; }
    echo ">>> Auto-running next stage for $SLUG"
    run_agent "orchestrator" \
      "Auto-detect and run the next incomplete pipeline stage for '$SLUG'. WORKSPACE_ROOT=$WORKSPACE. PRODUCT_SLUG=$SLUG."
    ;;

  help|--help|-h|*)
    cat <<'EOF'
Etsy Art Pipeline — run_stage.sh

USAGE:
  ./scripts/run_stage.sh <stage> [product-slug]

STAGES:
  research              Stage 1 — Trend research (no slug needed)
  concept  <slug>       Stage 2 — Concept brief
  prompts  <slug>       Stage 3 — Midjourney prompts
  [MANUAL: generate art in Midjourney → drop PNG into 04_generated_art/<slug>.png]
  qc       <slug>       Stage 5 — QC review of the generated image
  exports  <slug>       Stage 6 — Resize to all print formats (Python/Pillow)
  [MANUAL: create mockups → drop into 07_mockups/<slug>/]
  listing  <slug>       Stage 8 — Etsy listing copy
  bundle   <slug>       Stage 9 — Assemble upload bundle

  status   <slug>       Show pipeline status for a product
  auto     <slug>       Run the next incomplete stage automatically

ENVIRONMENT:
  ETSY_WORKSPACE        Override workspace path
                        (default: ~/Desktop/etsy-art-factory/workspace)

EXAMPLES:
  ./scripts/run_stage.sh research
  ./scripts/run_stage.sh concept night-market-neon
  ./scripts/run_stage.sh exports moody-desert-sun
  ETSY_WORKSPACE=/Volumes/External/etsy ./scripts/run_stage.sh status moody-desert-sun
EOF
    ;;
esac

# Etsy Art Pipeline — Setup Guide

## What This Is

A set of Claude Code agents and scripts that automate the repeatable stages of your
Etsy digital-download art pipeline. You still generate images in Midjourney and create
mockups manually — everything else runs from a single command.

---

## Prerequisites

- macOS (Ventura or later recommended)
- Claude Code installed — check with `claude --version`
- Python 3.10 or later — check with `python3 --version`
- Pillow — install with: `pip3 install --user Pillow`

---

## Step 1: Fix the Claude PATH on macOS

Claude Code installs to `~/.local/bin/claude`, but macOS Terminal opens **login shells**
that read `~/.bash_profile` — not `~/.bashrc`. This is why `claude: command not found`
appeared in your last session.

**Fix (run this once):**

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
which claude          # should print: /Users/yourname/.local/bin/claude
claude --version      # should print: 2.x.x
```

---

## Step 2: Install Pillow

```bash
pip3 install --user Pillow
python3 -c "from PIL import Image; print('Pillow OK')"
```

---

## Step 3: Copy Automation Files to Your Mac

From the DR repo, copy the entire `etsy-automation/` folder into your existing project:

```bash
cp -r etsy-automation/ ~/Desktop/etsy-art-factory/
```

Your project structure will then look like:

```
etsy-art-factory/
├── etsy-automation/       ← new
│   ├── SETUP.md
│   ├── .claude/
│   │   ├── settings.json
│   │   └── agents/
│   │       ├── orchestrator.md
│   │       ├── researcher.md
│   │       ├── concept-creator.md
│   │       ├── prompt-writer.md
│   │       ├── qc-reviewer.md
│   │       ├── listing-writer.md
│   │       └── bundle-packager.md
│   └── scripts/
│       ├── export_prints.py
│       └── run_stage.sh
├── workspace/             ← existing
│   ├── 01_trend_research/
│   ├── 02_concept_briefs/
│   ├── 03_midjourney_prompts/
│   ├── 04_generated_art/
│   ├── 05_final_selected_art/
│   ├── 06_print_exports/
│   ├── 07_mockups/
│   ├── 08_listing_copy/
│   ├── 09_upload_bundle/
│   └── 10_logs/
└── CLAUDE.md
```

---

## Step 4: Make the Script Executable

```bash
chmod +x ~/Desktop/etsy-art-factory/etsy-automation/scripts/run_stage.sh
```

---

## Step 5: Log In to Claude Code

```bash
claude auth login
```

Follow the browser prompt. You only need to do this once.

---

## Step 6: Smoke Test

```bash
cd ~/Desktop/etsy-art-factory/etsy-automation
./scripts/run_stage.sh help
```

You should see the full usage menu. If you get `claude: command not found`, re-check Step 1.

---

## Step 7: Run Your First Product (moody-desert-sun)

moody-desert-sun already has its concept brief, prompts, and Midjourney PNG.
Start from Stage 5:

```bash
cd ~/Desktop/etsy-art-factory/etsy-automation

# Stage 5 — QC review
./scripts/run_stage.sh qc moody-desert-sun

# Stage 6 — Resize to all print formats
./scripts/run_stage.sh exports moody-desert-sun

# Stage 8 — Etsy listing copy
./scripts/run_stage.sh listing moody-desert-sun

# Stage 9 — Package upload bundle
./scripts/run_stage.sh bundle moody-desert-sun

# Check full pipeline status
./scripts/run_stage.sh status moody-desert-sun
```

---

## Running a Brand New Product (Full Pipeline)

```bash
cd ~/Desktop/etsy-art-factory/etsy-automation

# 1. Research trends
./scripts/run_stage.sh research

# 2. Create concept brief (choose a slug from the trend report)
./scripts/run_stage.sh concept your-product-slug

# 3. Write Midjourney prompts
./scripts/run_stage.sh prompts your-product-slug

# ── MANUAL STEP ──────────────────────────────────────────────────────────────
# 4. Generate image in Midjourney using the prompts from Stage 3.
#    Save the PNG as: your-product-slug.png
#    Drop it into:    workspace/04_generated_art/your-product-slug.png
# ─────────────────────────────────────────────────────────────────────────────

# 5. QC review
./scripts/run_stage.sh qc your-product-slug

# 6. Print exports
./scripts/run_stage.sh exports your-product-slug

# ── MANUAL STEP ──────────────────────────────────────────────────────────────
# 7. Create mockup images and drop them into:
#    workspace/07_mockups/your-product-slug/
# ─────────────────────────────────────────────────────────────────────────────

# 8. Listing copy
./scripts/run_stage.sh listing your-product-slug

# 9. Bundle
./scripts/run_stage.sh bundle your-product-slug
```

Or use `auto` to let the orchestrator pick the next step:

```bash
./scripts/run_stage.sh auto your-product-slug
```

---

## Troubleshooting

### `claude: command not found` in Terminal
Re-run Step 1. Make sure you added the export line to `~/.bash_profile`, not `~/.bashrc`.

### `claude: command not found` when running the script directly (e.g., double-click or cron)
The script bootstraps PATH internally. If still failing, set the env var manually:
```bash
CLAUDE_BIN="$HOME/.local/bin/claude" ./scripts/run_stage.sh exports moody-desert-sun
```
Then open `run_stage.sh` and change:
```bash
CLAUDE="$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")"
```
to:
```bash
CLAUDE="${CLAUDE_BIN:-$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")}"
```

### `ModuleNotFoundError: No module named 'PIL'`
```bash
pip3 install --user --upgrade Pillow
```

### Export script skips large sizes
The source image is too small for those sizes. Upscale in Midjourney (use `/upscale 2x`)
before running exports. Or allow upscaling (lower quality):
```bash
python3 scripts/export_prints.py --slug your-slug --allow-upscale
```

### Agent writes nothing / empty output
Check the log: `cat workspace/10_logs/your-slug-pipeline.log`
Enable debug mode: `CLAUDE_DEBUG=1 ./scripts/run_stage.sh listing your-slug`

---

## Workspace Environment Variable

If your workspace is not at `~/Desktop/etsy-art-factory/workspace`, set:

```bash
export ETSY_WORKSPACE="/your/custom/path/workspace"
./scripts/run_stage.sh exports your-slug
```

Or set it permanently in `~/.bash_profile`:
```bash
echo 'export ETSY_WORKSPACE="/your/custom/path/workspace"' >> ~/.bash_profile
source ~/.bash_profile
```

# Portfolio Shot Guide

This repo now includes two kinds of visual assets:

- **Ready now:** `assets/previews/*.png`
- **True CAD renders later:** generated with `scripts/render_portfolio_presets.sh`

## Upload-Ready Images

Use these files immediately for GitHub, Behance, Notion, or a portfolio site:

```text
assets/previews/portfolio-overview.png
assets/previews/transmission-generator-cover.png
assets/previews/pcb-enclosure-cover.png
assets/previews/bracket-handoff-cover.png
assets/previews/structural-bracket-cover.png
```

## Hero Presets

### 01 · Transmission Generator

```bash
openscad \
  -o assets/renders/01-transmission-mesh.png \
  -D 'render_mode="mesh_preview"' \
  -D 'num_teeth=24' \
  -D 'mate_teeth=36' \
  -D 'mesh_rotation_deg=8' \
  --camera=60,25,18,65,0,35,320 \
  --imgsize=2200,1400 \
  01_parametric_gear/parametric_gear.scad
```

Shot intent: show two visibly different gears, centre distance, and the fact that the project is now pair-aware.

### 02 · PCB Enclosure Generator

```bash
openscad \
  -o assets/renders/02-enclosure-exploded.png \
  -D 'closure_mode="screw"' \
  -D 'gasket_enabled=true' \
  -D 'show_exploded=true' \
  --camera=52,42,30,66,0,36,320 \
  --imgsize=2200,1400 \
  02_enclosure_box/enclosure.scad
```

Shot intent: show lid strategy, PCB-driven enclosure logic, and cutout/product packaging feel.

### 03 · Bracket Handoff Drawing

Open `03_technical_drawing/mounting_bracket.dxf` in LibreCAD or QCAD and capture the full sheet with title block visible.

Recommended framing:

- full sheet visible
- top/front/right views readable
- notes and title block included

### 04 · Structural Bracket Family

```bash
python3 04_cadquery_bracket/bracket.py \
  --base-hole-type slot \
  --base-slot-len 24 \
  --tip-load-n 400 \
  --prefix assets/renders/04-structural-bracket
```

Shot intent: use exported geometry plus terminal output as part of the case study; pair with `assets/previews/structural-bracket-cover.png` as the immediate hero image.

## Suggested Posting Order

1. `assets/previews/portfolio-overview.png`
2. `assets/previews/transmission-generator-cover.png`
3. `assets/previews/pcb-enclosure-cover.png`
4. `assets/previews/structural-bracket-cover.png`
5. `assets/previews/bracket-handoff-cover.png`

## Quick Command

If the tools are installed on your machine:

```bash
./scripts/render_portfolio_presets.sh
```

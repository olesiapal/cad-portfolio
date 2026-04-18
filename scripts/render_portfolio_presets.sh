#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/assets/renders"

mkdir -p "$OUT_DIR"

echo "Output directory: $OUT_DIR"

if command -v openscad >/dev/null 2>&1; then
  echo "Rendering OpenSCAD presets..."

  openscad \
    -o "$OUT_DIR/01-transmission-mesh.png" \
    -D 'render_mode="mesh_preview"' \
    -D 'num_teeth=24' \
    -D 'mate_teeth=36' \
    -D 'mesh_rotation_deg=8' \
    --camera=60,25,18,65,0,35,320 \
    --imgsize=2200,1400 \
    "$ROOT_DIR/01_parametric_gear/parametric_gear.scad"

  openscad \
    -o "$OUT_DIR/02-enclosure-exploded.png" \
    -D 'closure_mode="screw"' \
    -D 'gasket_enabled=true' \
    -D 'show_exploded=true' \
    --camera=52,42,30,66,0,36,320 \
    --imgsize=2200,1400 \
    "$ROOT_DIR/02_enclosure_box/enclosure.scad"
else
  echo "openscad not found; skipped true CAD renders for projects 01 and 02."
fi

if python3 - <<'PY'
import importlib.util, sys
sys.exit(0 if importlib.util.find_spec("cadquery") else 1)
PY
then
  echo "Exporting CadQuery preset geometry..."
  python3 "$ROOT_DIR/04_cadquery_bracket/bracket.py" \
    --base-hole-type slot \
    --base-slot-len 24 \
    --tip-load-n 400 \
    --prefix "$OUT_DIR/04-structural-bracket"
else
  echo "cadquery Python package not found; skipped bracket export preset."
fi

cat <<'EOF'

Manual screenshot note:
- Use assets/previews/*.png immediately for portfolio covers.
- If LibreCAD/QCAD is installed, open 03_technical_drawing/mounting_bracket.dxf
  and capture the full sheet at 1:1 with the title block visible.
EOF

# CAD Portfolio

> Script-based parametric CAD — involute gears, snap-fit enclosures, structural brackets, and engineering drawings. Every model is code-driven: change a parameter, get a new part.

---

## Projects

### 01 · [Parametric Involute Spur Gear](01_parametric_gear/) — OpenSCAD

True involute tooth profile with backlash compensation, weight-reduction spokes, keyway, chamfers, and herringbone mode. All geometry derived from metric module and tooth count.

```
module = 2 · 24 teeth · 20° pressure angle · spoke pockets · optional herringbone
```

**Key features:** involute math from base circle · configurable backlash · spoke weight reduction · tip/bore chamfers · mating gear preview · CLI parameter overrides

---

### 02 · [Snap-Fit Electronics Enclosure](02_enclosure_box/) — OpenSCAD

Two-part snap-fit enclosure for custom PCBs. Base and lid generated from a single dimension set — standoffs, ventilation, cable glands, mounting ears, and label recess all adapt automatically.

```
80 × 60 × 30 mm cavity · 2.5 mm wall · M2.5 heat-set standoffs · keyhole mount ears
```

**Key features:** snap-fit lip with interference control · ventilation slot array · rear cable glands · wall-mount ears with keyhole · lid label recess · cross-section preview mode

---

### 03 · [Mounting Bracket — Technical Drawing](03_technical_drawing/) — DXF

Dimensioned engineering drawing in DXF R2000 format with proper layer structure, tolerance callouts per ISO 2768-m, hole fit designations (H7), surface finish symbols, and a complete title block.

```
100 × 60 mm · 4× Ø15 / Ø8 cbore · Al 6061-T6 · ISO 2768-m tolerances
```

**Key features:** 6-layer structure (OUTLINE / HIDDEN / CENTERLINE / DIMENSION / TITLEBLOCK / ANNOTATION) · H7 hole tolerances · Ra 3.2 surface finish · deburr note · third-angle projection

---

### 04 · [L-Bracket with Gusset](04_cadquery_bracket/) — CadQuery (Python)

Structural bracket generated programmatically with CadQuery. Exports STEP + STL + DXF. Includes mass estimation, CLI argument parsing, and a clean dataclass-based configuration system.

```
80 × 80 mm flange · 60 mm leg · 6 mm thick · M8 cbore + M6 through · Al 6061-T6 at 131 g
```

**Key features:** triangular gusset ribs · counterbored + through holes · lightening cutout · material mass calc · multi-format export · CLI overrides · library-importable API

---

## Tools & Formats

| Project | Tool | Input | Output |
|---|---|---|---|
| Spur Gear | OpenSCAD ≥ 2021.01 | `.scad` | `.stl` · `.dxf` · `.amf` |
| Enclosure | OpenSCAD ≥ 2021.01 | `.scad` | `.stl` |
| Technical Drawing | Any DXF viewer | `.dxf` | — |
| L-Bracket | CadQuery 2.x / Python 3.9+ | `.py` | `.step` · `.stl` · `.dxf` |

## Running the Projects

### OpenSCAD (Projects 01 & 02)

```bash
# Install: https://openscad.org/downloads.html
openscad 01_parametric_gear/parametric_gear.scad   # F5 preview · F6 render

# CLI batch export with parameter overrides
openscad -o gear_m3_z36.stl -D 'module_size=3' -D 'num_teeth=36' \
  01_parametric_gear/parametric_gear.scad
```

### CadQuery (Project 04)

```bash
pip install cadquery
python 04_cadquery_bracket/bracket.py
# → bracket.step + bracket.stl + bracket_profile.dxf

python 04_cadquery_bracket/bracket.py --flange-w 120 --thickness 8
```

### DXF Viewer (Project 03)

```
LibreCAD (free)  ·  QCAD  ·  AutoCAD  ·  FreeCAD  ·  DraftSight
```

## Design Philosophy

Every project in this portfolio follows the same principles:

1. **Parametric first** — geometry is driven by variables, not manual dimensions
2. **Code as CAD** — reproducible, version-controlled, reviewable
3. **Production-aware** — tolerances, material specs, and manufacturing notes included
4. **Standards-based** — ISO/DIN conventions for modules, fits, and tolerancing

## License

MIT — see [LICENSE](LICENSE)

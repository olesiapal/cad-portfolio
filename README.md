# CAD Portfolio

> A collection of parametric CAD projects demonstrating proficiency in
> script-based 3D modelling, 2D technical drafting, and engineering design.

---

## Projects

### 01 · Parametric Involute Spur Gear — OpenSCAD

**File:** [`01_parametric_gear/parametric_gear.scad`](01_parametric_gear/parametric_gear.scad)

A fully parametric spur gear with a true involute tooth profile, hub, keyway, and root fillets.
All geometry is driven by a small set of parameters at the top of the file —
change `num_teeth`, `module_size`, or `pressure_angle` and the entire model rebuilds instantly.

- True involute geometry (not polygon approximation)
- Metric module system
- Raised hub with keyway slot
- Preview mode for meshing pair

```
module_size = 2 | num_teeth = 24 | pressure_angle = 20° | height = 10 mm
```

---

### 02 · Snap-Fit Electronics Enclosure — OpenSCAD

**File:** [`02_enclosure_box/enclosure.scad`](02_enclosure_box/enclosure.scad)

A two-part snap-fit enclosure designed for custom PCBs.
Base and lid are generated from a single set of parameters —
change inner dimensions and all features (standoffs, lip, cutouts) adapt automatically.

- Four M2.5 PCB standoffs with counterbored screw holes
- Snap-fit lip with configurable interference
- Rear cable gland cutouts (count and diameter parametric)
- Exploded view mode for documentation renders

```
inner: 80 × 60 × 30 mm | wall: 2.5 mm | snap lip: 1.2 mm interference
```

---

### 03 · Mounting Bracket — Technical Drawing (DXF)

**File:** [`03_technical_drawing/mounting_bracket.dxf`](03_technical_drawing/mounting_bracket.dxf)

A dimensioned front-view technical drawing of an aluminium mounting bracket,
produced in standard DXF R2000 format. Compatible with AutoCAD, LibreCAD, QCAD, and FreeCAD.

- Proper layer structure: OUTLINE / HIDDEN / CENTERLINE / DIMENSION / TITLEBLOCK
- Four M8 clearance holes on 60 mm pattern
- Full dimensioning with tolerance callouts
- Title block: part number MB-001, material Al 6061-T6, scale 1:1

---

### 04 · L-Bracket with Gusset — CadQuery (Python)

**File:** [`04_cadquery_bracket/bracket.py`](04_cadquery_bracket/bracket.py)

A structural L-bracket generated entirely in Python using the CadQuery library.
Exports production-ready `.step` and `.stl` files programmatically.

- Triangular gusset rib for torsional rigidity
- Counterbored mounting holes on both flanges
- Full edge filleting
- STEP export for downstream CAD import

```bash
pip install cadquery
python bracket.py
# → bracket.step + bracket.stl
```

```
flange: 80 × 80 mm | leg: 80 × 60 mm | thickness: 6 mm | holes: Ø8.5 / CB Ø14
```

---

## Tools & Formats

| Project | Tool | Output Format |
|---|---|---|
| Spur Gear | OpenSCAD | `.scad` → `.stl` / `.dxf` |
| Enclosure | OpenSCAD | `.scad` → `.stl` |
| Technical Drawing | DXF / LibreCAD | `.dxf` |
| L-Bracket | CadQuery (Python) | `.step` / `.stl` |

## Running the Projects

**OpenSCAD** (projects 01 & 02)
```
Download: https://openscad.org/downloads.html
Open .scad file → F5 preview → F6 render → Export
```

**CadQuery** (project 04)
```bash
pip install cadquery
python bracket.py
```

**DXF** (project 03)
```
Open with: LibreCAD, QCAD, AutoCAD, FreeCAD, or any DXF-compatible viewer
```

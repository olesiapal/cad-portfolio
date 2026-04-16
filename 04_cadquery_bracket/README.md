# 04 · Parametric L-Bracket with Gusset — CadQuery

**Tool:** CadQuery 2.x (Python 3.9+)  
**Output:** `.step` · `.stl` · `.dxf`

---

## Overview

A structural L-bracket generated entirely in Python using the CadQuery kernel. The script produces production-ready STEP files suitable for downstream CAD import, FEA, or direct CNC machining. All geometry is driven by a `BracketConfig` dataclass — swap values or subclass it for project-specific variants.

> **Design intent:** General-purpose mounting bracket for panel/wall attachment. Default sizing fits M8 base bolts and M6 leg fasteners in Al 6061-T6.

## Features

| Feature | Description |
|---|---|
| **Gusset ribs** | Triangular stiffener on the inner bend for torsional rigidity |
| **Counterbored holes** | Base flange — M8 clearance with Ø14 counterbore |
| **Through-holes** | Vertical leg — M6 clearance, 1 or 2 rows |
| **Lightening cutout** | Optional oval slot on vertical leg to reduce weight |
| **Edge fillets** | Full fillet pass on vertical edges |
| **Mass estimation** | Volume-based mass calculation with configurable material density |
| **Multi-format export** | STEP + STL + DXF (profile cross-section) |
| **CLI overrides** | Change dimensions from the command line without editing code |

## Quick Start

```bash
pip install cadquery

# Default bracket
python bracket.py
# → bracket.step, bracket.stl, bracket_profile.dxf

# Custom dimensions
python bracket.py --flange-w 100 --leg-h 80 --thickness 8

# Without lightening cutout
python bracket.py --no-cutout
```

## Configuration

All parameters are defined in the `BracketConfig` dataclass:

```python
@dataclass
class BracketConfig:
    flange_w: float = 80.0        # Base flange width [mm]
    flange_depth: float = 80.0    # Base flange depth [mm]
    leg_h: float = 60.0           # Vertical leg height [mm]
    thickness: float = 6.0        # Material thickness [mm]
    base_hole_d: float = 8.5      # M8 clearance [mm]
    base_cbore_d: float = 14.0    # Counterbore OD [mm]
    enable_cutout: bool = True     # Lightening slot
    material_name: str = "Al 6061-T6"
    density_kg_m3: float = 2710.0  # For mass calc
```

## Sample Output

```
Building bracket: 80.0 × 80.0 × 60.0 mm, t=6.0 mm

────────────────────────────────────────────────
  Material:      Al 6061-T6
  Bounding box:  80.0 × 80.0 × 66.0 mm
  Volume:        48320.5 mm³
  Mass:          130.9 g (ρ = 2710 kg/m³)
────────────────────────────────────────────────
  ✓ STEP  → bracket.step
  ✓ STL   → bracket.stl
  ✓ DXF   → bracket_profile.dxf
```

## Integration

```python
# Use as a library in your own scripts
from bracket import BracketConfig, build_bracket, analyse

cfg = BracketConfig(flange_w=120, thickness=8)
model = build_bracket(cfg)
info = analyse(model, cfg)
print(f"Mass: {info['mass_g']:.0f} g")
```

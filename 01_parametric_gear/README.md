# 01 · Parametric Involute Spur Gear

**Tool:** OpenSCAD ≥ 2021.01  
**Output:** `.stl` · `.dxf` · `.amf`

---

## Overview

A production-grade parametric involute spur gear with configurable tooth geometry, weight-reduction spokes, keyway, chamfers, and optional herringbone (double-helical) mode. Every dimension is driven by parameters — change one value and the entire model regenerates.

> **Design intent:** Drop-in power transmission gear for prototyping and light-duty mechanisms. Suitable for 3D printing (FDM/SLA) or laser-cut acrylic/plywood profiles.

## Parameters at a Glance

| Group | Parameter | Default | Description |
|---|---|---|---|
| **Tooth** | `module_size` | 2 | Metric module — controls tooth pitch |
| | `num_teeth` | 24 | Tooth count (≥ 8) |
| | `pressure_angle` | 20° | Standard involute pressure angle |
| | `backlash` | 0.1 mm | Per-flank clearance for meshing |
| **Body** | `gear_height` | 10 mm | Face width |
| | `enable_spokes` | true | Weight-reduction spoke pattern |
| | `spoke_count` | 5 | Number of radial spokes |
| **Hub** | `hub_diameter` | 16 mm | Central hub OD |
| | `bore_diameter` | 8 mm | Shaft bore |
| | `keyway_width` | 3 mm | DIN 6885 keyway (0 = none) |
| **Finish** | `tip_chamfer` | 0.3 mm | Tooth tip break edge |
| | `bore_chamfer` | 0.5 mm | Bore entry chamfer |
| **Herringbone** | `herringbone` | false | Double-helical mode |
| | `helix_angle` | 25° | Helix angle when enabled |

## Key Features

- **True involute profile** computed from base circle — not a polygon approximation
- **Backlash compensation** — adjustable per-flank clearance for real-world meshing
- **Weight reduction** — parametric spoke pattern with configurable floor thickness
- **Herringbone mode** — toggle `herringbone = true` for axial-thrust-free operation
- **Keyway** — DIN-style slot for positive shaft locking
- **Chamfers** — tooth tips and bore entry for print quality and assembly ease
- **Mating preview** — enable `show_mate` to visualise a meshing pair in-place
- **Input validation** — `assert()` guards prevent impossible geometry

## Engineering Notes

The tooth profile follows ISO 53 / DIN 867 conventions:

```
Addendum     = 1.0 × module
Dedendum     = 1.25 × module
Clearance    = 0.25 × module
Pitch dia.   = module × teeth
Base circle  = pitch dia. × cos(pressure_angle)
```

For 3D-printed gears, increase `backlash` to 0.15–0.25 mm depending on printer tolerance. SLA resins can use tighter values (0.05–0.10 mm).

## Usage

```bash
# Preview in OpenSCAD GUI
openscad parametric_gear.scad        # F5 preview · F6 full render

# Command-line STL export
openscad -o gear_m2_z24.stl parametric_gear.scad

# Override parameters from CLI
openscad -o gear_m3_z36.stl \
  -D 'module_size=3' -D 'num_teeth=36' -D 'herringbone=true' \
  parametric_gear.scad
```

## Customisation Examples

| Use Case | Changes |
|---|---|
| Small pinion | `num_teeth=12`, `module_size=1.5` |
| Heavy-duty | `module_size=4`, `gear_height=20`, `spoke_count=6` |
| Herringbone pair | `herringbone=true`, `helix_angle=30` |
| Laser-cut profile | Export as DXF (2D), ignore hub height |

# 01 · Parametric Involute Spur Gear

**Tool:** OpenSCAD  
**Format:** `.scad`

## Overview

A fully parametric involute spur gear generated entirely through script.  
Change any value in the `[Gear Parameters]` block and the geometry regenerates instantly — no manual redraw needed.

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `module_size` | 2 | Controls tooth size (standard metric module) |
| `num_teeth` | 24 | Number of teeth |
| `pressure_angle` | 20° | Involute pressure angle |
| `gear_height` | 10 mm | Face width |
| `bore_diameter` | 5 mm | Shaft hole |
| `hub_diameter` | 12 mm | Central hub |

## Features

- True involute tooth profile (not approximated)
- Addendum / dedendum calculated from module
- Keyway slot for shaft locking
- Raised hub for bearing seat
- Mating gear preview (commented out — uncomment to visualise mesh)

## Usage

```bash
openscad parametric_gear.scad
# Export → STL for 3D printing
# Export → DXF for laser cutting (2D profile)
```

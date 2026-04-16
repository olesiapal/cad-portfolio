# 02 · Snap-Fit Electronics Enclosure

**Tool:** OpenSCAD ≥ 2021.01  
**Output:** `.stl` (FDM/SLA print-ready)

---

## Overview

A production-ready two-part snap-fit enclosure for custom electronics. Both halves are generated from a single parameter set — change the inner dimensions and every feature (standoffs, lip, vents, glands, mounting ears) adapts automatically. Designed with FDM print tolerances in mind; also suitable for SLA or low-volume injection moulding.

> **Design intent:** General-purpose enclosure for Raspberry Pi / Arduino / custom PCB projects. Prints without supports in the default orientation (base up, lid up).

## Features

| Feature | Description |
|---|---|
| **Snap-fit lip** | Interference-fit perimeter lip with lead-in chamfer; configurable interference for PLA / ABS / PETG |
| **PCB standoffs** | 4× corner standoffs sized for M2.5 heat-set inserts |
| **Ventilation** | Parametric slot array on both side walls; toggle on/off |
| **Cable glands** | Rear-wall circular cutouts (count & diameter configurable) |
| **Mounting ears** | Optional wall-mount ears with keyhole slots for tool-free hanging |
| **Label recess** | Shallow pocket on lid for adhesive label or engraved nameplate |
| **Draft angle** | Configurable draft for injection-mould compatibility |
| **Preview modes** | Exploded view & cross-section cut for documentation renders |

## Parameters

<details>
<summary>Full parameter table (click to expand)</summary>

| Group | Parameter | Default | Description |
|---|---|---|---|
| Dimensions | `inner_w / _d / _h` | 80 / 60 / 30 | Cavity size [mm] |
| Wall | `wall` | 2.5 | Shell thickness [mm] |
| | `corner_r` | 4 | Fillet radius [mm] |
| | `draft_angle` | 1° | Wall draft for moulding |
| Snap-fit | `lip_h` | 3.0 | Lip height [mm] |
| | `lip_w` | 1.2 | Interference [mm] |
| Standoffs | `standoff_h` | 4 | Height [mm] |
| | `insert_d` | 3.6 | Heat-set bore for M2.5 |
| Cable | `gland_d` | 8 | Hole diameter [mm] |
| | `gland_count` | 2 | Number of holes |
| Vents | `enable_vents` | true | On/off |
| | `vent_slot_w` | 1.5 | Slot width [mm] |
| Ears | `enable_ears` | true | Wall-mount lugs |
| Label | `label_recess` | true | Lid recess |

</details>

## Print Settings (FDM)

| Setting | Recommendation |
|---|---|
| Layer height | 0.2 mm |
| Walls | 3 perimeters |
| Infill | 20–30% grid |
| Supports | None needed |
| Material | PLA / PETG / ABS |

For **PLA**, use `lip_w = 1.0` (less flex).  
For **PETG/ABS**, default `lip_w = 1.2` works well.

## Usage

```bash
# GUI preview
openscad enclosure.scad

# CLI export — base and lid as one STL
openscad -o enclosure.stl enclosure.scad

# Custom dimensions from command line
openscad -o enclosure_120x80.stl \
  -D 'inner_w=120' -D 'inner_d=80' -D 'inner_h=40' \
  enclosure.scad

# Exploded view for documentation
openscad -o exploded.png \
  -D 'show_exploded=true' \
  --camera=40,30,25,30,0,20,250 --imgsize=1920,1080 \
  enclosure.scad
```

## Customisation Examples

| Use Case | Key Changes |
|---|---|
| Raspberry Pi 4 case | `inner_w=90`, `inner_d=65`, `inner_h=25`, `gland_count=3` |
| Waterproof (IP54-ish) | `enable_vents=false`, `lip_w=1.5` |
| Wall-mount sensor | `enable_ears=true`, `ear_keyhole=true` |
| Injection mould | `draft_angle=2`, `corner_r=3`, `lip_chamfer=0.6` |

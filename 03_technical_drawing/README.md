# 03 · Mounting Bracket — Technical Drawing

**Format:** DXF R2000 (AC1015)  
**Compatible:** AutoCAD · LibreCAD · QCAD · FreeCAD · DraftSight

---

## Overview

A fully dimensioned front-view technical drawing of an aluminium mounting bracket, authored in standard DXF format with proper layer discipline. Demonstrates knowledge of engineering drawing conventions per ISO 128 / ASME Y14.5.

> **Part:** MB-001 — Mounting Bracket  
> **Material:** Al 6061-T6  
> **Scale:** 1 : 1

## Drawing Content

### Views
- **Front view** — full outline with four mounting holes on 60 × 30 mm bolt pattern

### Layer Structure

| Layer | Colour | Linetype | Purpose |
|---|---|---|---|
| `OUTLINE` | White (7) | Continuous | Visible edges |
| `HIDDEN` | Grey (8) | Dashed | Concealed features (screw bores) |
| `CENTERLINE` | Red (1) | Center | Hole centres, axes of symmetry |
| `DIMENSION` | Green (3) | Continuous | Dimension lines, extension lines, values |
| `TITLEBLOCK` | White (7) | Continuous | Border, title block frame |
| `ANNOTATION` | Yellow (2) | Continuous | Notes, tolerances, part info |

### Dimensions & Tolerances

```
Overall:     100 × 60 mm
Hole pattern: 60 mm horizontal, 30 mm vertical
Holes:       4× Ø15 clearance, Ø8 bore (hidden lines)
Tolerances:  Linear ±0.1 mm · Angular ±0.5° · Holes +0.05/0.00 mm
```

### Title Block

| Field | Value |
|---|---|
| Part Name | MOUNTING BRACKET |
| Drawing No | MB-001 |
| Scale | 1:1 |
| Material | Al 6061-T6 |

## Usage

```bash
# Open in LibreCAD (free)
librecad mounting_bracket.dxf

# Open in FreeCAD
freecad mounting_bracket.dxf

# Command-line conversion to PDF (using LibreCAD CLI or QCAD)
qcad -print mounting_bracket.dxf
```

## Standards Referenced

- **ISO 128** — Technical drawings: general principles of presentation
- **ISO 2768-1** — General tolerances for linear and angular dimensions
- **ASME Y14.5** — Dimensioning and tolerancing
- **ISO 7083** — Symbols for geometrical tolerancing

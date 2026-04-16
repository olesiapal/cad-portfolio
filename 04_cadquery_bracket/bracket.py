"""
CadQuery Portfolio Project — Parametric L-Bracket with Gusset
=============================================================
Generates a structural L-bracket with filleted edges, mounting
holes, and a triangular gusset for rigidity.

Requirements:
    pip install cadquery
    # or use CQ-editor (https://github.com/CadQuery/CQ-editor)

Usage:
    python bracket.py
    # Exports bracket.step and bracket.stl to working directory
"""

import cadquery as cq

# ── Parameters ───────────────────────────────────────────────
FLANGE_W       = 80.0   # Flange width  (mm)
FLANGE_H       = 60.0   # Vertical leg height
THICKNESS      = 6.0    # Material thickness
FILLET_R       = 2.0    # Edge fillet radius
HOLE_D         = 8.5    # Mounting hole diameter (M8 clearance)
HOLE_MARGIN    = 12.0   # Hole centre from edge
COUNTERBORE_D  = 14.0   # Counterbore diameter
COUNTERBORE_D2 = 8.5    # Countersink minor diameter (leave 0 to skip)
GUSSET_DEPTH   = 40.0   # Gusset depth (triangular rib)

# ── Horizontal flange ────────────────────────────────────────
base = (
    cq.Workplane("XY")
    .box(FLANGE_W, FLANGE_W, THICKNESS, centered=(True, True, False))
)

# ── Vertical leg ─────────────────────────────────────────────
leg = (
    cq.Workplane("XZ")
    .workplane(offset=-FLANGE_W / 2)
    .box(FLANGE_W, FLANGE_H, THICKNESS, centered=(True, False, False))
    .translate([0, FLANGE_W / 2 - THICKNESS / 2, THICKNESS])
)

bracket = base.union(leg)

# ── Gusset (triangular rib on back face) ────────────────────
gusset_pts = [
    (0, 0),
    (GUSSET_DEPTH, 0),
    (0, GUSSET_DEPTH),
]
gusset = (
    cq.Workplane("YZ")
    .workplane(offset=0)
    .polyline(gusset_pts)
    .close()
    .extrude(THICKNESS)
    .translate([-THICKNESS / 2, -FLANGE_W / 2, THICKNESS])
)

bracket = bracket.union(gusset)

# ── Fillets ──────────────────────────────────────────────────
bracket = bracket.edges("|Z").fillet(FILLET_R)

# ── Mounting holes on base flange ───────────────────────────
hole_positions = [
    (HOLE_MARGIN - FLANGE_W / 2,  HOLE_MARGIN - FLANGE_W / 2),
    (FLANGE_W / 2 - HOLE_MARGIN,  HOLE_MARGIN - FLANGE_W / 2),
    (HOLE_MARGIN - FLANGE_W / 2,  FLANGE_W / 2 - HOLE_MARGIN),
    (FLANGE_W / 2 - HOLE_MARGIN,  FLANGE_W / 2 - HOLE_MARGIN),
]

bracket = (
    bracket
    .faces(">Z")
    .workplane()
    .pushPoints(hole_positions)
    .cboreHole(HOLE_D, COUNTERBORE_D, THICKNESS / 2)
)

# ── Mounting holes on vertical leg ──────────────────────────
leg_hole_positions = [
    (HOLE_MARGIN - FLANGE_W / 2,  HOLE_MARGIN + THICKNESS),
    (FLANGE_W / 2 - HOLE_MARGIN,  HOLE_MARGIN + THICKNESS),
]

bracket = (
    bracket
    .faces(">Y")
    .workplane()
    .pushPoints(leg_hole_positions)
    .hole(HOLE_D)
)

# ── Export ──────────────────────────────────────────────────
cq.exporters.export(bracket, "bracket.step")
cq.exporters.export(bracket, "bracket.stl")

print("✓ Exported: bracket.step")
print("✓ Exported: bracket.stl")
print(f"\nGeometry summary:")
print(f"  Base flange:  {FLANGE_W} × {FLANGE_W} × {THICKNESS} mm")
print(f"  Vertical leg: {FLANGE_W} × {FLANGE_H} × {THICKNESS} mm")
print(f"  Mounting holes: Ø{HOLE_D} with Ø{COUNTERBORE_D} counterbore")
print(f"  Gusset depth: {GUSSET_DEPTH} mm")

# ── Visualise in CQ-editor (comment out for CLI use) ────────
# show_object(bracket, name="L-Bracket with Gusset")

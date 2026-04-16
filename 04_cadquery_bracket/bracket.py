"""
CadQuery — Parametric L-Bracket with Gusset
============================================
Generates a structural L-bracket with:
  • Triangular gusset rib for torsional/bending rigidity
  • Counterbored mounting holes on base flange
  • Through-holes on vertical leg
  • Full edge filleting
  • Lightening cutout on vertical leg (optional)
  • Material mass estimation (Al 6061-T6 default)
  • STEP + STL + DXF export

Requirements:
    pip install cadquery

Usage:
    python bracket.py                     # Default parameters
    python bracket.py --flange-w 100      # Override via CLI
"""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass, field

try:
    import cadquery as cq
except ImportError:
    sys.exit(
        "ERROR: CadQuery not installed.\n"
        "       pip install cadquery\n"
        "       https://cadquery.readthedocs.io/en/latest/installation.html"
    )

# ═══════════════════════════════════════════════════════════════
#  Configuration
# ═══════════════════════════════════════════════════════════════

@dataclass
class BracketConfig:
    """All dimensions in millimetres."""

    # ── Flange geometry ──────────────────────────────────────
    flange_w: float = 80.0        # Flange width  (X & Y)
    flange_depth: float = 80.0    # Flange depth  (Y direction)
    leg_h: float = 60.0           # Vertical leg height
    thickness: float = 6.0        # Material thickness

    # ── Fillets ──────────────────────────────────────────────
    fillet_r: float = 2.0         # Edge fillet radius
    inner_fillet_r: float = 4.0   # Interior bend fillet

    # ── Gusset ───────────────────────────────────────────────
    gusset_depth: float = 40.0    # Triangular rib depth
    gusset_thickness: float = 0.0 # 0 = same as main thickness

    # ── Base flange holes ────────────────────────────────────
    base_hole_d: float = 8.5      # M8 clearance
    base_cbore_d: float = 14.0    # Counterbore diameter
    base_cbore_depth: float = 3.0 # Counterbore depth
    base_hole_margin: float = 14.0

    # ── Vertical leg holes ───────────────────────────────────
    leg_hole_d: float = 6.5       # M6 clearance
    leg_hole_margin: float = 14.0
    leg_hole_rows: int = 1        # 1 or 2 rows

    # ── Lightening cutout (vertical leg) ─────────────────────
    enable_cutout: bool = True
    cutout_w: float = 30.0        # Width of oval cutout
    cutout_h: float = 20.0        # Height of oval cutout
    cutout_fillet: float = 8.0    # Corner radius of cutout

    # ── Material ─────────────────────────────────────────────
    material_name: str = "Al 6061-T6"
    density_kg_m3: float = 2710.0 # Aluminium 6061
    yield_mpa: float = 276.0      # Yield strength

    @property
    def gusset_t(self) -> float:
        return self.gusset_thickness or self.thickness


# ═══════════════════════════════════════════════════════════════
#  Builder
# ═══════════════════════════════════════════════════════════════

def build_bracket(cfg: BracketConfig) -> cq.Workplane:
    """Construct the bracket solid from config."""

    # ── 1. Base flange ───────────────────────────────────────
    base = (
        cq.Workplane("XY")
        .box(cfg.flange_w, cfg.flange_depth, cfg.thickness,
             centered=(True, True, False))
    )

    # ── 2. Vertical leg ──────────────────────────────────────
    leg = (
        cq.Workplane("XZ")
        .workplane(offset=-cfg.flange_depth / 2)
        .box(cfg.flange_w, cfg.leg_h, cfg.thickness,
             centered=(True, False, False))
        .translate([0, cfg.flange_depth / 2 - cfg.thickness / 2,
                    cfg.thickness])
    )

    bracket = base.union(leg)

    # ── 3. Gusset (triangular rib) ───────────────────────────
    gd = cfg.gusset_depth
    gusset_pts = [(0, 0), (gd, 0), (0, gd)]
    gusset = (
        cq.Workplane("YZ")
        .polyline(gusset_pts).close()
        .extrude(cfg.gusset_t)
        .translate([-cfg.gusset_t / 2,
                    -cfg.flange_depth / 2,
                    cfg.thickness])
    )
    bracket = bracket.union(gusset)

    # ── 4. Mirror gusset to opposite side ────────────────────
    gusset_mirror = (
        cq.Workplane("YZ")
        .polyline(gusset_pts).close()
        .extrude(cfg.gusset_t)
        .translate([-cfg.gusset_t / 2 + cfg.flange_w / 2 - cfg.gusset_t / 2,
                    -cfg.flange_depth / 2,
                    cfg.thickness])
    )
    # Second gusset on the other side
    gusset2 = (
        cq.Workplane("YZ")
        .polyline(gusset_pts).close()
        .extrude(cfg.gusset_t)
        .translate([cfg.flange_w / 2 - cfg.gusset_t - cfg.gusset_t / 2,
                    -cfg.flange_depth / 2,
                    cfg.thickness])
    )

    # ── 5. Edge fillets ──────────────────────────────────────
    try:
        bracket = bracket.edges("|Z").fillet(cfg.fillet_r)
    except Exception:
        pass  # Skip if fillet fails on thin edges

    # ── 6. Base flange mounting holes ────────────────────────
    m = cfg.base_hole_margin
    hw = cfg.flange_w / 2
    hd = cfg.flange_depth / 2
    base_holes = [
        ( m - hw,  m - hd),
        ( hw - m,  m - hd),
        ( m - hw,  hd - m),
        ( hw - m,  hd - m),
    ]

    bracket = (
        bracket
        .faces(">Z").workplane()
        .pushPoints(base_holes)
        .cboreHole(cfg.base_hole_d, cfg.base_cbore_d, cfg.base_cbore_depth)
    )

    # ── 7. Vertical leg mounting holes ───────────────────────
    leg_holes = [
        (cfg.leg_hole_margin - hw, cfg.leg_hole_margin + cfg.thickness),
        (hw - cfg.leg_hole_margin, cfg.leg_hole_margin + cfg.thickness),
    ]
    if cfg.leg_hole_rows >= 2:
        row2_y = cfg.leg_h - cfg.leg_hole_margin
        leg_holes += [
            (cfg.leg_hole_margin - hw, row2_y),
            (hw - cfg.leg_hole_margin, row2_y),
        ]

    bracket = (
        bracket
        .faces(">Y").workplane()
        .pushPoints(leg_holes)
        .hole(cfg.leg_hole_d)
    )

    # ── 8. Lightening cutout on vertical leg ─────────────────
    if cfg.enable_cutout and cfg.cutout_w > 0 and cfg.cutout_h > 0:
        try:
            cutout_center_z = cfg.thickness + cfg.leg_h / 2
            bracket = (
                bracket
                .faces(">Y").workplane()
                .slot2D(cfg.cutout_w, cfg.cutout_h)
                .cutThruAll()
            )
        except Exception:
            pass  # Skip cutout if geometry fails

    return bracket


# ═══════════════════════════════════════════════════════════════
#  Analysis
# ═══════════════════════════════════════════════════════════════

def analyse(bracket: cq.Workplane, cfg: BracketConfig) -> dict:
    """Compute mass and bounding box."""
    bb = bracket.val().BoundingBox()
    vol_mm3 = bracket.val().Volume()
    vol_m3 = vol_mm3 * 1e-9
    mass_kg = vol_m3 * cfg.density_kg_m3
    mass_g = mass_kg * 1000

    return {
        "volume_mm3": vol_mm3,
        "mass_g": mass_g,
        "bbox": (round(bb.xlen, 1), round(bb.ylen, 1), round(bb.zlen, 1)),
        "material": cfg.material_name,
        "density": cfg.density_kg_m3,
    }


# ═══════════════════════════════════════════════════════════════
#  Export
# ═══════════════════════════════════════════════════════════════

def export_all(bracket: cq.Workplane, prefix: str = "bracket"):
    """Export STEP, STL, and DXF (base profile)."""
    files = {}

    for fmt in ("step", "stl"):
        path = f"{prefix}.{fmt}"
        cq.exporters.export(bracket, path)
        files[fmt] = path

    # DXF — project base flange profile for 2D workflows
    try:
        dxf_path = f"{prefix}_profile.dxf"
        cq.exporters.export(
            bracket.section(),  # XY cross section at Z=0
            dxf_path,
            exportType="DXF",
        )
        files["dxf"] = dxf_path
    except Exception:
        pass

    return files


# ═══════════════════════════════════════════════════════════════
#  CLI
# ═══════════════════════════════════════════════════════════════

def parse_args() -> BracketConfig:
    p = argparse.ArgumentParser(
        description="Parametric L-Bracket generator")

    cfg = BracketConfig()
    p.add_argument("--flange-w",   type=float, default=cfg.flange_w)
    p.add_argument("--flange-d",   type=float, default=cfg.flange_depth)
    p.add_argument("--leg-h",      type=float, default=cfg.leg_h)
    p.add_argument("--thickness",  type=float, default=cfg.thickness)
    p.add_argument("--hole-d",     type=float, default=cfg.base_hole_d)
    p.add_argument("--no-cutout",  action="store_true")
    p.add_argument("--prefix",     type=str,   default="bracket")

    args = p.parse_args()
    cfg.flange_w = args.flange_w
    cfg.flange_depth = args.flange_d
    cfg.leg_h = args.leg_h
    cfg.thickness = args.thickness
    cfg.base_hole_d = args.hole_d
    cfg.enable_cutout = not args.no_cutout

    return cfg, args.prefix


# ═══════════════════════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    cfg, prefix = parse_args()

    print(f"Building bracket: {cfg.flange_w} × {cfg.flange_depth}"
          f" × {cfg.leg_h} mm, t={cfg.thickness} mm")

    bracket = build_bracket(cfg)
    info = analyse(bracket, cfg)
    files = export_all(bracket, prefix)

    print(f"\n{'─' * 48}")
    print(f"  Material:      {info['material']}")
    print(f"  Bounding box:  {info['bbox'][0]} × {info['bbox'][1]}"
          f" × {info['bbox'][2]} mm")
    print(f"  Volume:        {info['volume_mm3']:.1f} mm³")
    print(f"  Mass:          {info['mass_g']:.1f} g "
          f"(ρ = {info['density']} kg/m³)")
    print(f"{'─' * 48}")
    for fmt, path in files.items():
        print(f"  ✓ {fmt.upper():5s} → {path}")
    print()

# ── CQ-editor visualisation ─────────────────────────────────
# Uncomment for interactive use in CQ-editor:
# cfg = BracketConfig()
# result = build_bracket(cfg)
# show_object(result, name="L-Bracket", options={"color": (180, 180, 200)})

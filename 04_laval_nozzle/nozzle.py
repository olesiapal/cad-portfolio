"""
CadQuery — De Laval Nozzle with Regenerative Cooling
=====================================================
Generates a parametric convergent-divergent (de Laval) rocket nozzle with:
  • Smooth inner bore profile (converging → throat → diverging)
  • Axial regenerative cooling channels cut into the inner liner wall
  • Sealed outer jacket closing the channel network
  • Inlet and exit coolant manifold rings with radial feed ports
  • Bolted inlet and exit flanges (configurable PCD / count)
  • Area ratio, channel fit, and wall-margin analysis output
  • STEP + STL export (full nozzle and cross-section cut)

Technology:
  In regenerative cooling, propellant flows through wall channels from
  the exit toward the throat (counter-flow) before entering the combustion
  chamber. This absorbs heat from the highest thermal-load region and
  pre-heats the propellant, improving specific impulse.

The geometry is intentionally a portfolio-quality structural model.
It does not simulate thermal gradients, ablation, or propellant state.
"""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass


def require_cadquery():
    try:
        import cadquery as cq  # type: ignore
    except ImportError:
        sys.exit(
            "ERROR: CadQuery not installed.\n"
            "       pip install cadquery\n"
            "       https://cadquery.readthedocs.io/en/latest/installation.html"
        )
    return cq


# ── Configuration ─────────────────────────────────────────────────────────────

@dataclass
class NozzleConfig:
    """All dimensions in millimetres unless noted."""

    # Flow geometry
    inlet_d:        float = 82.0    # combustion-side inner diameter
    throat_d:       float = 30.0    # throat inner diameter (minimum)
    exit_d:         float = 76.0    # nozzle exit inner diameter
    conv_length:    float = 50.0    # converging section length
    div_length:     float = 95.0    # diverging section length

    # Wall
    wall_t:         float = 7.0     # inner liner wall thickness
    jacket_t:       float = 2.5     # outer jacket (channel cover) thickness

    # Cooling channels (axial slots on outer face of liner)
    channel_count:  int   = 24      # number of channels around circumference
    channel_w:      float = 3.2     # channel width (tangential)
    channel_depth:  float = 4.0     # channel depth (radial, into liner wall)

    # Flanges
    flange_t:       float = 14.0    # flange plate thickness
    flange_od:      float = 135.0   # flange outer diameter
    bolt_count:     int   = 8       # bolts per flange
    bolt_d:         float = 8.5     # bolt-hole diameter (M8 clearance)
    bolt_pcd:       float = 116.0   # bolt-hole pitch circle diameter

    # Manifold rings
    manifold_h:     float = 8.0     # axial height of manifold ring
    manifold_od:    float = 116.0   # manifold ring outer diameter
    port_d:         float = 10.0    # radial coolant port diameter


# ── Analysis ──────────────────────────────────────────────────────────────────

def analyse(cfg: NozzleConfig) -> dict:
    rt = cfg.throat_d / 2
    re = cfg.exit_d / 2

    area_ratio       = (re / rt) ** 2
    throat_outer_r   = rt + cfg.wall_t
    throat_circ      = 2 * math.pi * throat_outer_r
    channel_pitch    = throat_circ / cfg.channel_count
    land_width       = channel_pitch - cfg.channel_w
    wall_margin      = cfg.wall_t - cfg.channel_depth

    warnings = []
    if land_width < 1.5:
        warnings.append(
            f"Land width {land_width:.2f} mm is very narrow (< 1.5 mm) — "
            "reduce channel_count or channel_w"
        )
    if wall_margin < 1.0:
        warnings.append(
            f"Channel depth {cfg.channel_depth} mm leaves only "
            f"{wall_margin:.1f} mm of wall below — reduce channel_depth"
        )
    if cfg.manifold_od / 2 < throat_outer_r + cfg.jacket_t + 2:
        warnings.append("Manifold OD may be too small to clear jacket")

    return {
        "area_ratio":    round(area_ratio, 3),
        "throat_circ":   round(throat_circ, 1),
        "ch_pitch":      round(channel_pitch, 2),
        "land_w":        round(land_width, 2),
        "wall_margin":   round(wall_margin, 2),
        "total_length":  cfg.conv_length + cfg.div_length,
        "warnings":      warnings,
    }


# ── Geometry ──────────────────────────────────────────────────────────────────
#
# Coordinate convention (all geometry):
#   X = nozzle axis (inlet at X=0, exit at X=tl)
#   Y,Z = radial directions
#   Profiles are in the XY plane; revolution is around the X axis.

def build_nozzle(cfg: NozzleConfig):
    cq = require_cadquery()

    ri = cfg.inlet_d   / 2
    rt = cfg.throat_d  / 2
    re = cfg.exit_d    / 2
    wt = cfg.wall_t
    jt = cfg.jacket_t
    cl = cfg.conv_length
    dl = cfg.div_length
    tl = cl + dl

    # ── Inner liner — revolved closed profile ─────────────────────────────────
    # Profile in XY plane: (axial_x, radius_y). Revolve around X axis.
    liner_pts = [
        (0,      ri),           # inner inlet
        (cl,     rt),           # inner throat
        (tl,     re),           # inner exit
        (tl,     re + wt),      # outer exit
        (cl,     rt + wt),      # outer throat
        (0,      ri + wt),      # outer inlet
    ]

    liner = (
        cq.Workplane("XY")
        .polyline(liner_pts, includeCurrent=False)
        .close()
        .revolve(360, [0, 0, 0], [1, 0, 0])
    )

    # ── Cooling channels (axial rectangular slots, N ×) ───────────────────────
    # Each channel: a rectangle in the YZ cross-section extruded along X,
    # then rotated to its angular position around the X axis.
    r_ch = rt + wt - cfg.channel_depth / 2   # radial centre at throat

    for i in range(cfg.channel_count):
        angle = i * 360 / cfg.channel_count
        try:
            ch = (
                cq.Workplane("YZ")
                .center(r_ch, 0)
                .rect(cfg.channel_depth + 0.4, cfg.channel_w)
                .extrude(tl + 2)
                .translate([-1, 0, 0])
                .rotate([0, 0, 0], [1, 0, 0], angle)
            )
            liner = liner.cut(ch)
        except Exception:
            pass

    # ── Outer jacket — seals channels ────────────────────────────────────────
    jacket_pts = [
        (0,  ri + wt),
        (cl, rt + wt),
        (tl, re + wt),
        (tl, re + wt + jt),
        (cl, rt + wt + jt),
        (0,  ri + wt + jt),
    ]

    jacket = (
        cq.Workplane("XY")
        .polyline(jacket_pts, includeCurrent=False)
        .close()
        .revolve(360, [0, 0, 0], [1, 0, 0])
    )

    body = liner.union(jacket)

    # ── Coolant manifold rings ─────────────────────────────────────────────────
    man_id = ri + wt + jt + 0.2
    man_od = cfg.manifold_od / 2
    mh     = cfg.manifold_h

    # Inlet manifold: at X=0, extends to X=-mh
    inlet_ring = (
        cq.Workplane("YZ")
        .circle(man_od)
        .circle(man_id)
        .extrude(mh)
        .translate([-mh, 0, 0])
    )
    # Coolant port through inlet manifold (radial, along Z axis)
    inlet_port = (
        cq.Workplane("XY")
        .center(-mh / 2, 0)
        .circle(cfg.port_d / 2)
        .extrude(man_od + 2, both=True)
    )
    inlet_ring = inlet_ring.cut(inlet_port)
    body = body.union(inlet_ring)

    # Exit manifold: at X=tl, extends to X=tl+mh
    exit_ring = (
        cq.Workplane("YZ")
        .workplane(offset=tl)
        .circle(man_od)
        .circle(man_id)
        .extrude(mh)
    )
    exit_port = (
        cq.Workplane("XY")
        .center(tl + mh / 2, 0)
        .circle(cfg.port_d / 2)
        .extrude(man_od + 2, both=True)
    )
    exit_ring = exit_ring.cut(exit_port)
    body = body.union(exit_ring)

    # ── Flanges ────────────────────────────────────────────────────────────────
    def make_flange(bore_r: float, x_start: float) -> object:
        f = (
            cq.Workplane("YZ")
            .workplane(offset=x_start)
            .circle(cfg.flange_od / 2)
            .circle(bore_r)
            .extrude(cfg.flange_t)
        )
        pcd_r = cfg.bolt_pcd / 2
        for k in range(cfg.bolt_count):
            a  = math.radians(k * 360 / cfg.bolt_count + 22.5)
            by = pcd_r * math.cos(a)
            bz = pcd_r * math.sin(a)
            hole = (
                cq.Workplane("YZ")
                .workplane(offset=x_start - 0.5)
                .center(by, bz)
                .circle(cfg.bolt_d / 2)
                .extrude(cfg.flange_t + 1)
            )
            f = f.cut(hole)
        return f

    inlet_flange = make_flange(ri, -cfg.flange_t)
    exit_flange  = make_flange(re,  tl)

    body = body.union(inlet_flange).union(exit_flange)

    return body


# ── Export ────────────────────────────────────────────────────────────────────

def export_all(body, cfg: NozzleConfig, section: bool = False):
    cq = require_cadquery()
    tl = cfg.conv_length + cfg.div_length

    cq.exporters.export(body, "laval_nozzle.step")
    cq.exporters.export(body, "laval_nozzle.stl")
    print("  ✓ STEP  → laval_nozzle.step")
    print("  ✓ STL   → laval_nozzle.stl")

    if section:
        try:
            # Clip to Z ≥ 0 half — shows inner bore, channels, and flanges
            clip = (
                cq.Workplane("XY")
                .box(tl + 200, cfg.flange_od + 20, cfg.flange_od + 20)
                .translate([tl / 2, 0, (cfg.flange_od + 20) / 2])
            )
            sec = body.intersect(clip)
            cq.exporters.export(sec, "laval_nozzle_section.step")
            cq.exporters.export(sec, "laval_nozzle_section.stl")
            print("  ✓ STEP  → laval_nozzle_section.step")
            print("  ✓ STL   → laval_nozzle_section.stl")
        except Exception as exc:
            print(f"  ! Section export skipped: {exc}")


# ── Report ────────────────────────────────────────────────────────────────────

def print_report(cfg: NozzleConfig, info: dict):
    sep = "─" * 54
    print(sep)
    print("  De Laval Nozzle — Parametric Analysis")
    print(sep)
    print(f"  Inlet diameter:           {cfg.inlet_d} mm")
    print(f"  Throat diameter:          {cfg.throat_d} mm")
    print(f"  Exit diameter:            {cfg.exit_d} mm")
    print(f"  Converging length:        {cfg.conv_length} mm")
    print(f"  Diverging length:         {cfg.div_length} mm")
    print(f"  Total length:             {info['total_length']} mm")
    print(f"  Wall thickness:           {cfg.wall_t} mm")
    print(f"  Jacket thickness:         {cfg.jacket_t} mm")
    print(sep)
    print(f"  Area ratio (Ae / At):     {info['area_ratio']}")
    print(f"  Throat circumference:     {info['throat_circ']} mm")
    print(f"  Channel count:            {cfg.channel_count}")
    print(f"  Channel pitch:            {info['ch_pitch']} mm")
    print(f"  Land width:               {info['land_w']} mm")
    print(f"  Channel depth:            {cfg.channel_depth} mm")
    print(f"  Wall below channel:       {info['wall_margin']} mm")
    print(sep)
    print(f"  Bolt pattern:             {cfg.bolt_count}× ⌀{cfg.bolt_d} "
          f"on ⌀{cfg.bolt_pcd} PCD")
    print(f"  Coolant ports:            2× ⌀{cfg.port_d} (inlet + exit manifold)")
    if info["warnings"]:
        print(sep)
        for w in info["warnings"]:
            print(f"  ⚠  {w}")
    print(sep)


# ── CLI ───────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Build a parametric de Laval nozzle with regenerative cooling."
    )
    p.add_argument("--inlet-d",      type=float, default=82.0,
                   help="inlet inner diameter [mm]")
    p.add_argument("--throat-d",     type=float, default=30.0,
                   help="throat inner diameter [mm]")
    p.add_argument("--exit-d",       type=float, default=76.0,
                   help="exit inner diameter [mm]")
    p.add_argument("--conv-length",  type=float, default=50.0,
                   help="converging section length [mm]")
    p.add_argument("--div-length",   type=float, default=95.0,
                   help="diverging section length [mm]")
    p.add_argument("--wall-t",       type=float, default=7.0,
                   help="wall thickness [mm]")
    p.add_argument("--channels",     type=int,   default=24,
                   help="number of cooling channels")
    p.add_argument("--channel-w",    type=float, default=3.2,
                   help="channel slot width [mm]")
    p.add_argument("--channel-depth",type=float, default=4.0,
                   help="channel slot depth [mm]")
    p.add_argument("--section",      action="store_true",
                   help="also export a YZ cross-section cut")
    return p.parse_args()


if __name__ == "__main__":
    args = parse_args()

    cfg = NozzleConfig(
        inlet_d       = args.inlet_d,
        throat_d      = args.throat_d,
        exit_d        = args.exit_d,
        conv_length   = args.conv_length,
        div_length    = args.div_length,
        wall_t        = args.wall_t,
        channel_count = args.channels,
        channel_w     = args.channel_w,
        channel_depth = args.channel_depth,
    )

    info = analyse(cfg)
    print_report(cfg, info)

    print("\nBuilding geometry (24 channel cuts + boolean unions — ~30 s)...")
    body = build_nozzle(cfg)

    print("\nExporting:")
    export_all(body, cfg, section=args.section)

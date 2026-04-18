"""
CadQuery — Structural Bracket Family
====================================
Generates a fabrication-oriented L-bracket with:
  • True inner bend radius in the base profile
  • Dual gusset ribs for stiffness near the bend
  • Round or slotted base mounting holes
  • Multi-row leg holes
  • Rounded lightening cutout with real corner radius
  • Mass estimation and lightweight load-case output
  • STEP + STL + DXF export

The load estimate is intentionally simple and conservative. It is a
portfolio-quality screening calculation, not a substitute for FEA.
"""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from typing import Any


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


@dataclass
class BracketConfig:
    """All dimensions in millimetres unless noted."""

    flange_w: float = 100.0
    flange_depth: float = 60.0
    leg_h: float = 60.0
    thickness: float = 6.0

    fillet_r: float = 1.5
    inner_fillet_r: float = 4.0

    gusset_depth: float = 34.0
    gusset_thickness: float = 0.0

    base_hole_type: str = "round"  # round / slot
    base_hole_d: float = 8.5
    base_cbore_d: float = 14.0
    base_cbore_depth: float = 3.0
    base_slot_len: float = 20.0
    base_hole_margin_x: float = 20.0
    base_hole_margin_y: float = 15.0

    leg_hole_d: float = 6.5
    leg_hole_margin_x: float = 20.0
    leg_hole_z_from_base: float = 14.0
    leg_hole_rows: int = 2
    leg_hole_row_pitch: float = 32.0

    enable_cutout: bool = True
    cutout_w: float = 34.0
    cutout_h: float = 24.0
    cutout_fillet: float = 6.0

    material_name: str = "Al 6061-T6"
    density_kg_m3: float = 2710.0
    youngs_gpa: float = 69.0
    yield_mpa: float = 276.0
    tip_load_n: float = 250.0

    @property
    def gusset_t(self) -> float:
        return self.gusset_thickness or self.thickness

    @property
    def total_h(self) -> float:
        return self.thickness + self.leg_h


def validate_config(cfg: BracketConfig) -> None:
    if cfg.base_hole_type not in {"round", "slot"}:
        raise ValueError("base_hole_type must be 'round' or 'slot'")
    if cfg.flange_w <= 0 or cfg.flange_depth <= 0 or cfg.leg_h <= 0:
        raise ValueError("Main bracket dimensions must be positive")
    if cfg.thickness <= 0:
        raise ValueError("thickness must be positive")
    if cfg.inner_fillet_r < 0:
        raise ValueError("inner_fillet_r cannot be negative")
    if cfg.base_hole_margin_x >= cfg.flange_w / 2:
        raise ValueError("base_hole_margin_x is too large for the flange width")
    if cfg.base_hole_margin_y >= cfg.flange_depth / 2:
        raise ValueError("base_hole_margin_y is too large for the flange depth")
    if cfg.base_hole_d >= min(cfg.flange_w, cfg.flange_depth):
        raise ValueError("base_hole_d is not compatible with the flange size")
    if cfg.base_hole_type == "slot" and cfg.base_slot_len <= cfg.base_hole_d:
        raise ValueError("base_slot_len must be larger than base_hole_d")
    if cfg.cutout_fillet * 2 >= min(cfg.cutout_w, cfg.cutout_h):
        raise ValueError("cutout_fillet is too large for the requested cutout size")
    if cfg.leg_hole_rows >= 2:
        top_row = cfg.thickness + cfg.leg_hole_z_from_base + cfg.leg_hole_row_pitch
        if top_row >= cfg.total_h - 4:
            raise ValueError("Second leg-hole row does not fit inside the default leg height")


def make_base_blank(cq: Any, cfg: BracketConfig):
    hd = cfg.flange_depth / 2
    t = cfg.thickness
    r = min(cfg.inner_fillet_r, t - 0.2, cfg.leg_h / 2)

    profile = (
        cq.Workplane("YZ")
        .moveTo(-hd, 0)
        .lineTo(hd, 0)
        .lineTo(hd, cfg.total_h)
        .lineTo(hd - t, cfg.total_h)
    )

    if r > 0.01:
        profile = (
            profile
            .lineTo(hd - t, t + r)
            .threePointArc((hd - t, t), (hd - t - r, t))
        )
    else:
        profile = profile.lineTo(hd - t, t)

    profile = profile.lineTo(-hd, t).close()

    return profile.extrude(cfg.flange_w / 2, both=True)


def make_gusset(cq: Any, cfg: BracketConfig, x_center: float):
    inner_face_y = cfg.flange_depth / 2 - cfg.thickness
    top_z = cfg.thickness
    rise = min(cfg.gusset_depth, cfg.leg_h - 4)
    run = min(cfg.gusset_depth, cfg.flange_depth - cfg.thickness - 4)

    gusset = (
        cq.Workplane("YZ")
        .polyline(
            [
                (inner_face_y, top_z),
                (inner_face_y - run, top_z),
                (inner_face_y, top_z + rise),
            ]
        )
        .close()
        .extrude(cfg.gusset_t / 2, both=True)
        .translate((x_center, 0, 0))
    )

    return gusset


def base_hole_positions(cfg: BracketConfig) -> list[tuple[float, float]]:
    hw = cfg.flange_w / 2
    hd = cfg.flange_depth / 2

    return [
        (-hw + cfg.base_hole_margin_x, -hd + cfg.base_hole_margin_y),
        (hw - cfg.base_hole_margin_x, -hd + cfg.base_hole_margin_y),
        (-hw + cfg.base_hole_margin_x, hd - cfg.base_hole_margin_y),
        (hw - cfg.base_hole_margin_x, hd - cfg.base_hole_margin_y),
    ]


def leg_hole_positions(cfg: BracketConfig) -> list[tuple[float, float]]:
    hw = cfg.flange_w / 2
    rows = []

    first_row_z = cfg.thickness + cfg.leg_hole_z_from_base
    rows.append(first_row_z)
    if cfg.leg_hole_rows >= 2:
        rows.append(first_row_z + cfg.leg_hole_row_pitch)

    return [
        (x, z)
        for z in rows
        for x in (-hw + cfg.leg_hole_margin_x, hw - cfg.leg_hole_margin_x)
    ]


def make_slot_cutter_xy(
    cq: Any,
    x_center: float,
    y_center: float,
    z0: float,
    depth: float,
    slot_len: float,
    slot_d: float,
    axis: str = "y",
):
    radius = slot_d / 2
    straight = max(slot_len - slot_d, 0.1)

    if axis == "x":
        box = (
            cq.Workplane("XY")
            .box(straight, slot_d, depth, centered=(True, True, False))
            .translate((x_center, y_center, z0))
        )
        ends = [
            (x_center - straight / 2, y_center),
            (x_center + straight / 2, y_center),
        ]
    else:
        box = (
            cq.Workplane("XY")
            .box(slot_d, straight, depth, centered=(True, True, False))
            .translate((x_center, y_center, z0))
        )
        ends = [
            (x_center, y_center - straight / 2),
            (x_center, y_center + straight / 2),
        ]

    cutter = box
    for end_x, end_y in ends:
        cutter = cutter.union(
            cq.Workplane("XY")
            .center(end_x, end_y)
            .circle(radius)
            .extrude(depth)
            .translate((0, 0, z0))
        )

    return cutter


def make_base_hole_cutters(cq: Any, cfg: BracketConfig):
    cutters = None

    for x_pos, y_pos in base_hole_positions(cfg):
        if cfg.base_hole_type == "round":
            through = (
                cq.Workplane("XY")
                .center(x_pos, y_pos)
                .circle(cfg.base_hole_d / 2)
                .extrude(cfg.thickness + 2)
                .translate((0, 0, -1))
            )
            counterbore = (
                cq.Workplane("XY")
                .center(x_pos, y_pos)
                .circle(cfg.base_cbore_d / 2)
                .extrude(cfg.base_cbore_depth + 0.2)
                .translate((0, 0, cfg.thickness - cfg.base_cbore_depth))
            )
            cutter = through.union(counterbore)
        else:
            cutter = make_slot_cutter_xy(
                cq,
                x_center=x_pos,
                y_center=y_pos,
                z0=-1,
                depth=cfg.thickness + 2,
                slot_len=cfg.base_slot_len,
                slot_d=cfg.base_hole_d,
                axis="y",
            )

        cutters = cutter if cutters is None else cutters.union(cutter)

    return cutters


def make_leg_hole_cutters(cq: Any, cfg: BracketConfig):
    y_center = cfg.flange_depth / 2 - cfg.thickness / 2
    depth = cfg.thickness + 2
    cutters = None

    for x_pos, z_pos in leg_hole_positions(cfg):
        cutter = (
            cq.Workplane("XZ")
            .center(x_pos, z_pos)
            .circle(cfg.leg_hole_d / 2)
            .extrude(depth)
            .translate((0, y_center - depth / 2, 0))
        )
        cutters = cutter if cutters is None else cutters.union(cutter)

    return cutters


def make_cutout_cutter(cq: Any, cfg: BracketConfig):
    if not cfg.enable_cutout:
        return None

    radius = cfg.cutout_fillet
    width = cfg.cutout_w
    height = cfg.cutout_h
    depth = cfg.thickness + 2
    y_center = cfg.flange_depth / 2 - cfg.thickness / 2
    z_center = cfg.thickness + cfg.leg_h / 2

    solid = (
        cq.Workplane("XY")
        .box(max(width - radius * 2, 0.1), depth, height, centered=(True, True, True))
        .translate((0, y_center, z_center))
    )
    solid = solid.union(
        cq.Workplane("XY")
        .box(width, depth, max(height - radius * 2, 0.1), centered=(True, True, True))
        .translate((0, y_center, z_center))
    )

    for x_pos in (-width / 2 + radius, width / 2 - radius):
        for z_pos in (-height / 2 + radius, height / 2 - radius):
            solid = solid.union(
                cq.Workplane("XZ")
                .center(x_pos, z_center + z_pos)
                .circle(radius)
                .extrude(depth)
                .translate((0, y_center - depth / 2, 0))
            )

    return solid


def build_bracket(cfg: BracketConfig):
    cq = require_cadquery()
    validate_config(cfg)

    bracket = make_base_blank(cq, cfg)

    left_gusset = make_gusset(cq, cfg, -cfg.flange_w / 2 + cfg.gusset_t / 2)
    right_gusset = make_gusset(cq, cfg, cfg.flange_w / 2 - cfg.gusset_t / 2)
    bracket = bracket.union(left_gusset).union(right_gusset)

    base_cutters = make_base_hole_cutters(cq, cfg)
    if base_cutters is not None:
        bracket = bracket.cut(base_cutters)

    leg_cutters = make_leg_hole_cutters(cq, cfg)
    if leg_cutters is not None:
        bracket = bracket.cut(leg_cutters)

    cutout_cutter = make_cutout_cutter(cq, cfg)
    if cutout_cutter is not None:
        bracket = bracket.cut(cutout_cutter)

    try:
        bracket = bracket.edges("|X").fillet(cfg.fillet_r)
    except Exception:
        pass

    return bracket


def estimate_tip_load(cfg: BracketConfig) -> dict[str, float] | None:
    if cfg.tip_load_n <= 0:
        return None

    load_n = cfg.tip_load_n
    span_m = cfg.leg_h / 1000
    width_m = cfg.flange_w / 1000
    thickness_m = cfg.thickness / 1000
    elastic_modulus_pa = cfg.youngs_gpa * 1e9

    inertia_m4 = width_m * thickness_m**3 / 12
    moment_nm = load_n * span_m
    outer_fibre_m = thickness_m / 2
    stress_mpa = (moment_nm * outer_fibre_m / inertia_m4) / 1e6
    deflection_mm = (
        load_n * span_m**3 / (3 * elastic_modulus_pa * inertia_m4)
    ) * 1000
    safety_factor = math.inf if stress_mpa <= 0 else cfg.yield_mpa / stress_mpa

    return {
        "tip_load_n": load_n,
        "root_moment_nm": moment_nm,
        "stress_mpa": stress_mpa,
        "deflection_mm": deflection_mm,
        "safety_factor": safety_factor,
    }


def analyse(bracket: Any, cfg: BracketConfig) -> dict[str, Any]:
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
        "load_case": estimate_tip_load(cfg),
    }


def export_all(bracket: Any, prefix: str = "bracket") -> dict[str, str]:
    cq = require_cadquery()
    files: dict[str, str] = {}

    for fmt in ("step", "stl"):
        path = f"{prefix}.{fmt}"
        cq.exporters.export(bracket, path)
        files[fmt] = path

    try:
        dxf_path = f"{prefix}_profile.dxf"
        cq.exporters.export(
            bracket.section(),
            dxf_path,
            exportType="DXF",
        )
        files["dxf"] = dxf_path
    except Exception:
        pass

    return files


def parse_args() -> tuple[BracketConfig, str]:
    cfg = BracketConfig()
    parser = argparse.ArgumentParser(description="Structural bracket family generator")

    parser.add_argument("--flange-w", type=float, default=cfg.flange_w)
    parser.add_argument("--flange-d", type=float, default=cfg.flange_depth)
    parser.add_argument("--leg-h", type=float, default=cfg.leg_h)
    parser.add_argument("--thickness", type=float, default=cfg.thickness)
    parser.add_argument("--inner-fillet-r", type=float, default=cfg.inner_fillet_r)
    parser.add_argument("--hole-d", type=float, default=cfg.base_hole_d)
    parser.add_argument("--base-hole-type", choices=("round", "slot"), default=cfg.base_hole_type)
    parser.add_argument("--base-slot-len", type=float, default=cfg.base_slot_len)
    parser.add_argument("--leg-hole-rows", type=int, choices=(1, 2), default=cfg.leg_hole_rows)
    parser.add_argument("--tip-load-n", type=float, default=cfg.tip_load_n)
    parser.add_argument("--no-cutout", action="store_true")
    parser.add_argument("--prefix", type=str, default="bracket")

    args = parser.parse_args()
    cfg.flange_w = args.flange_w
    cfg.flange_depth = args.flange_d
    cfg.leg_h = args.leg_h
    cfg.thickness = args.thickness
    cfg.inner_fillet_r = args.inner_fillet_r
    cfg.base_hole_d = args.hole_d
    cfg.base_hole_type = args.base_hole_type
    cfg.base_slot_len = args.base_slot_len
    cfg.leg_hole_rows = args.leg_hole_rows
    cfg.tip_load_n = args.tip_load_n
    cfg.enable_cutout = not args.no_cutout

    return cfg, args.prefix


def main() -> None:
    cfg, prefix = parse_args()
    bracket = build_bracket(cfg)
    info = analyse(bracket, cfg)
    files = export_all(bracket, prefix)

    print(
        f"Building bracket family member: {cfg.flange_w} × {cfg.flange_depth}"
        f" × {cfg.leg_h} mm, t={cfg.thickness} mm"
    )
    print(f"Base hole type: {cfg.base_hole_type}")
    print(f"Inner bend radius: {cfg.inner_fillet_r} mm")

    print(f"\n{'─' * 52}")
    print(f"  Material:      {info['material']}")
    print(f"  Bounding box:  {info['bbox'][0]} × {info['bbox'][1]} × {info['bbox'][2]} mm")
    print(f"  Volume:        {info['volume_mm3']:.1f} mm³")
    print(f"  Mass:          {info['mass_g']:.1f} g (ρ = {info['density']} kg/m³)")

    if info["load_case"] is not None:
        load = info["load_case"]
        print(f"{'─' * 52}")
        print(f"  Load case:     tip load on leg = {load['tip_load_n']:.1f} N")
        print(f"  Root moment:   {load['root_moment_nm']:.2f} N·m")
        print(f"  Stress:        {load['stress_mpa']:.1f} MPa")
        print(f"  Deflection:    {load['deflection_mm']:.3f} mm")
        print(f"  Safety factor: {load['safety_factor']:.2f}")

    print(f"{'─' * 52}")
    for fmt, path in files.items():
        print(f"  ✓ {fmt.upper():5s} → {path}")
    print()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Drone Frame — Manufacturing Handoff Drawing
Generates an A3 technical drawing (DXF R2010) for a parametric
X-configuration quadcopter frame.

Requirements: ezdxf >= 1.0   (pip install ezdxf)
Usage:        python3 generate_drone_drawing.py
Output:       drone_frame.dxf
"""

import math
import ezdxf
from ezdxf import units
from ezdxf.enums import TextEntityAlignment

# ── Frame Parameters ─────────────────────────────────────────
ARM_LENGTH      = 85      # centre → motor-mount centre [mm]
ARM_WIDTH       = 20      # arm width [mm]
CENTER_OD       = 52      # centre-plate outer diameter [mm]
CENTER_ID       = 28      # weight-reduction inner circle diameter [mm]
FC_MOUNT        = 30.5    # FC hole pattern (square spacing) [mm]
MOTOR_PATTERN   = 16      # motor bolt pattern (square side) [mm]
MOTOR_BELL_D    = 28      # motor bell clearance circle [mm]
D_MOTOR_BOLT    = 2.5     # motor mount hole diameter [mm]
D_FC_BOLT       = 3.2     # FC/stack bolt hole diameter [mm]
D_ARM_HOLE      = 5.0     # arm lightening hole diameter [mm]
FRAME_T         = 4.0     # carbon plate thickness [mm]

# ── Sheet & View Layout (A3 landscape, mm) ───────────────────
SHEET_W, SHEET_H = 420, 297
MARGIN           = 10

TOP_CENTER    = (148, 175)   # top view origin
SIDE_CENTER   = (148,  52)   # side/profile view origin
DETAIL_CENTER = (345, 195)   # motor-mount detail (2× scale)
DETAIL_SCALE  = 2.0
TITLE_ORIGIN  = (272,  10)   # title block bottom-left

# ── Geometry helpers ─────────────────────────────────────────

def arm_outline(angle_deg, length, width):
    """4-corner outline of one arm, origin at frame centre."""
    a  = math.radians(angle_deg)
    px, py =  math.cos(a),  math.sin(a)
    nx, ny = -math.sin(a),  math.cos(a)
    hw = width / 2
    r0 = CENTER_OD / 2
    return [
        (px * r0 + nx * hw,  py * r0 + ny * hw),
        (px * r0 - nx * hw,  py * r0 - ny * hw),
        (px * length - nx * hw, py * length - ny * hw),
        (px * length + nx * hw, py * length + ny * hw),
    ]

def motor_centre(angle_deg, length):
    a = math.radians(angle_deg)
    return math.cos(a) * length, math.sin(a) * length

def offset(pts, dx, dy):
    return [(x + dx, y + dy) for x, y in pts]

def add_text(msp, text, pos, height=3.5, layer="NOTES",
             align=TextEntityAlignment.LEFT, style="DRAWING"):
    msp.add_text(
        text,
        dxfattribs={"layer": layer, "height": height, "style": style},
    ).set_placement(pos, align=align)

# ── Main builder ─────────────────────────────────────────────

def build_drawing():
    doc = ezdxf.new("R2010", setup=True)
    doc.units = units.MM
    msp = doc.modelspace()

    # Layers
    doc.layers.add("OUTLINE",     color=7,  lineweight=50)
    doc.layers.add("CENTERLINE",  color=1,  lineweight=13,
                   linetype="CENTER")
    doc.layers.add("DIMENSION",   color=5,  lineweight=13)
    doc.layers.add("HIDDEN",      color=3,  lineweight=13,
                   linetype="DASHED")
    doc.layers.add("TITLE_BLOCK", color=7,  lineweight=35)
    doc.layers.add("NOTES",       color=2,  lineweight=13)

    doc.styles.add("DRAWING", font="Arial")

    OL  = {"layer": "OUTLINE",     "lineweight": 50}
    OLt = {"layer": "OUTLINE",     "lineweight": 35}
    OLh = {"layer": "OUTLINE",     "lineweight": 25}
    CL  = {"layer": "CENTERLINE"}
    TB  = {"layer": "TITLE_BLOCK", "lineweight": 35}

    # ── Sheet border ─────────────────────────────────────────
    msp.add_lwpolyline(
        [(MARGIN, MARGIN), (SHEET_W - MARGIN, MARGIN),
         (SHEET_W - MARGIN, SHEET_H - MARGIN), (MARGIN, SHEET_H - MARGIN)],
        close=True, dxfattribs={"layer": "TITLE_BLOCK", "lineweight": 60},
    )

    # ── TOP VIEW ─────────────────────────────────────────────
    ox, oy = TOP_CENTER

    # Centre plate
    msp.add_circle((ox, oy), CENTER_OD / 2, dxfattribs=OL)
    msp.add_circle((ox, oy), CENTER_ID / 2, dxfattribs=OLt)

    # 4 Arms
    for ang in [45, 135, 225, 315]:
        pts = offset(arm_outline(ang, ARM_LENGTH, ARM_WIDTH), ox, oy)
        msp.add_lwpolyline(pts, close=True, dxfattribs=OL)

    # Motor mounts
    for ang in [45, 135, 225, 315]:
        mx, my = motor_centre(ang, ARM_LENGTH)
        cx, cy = ox + mx, oy + my

        msp.add_circle((cx, cy), MOTOR_BELL_D / 2, dxfattribs=OLt)

        hp = MOTOR_PATTERN / 2
        for bx, by in [(hp, hp), (hp, -hp), (-hp, hp), (-hp, -hp)]:
            msp.add_circle((cx + bx, cy + by), D_MOTOR_BOLT / 2,
                           dxfattribs=OLh)

        ext = MOTOR_BELL_D / 2 + 6
        msp.add_line((cx - ext, cy), (cx + ext, cy), dxfattribs=CL)
        msp.add_line((cx, cy - ext), (cx, cy + ext), dxfattribs=CL)

    # FC mount holes
    hp = FC_MOUNT / 2
    for bx, by in [(hp, hp), (hp, -hp), (-hp, hp), (-hp, -hp)]:
        msp.add_circle((ox + bx, oy + by), D_FC_BOLT / 2, dxfattribs=OLh)

    # Arm lightening holes (mid-arm)
    for ang in [45, 135, 225, 315]:
        mx, my = motor_centre(ang, ARM_LENGTH * 0.58)
        msp.add_circle((ox + mx, oy + my), D_ARM_HOLE / 2, dxfattribs=OLh)

    # Frame centre crosshair
    span = ARM_LENGTH + 18
    msp.add_line((ox - span, oy), (ox + span, oy), dxfattribs=CL)
    msp.add_line((ox, oy - span), (ox, oy + span), dxfattribs=CL)
    diag = span * math.cos(math.radians(45))
    msp.add_line((ox - diag, oy - diag), (ox + diag, oy + diag), dxfattribs=CL)
    msp.add_line((ox - diag, oy + diag), (ox + diag, oy - diag), dxfattribs=CL)

    # ── Dimensions (top view) ─────────────────────────────────
    dstyle_over = {"dimtxt": 2.8, "dimasz": 2.2, "dimlayer": "DIMENSION",
                   "dimexo": 1.5, "dimexe": 2.0}

    # Motor-to-motor diagonal (wheelbase)
    m45  = (ox + motor_centre(45,  ARM_LENGTH)[0],
            oy + motor_centre(45,  ARM_LENGTH)[1])
    m225 = (ox + motor_centre(225, ARM_LENGTH)[0],
            oy + motor_centre(225, ARM_LENGTH)[1])
    d = msp.add_aligned_dim(p1=m45, p2=m225, distance=14,
                             dimstyle="EZDXF", override=dstyle_over)
    d.render()

    # Arm width
    corners = offset(arm_outline(45, ARM_LENGTH, ARM_WIDTH), ox, oy)
    d2 = msp.add_aligned_dim(p1=corners[0], p2=corners[1], distance=6,
                              dimstyle="EZDXF", override=dstyle_over)
    d2.render()

    # Centre plate diameter
    d3 = msp.add_diameter_dim(center=(ox, oy), radius=CENTER_OD / 2,
                               angle=145, dimstyle="EZDXF",
                               override=dstyle_over)
    d3.render()

    # FC mount pattern
    d4 = msp.add_linear_dim(
        base=(ox, oy + CENTER_OD / 2 + 16),
        p1=(ox - FC_MOUNT / 2, oy + FC_MOUNT / 2),
        p2=(ox + FC_MOUNT / 2, oy + FC_MOUNT / 2),
        dimstyle="EZDXF", override=dstyle_over,
    )
    d4.render()

    add_text(msp, "TOP VIEW — 1:1",
             (ox, oy - ARM_LENGTH - 22), height=4,
             align=TextEntityAlignment.CENTER)

    # ── SIDE VIEW (frame profile) ─────────────────────────────
    sx, sy = SIDE_CENTER
    half = ARM_LENGTH + 10

    for y_off in [FRAME_T / 2, -FRAME_T / 2]:
        msp.add_line((sx - half, sy + y_off), (sx + half, sy + y_off),
                     dxfattribs=OL)
    msp.add_line((sx - half, sy - FRAME_T / 2),
                 (sx - half, sy + FRAME_T / 2), dxfattribs=OL)
    msp.add_line((sx + half, sy - FRAME_T / 2),
                 (sx + half, sy + FRAME_T / 2), dxfattribs=OL)
    msp.add_line((sx - half - 5, sy), (sx + half + 5, sy), dxfattribs=CL)

    # Thickness
    d5 = msp.add_linear_dim(
        base=(sx + half + 16, sy),
        p1=(sx + half, sy - FRAME_T / 2),
        p2=(sx + half, sy + FRAME_T / 2),
        angle=90, dimstyle="EZDXF", override=dstyle_over,
    )
    d5.render()

    # Overall span
    d6 = msp.add_linear_dim(
        base=(sx, sy - FRAME_T / 2 - 12),
        p1=(sx - half, sy - FRAME_T / 2),
        p2=(sx + half, sy - FRAME_T / 2),
        dimstyle="EZDXF", override=dstyle_over,
    )
    d6.render()

    add_text(msp, "SIDE VIEW — 1:1",
             (sx, sy - FRAME_T / 2 - 24), height=4,
             align=TextEntityAlignment.CENTER)

    # ── MOTOR MOUNT DETAIL (2:1) ──────────────────────────────
    dx, dy = DETAIL_CENTER
    s = DETAIL_SCALE

    msp.add_circle((dx, dy), MOTOR_BELL_D / 2 * s, dxfattribs=OL)

    hp = MOTOR_PATTERN / 2 * s
    for bx, by in [(hp, hp), (hp, -hp), (-hp, hp), (-hp, -hp)]:
        msp.add_circle((dx + bx, dy + by), D_MOTOR_BOLT / 2 * s,
                       dxfattribs=OLt)

    ext = MOTOR_BELL_D / 2 * s + 10
    msp.add_line((dx - ext, dy), (dx + ext, dy), dxfattribs=CL)
    msp.add_line((dx, dy - ext), (dx, dy + ext), dxfattribs=CL)

    # Pattern dimension (at 2× scale)
    d7 = msp.add_linear_dim(
        base=(dx, dy + MOTOR_BELL_D / 2 * s + 14),
        p1=(dx - hp, dy + hp), p2=(dx + hp, dy + hp),
        dimstyle="EZDXF", override=dstyle_over,
    )
    d7.render()

    add_text(msp, "DETAIL A — MOTOR MOUNT  2:1",
             (dx, dy - MOTOR_BELL_D / 2 * s - 16), height=4,
             align=TextEntityAlignment.CENTER)

    # Detail callout bubble in top view
    m45x = ox + motor_centre(45, ARM_LENGTH)[0]
    m45y = oy + motor_centre(45, ARM_LENGTH)[1]
    msp.add_circle((m45x + 18, m45y + 10), 6,
                   dxfattribs={"layer": "NOTES", "lineweight": 25})
    add_text(msp, "A", (m45x + 18, m45y + 7), height=5,
             align=TextEntityAlignment.CENTER, layer="NOTES")
    msp.add_line((m45x + 14, m45y + 8), (m45x + 8, m45y + 2),
                 dxfattribs={"layer": "NOTES", "lineweight": 25})

    # ── TITLE BLOCK ───────────────────────────────────────────
    tx, ty = TITLE_ORIGIN
    tb_w, tb_h = 138, 56

    msp.add_lwpolyline(
        [(tx, ty), (tx + tb_w, ty), (tx + tb_w, ty + tb_h), (tx, ty + tb_h)],
        close=True, dxfattribs=TB,
    )

    for y_row in [12, 24, 36, 48]:
        msp.add_line((tx, ty + y_row), (tx + tb_w, ty + y_row), dxfattribs=TB)
    msp.add_line((tx + 70, ty), (tx + 70, ty + 36), dxfattribs=TB)

    def tbt(text, rx, ry, h=3.5):
        add_text(msp, text, (tx + rx, ty + ry), height=h,
                 layer="NOTES", align=TextEntityAlignment.LEFT)

    tbt("TITLE:",                                    2, tb_h - 5,  h=2.5)
    tbt("Quadcopter Frame — Manufacturing Drawing",  2, tb_h - 11, h=4.2)
    tbt("MATERIAL:",                                 2, 40,        h=2.5)
    tbt("3K Carbon Fibre  t = 4.0 mm",               2, 34,        h=3.5)
    tbt("DRAWN BY:",                                 2, 27,        h=2.5)
    tbt("VB CAD Portfolio",                          2, 21,        h=3.5)
    tbt("DATE:",                                     72, 27,       h=2.5)
    tbt("2026-04-19",                                72, 21,       h=3.5)
    tbt("SCALE:",                                    2, 15,        h=2.5)
    tbt("1:1  (Detail A: 2:1)",                      2, 9,         h=3.5)
    tbt("FORMAT:",                                   72, 15,       h=2.5)
    tbt("A3 — ISO",                                  72, 9,        h=3.5)
    tbt("DWG No:",                                   2, 3,         h=2.5)
    tbt("VB-DRN-003  Rev A",                         2, -4,        h=3.5)

    # ── General notes ─────────────────────────────────────────
    notes = [
        "GENERAL NOTES:",
        "1. All dimensions in millimetres unless stated.",
        "2. Material: 3K plain-weave carbon fibre, t = 4.0 mm.",
        "3. Hole tolerances: ±0.1 mm. Outline: ±0.2 mm.",
        "4. Motor mount: M2.5 × 4 bolts, 16 mm square pattern.",
        "5. FC mount: M3 × 4 bolts, 30.5 mm square pattern.",
        "6. Deburr all cut edges. Do not sand fibre faces.",
    ]
    for i, note in enumerate(notes):
        add_text(msp, note, (tx, ty + tb_h + 9 + i * 6.0),
                 height=3.2, layer="NOTES")

    # Sheet title
    add_text(msp, "VB CAD PORTFOLIO — DRONE FRAME MANUFACTURING DRAWING",
             (MARGIN + 4, SHEET_H - MARGIN - 7), height=5,
             layer="TITLE_BLOCK")

    return doc


# ── Run ───────────────────────────────────────────────────────
if __name__ == "__main__":
    doc = build_drawing()
    out_path = "drone_frame.dxf"
    doc.saveas(out_path)

    diag_mm = round(ARM_LENGTH * 2 * math.sqrt(2), 1)
    print(f"Saved → {out_path}")
    print(f"Motor-to-motor diagonal:  {diag_mm} mm  ({round(diag_mm / 25.4, 2)}\")")
    print(f"Arm length:               {ARM_LENGTH} mm")
    print(f"Centre plate OD:          {CENTER_OD} mm")
    print(f"Motor bolt pattern:       {MOTOR_PATTERN} × {MOTOR_PATTERN} mm (M2.5)")
    print(f"FC mount pattern:         {FC_MOUNT} × {FC_MOUNT} mm (M3)")
    print(f"Frame thickness:          {FRAME_T} mm")

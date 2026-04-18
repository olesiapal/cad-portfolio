// ============================================================
//  PCB-Driven Electronics Enclosure Generator — OpenSCAD
//  Author:  olesiapal
//  Version: 3.0
//  License: MIT
//
//  Highlights:
//    • PCB mount pattern drives standoff placement
//    • Closure modes: snap or screw-fastened lid
//    • Rear / front / left / right cutout arrays
//    • Optional gasket groove for sealing concept studies
//    • Exploded and cross-section preview modes
// ============================================================

/* [Envelope] */
inner_w = 80;       // Inner cavity width  [mm]
inner_d = 60;       // Inner cavity depth  [mm]
inner_h = 30;       // Inner cavity height [mm]
wall    = 2.5;      // Wall thickness [mm]
corner_r = 4;       // Outer corner radius [mm]
draft_angle = 1;    // Draft on outer shell [deg]
base_ratio = 0.62;  // Height split assigned to base

/* [PCB Mount Pattern] */
pcb_hole_pattern = [
    [8, 8],
    [72, 8],
    [72, 52],
    [8, 52]
];
standoff_h = 4;       // Standoff height above floor [mm]
standoff_od = 6;      // Standoff OD [mm]
insert_d = 3.6;       // Insert/pilot bore [mm]
insert_depth = 4;     // Insert bore depth [mm]

/* [Closure] */
closure_mode = "snap";    // snap / screw
register_h = 3.0;         // Register/lip height [mm]
register_w = 1.2;         // Register radial width [mm]
lip_chamfer = 0.4;        // Actual lead-in chamfer [mm]
snap_clearance = 0.20;    // Female groove clearance in snap mode [mm]
screw_clearance = 0.35;   // Female groove clearance in screw mode [mm]

/* [Screw Closure] */
screw_post_od = 8.0;              // Corner post OD [mm]
screw_post_offset = 9.0;          // Offset from inner wall [mm]
screw_pilot_d = 2.8;              // Pilot/insert hole in posts [mm]
screw_clearance_d = 3.2;          // Lid clearance hole [mm]
screw_head_recess_d = 6.8;        // Lid counterbore [mm]
screw_head_recess_depth = 2.2;    // Lid counterbore depth [mm]

/* [Cutouts] */
rear_cutouts = [
    [22, 10, 12, 9, "usb_c"],
    [52, 10, 8, 8, "round"]
];
front_cutouts = [];
left_cutouts  = [
    [30, 10, 14, 8, "slot"]
];
right_cutouts = [];

/* [Ventilation] */
enable_vents = true;
vent_slot_w = 1.5;
vent_slot_h = 8;
vent_spacing = 3.5;
vent_margin = 10;

/* [Accessories] */
enable_ears  = true;
ear_w        = 12;
ear_hole_d   = 4.5;
ear_keyhole  = true;
label_recess = true;
label_w      = 42;
label_d      = 16;
label_depth  = 0.6;

/* [Gasket] */
gasket_enabled  = false;
gasket_groove_w = 2.2;
gasket_groove_d = 1.0;

/* [Preview] */
show_exploded      = false;
show_cross_section = false;
$fn = 80;

// ── Derived values ──────────────────────────────────────────
outer_w = inner_w + wall * 2;
outer_d = inner_d + wall * 2;
base_h  = inner_h * base_ratio + wall;
lid_h   = inner_h * (1 - base_ratio) + wall;
explode = show_exploded ? base_h + 16 : 0;
closure_is_snap = closure_mode == "snap";
closure_is_screw = closure_mode == "screw";
register_clearance = closure_is_snap ? snap_clearance : screw_clearance;
assert(closure_is_snap || closure_is_screw, "closure_mode must be snap or screw");
assert(len(pcb_hole_pattern) >= 2, "pcb_hole_pattern must define at least two anchor points");

// ── Rounded geometry helpers ────────────────────────────────
module rounded_box(w, d, h, r) {
    rr = min(r, min(w, d) / 2 - 0.01);

    hull()
        for (x = [rr, w - rr], y = [rr, d - rr])
            translate([x, y, 0])
                cylinder(r = rr, h = h);
}

module drafted_box(w, d, h, r, draft = 0) {
    rr = min(r, min(w, d) / 2 - 0.01);
    shrink = draft <= 0 ? 0 : h * tan(draft);

    if (draft <= 0) {
        rounded_box(w, d, h, rr);
    } else {
        hull()
            for (x = [rr, w - rr], y = [rr, d - rr]) {
                translate([x, y, 0])
                    cylinder(r = rr, h = 0.01);
                translate([x, y, 0])
                    cylinder(r1 = rr, r2 = max(0.5, rr - shrink), h = h);
            }
    }
}

module rounded_rect_2d_centered(w, d, r) {
    rr = min(r, min(w, d) / 2 - 0.01);
    translate([-w / 2 + rr, -d / 2 + rr])
        offset(r = rr)
            square([max(0.1, w - rr * 2), max(0.1, d - rr * 2)]);
}

module tapered_register(outer_w_mm, outer_d_mm, inner_w_mm, inner_d_mm, corner_r_mm, height_mm, chamfer_mm) {
    outer_r = max(0.8, corner_r_mm);
    inner_r = max(0.8, corner_r_mm - register_w);
    top_outer_w = max(outer_w_mm - chamfer_mm * 2, inner_w_mm + 0.4);
    top_outer_d = max(outer_d_mm - chamfer_mm * 2, inner_d_mm + 0.4);
    top_outer_r = max(0.5, outer_r - chamfer_mm);

    difference() {
        hull() {
            linear_extrude(height = 0.01)
                rounded_rect_2d_centered(outer_w_mm, outer_d_mm, outer_r);
            translate([0, 0, height_mm])
                linear_extrude(height = 0.01)
                    rounded_rect_2d_centered(top_outer_w, top_outer_d, top_outer_r);
        }

        translate([0, 0, -0.1])
            linear_extrude(height = height_mm + 0.2)
                rounded_rect_2d_centered(inner_w_mm, inner_d_mm, inner_r);
    }
}

module ring_groove(outer_w_mm, outer_d_mm, inner_w_mm, inner_d_mm, r_outer, depth_mm) {
    difference() {
        linear_extrude(height = depth_mm)
            rounded_rect_2d_centered(outer_w_mm, outer_d_mm, r_outer);
        translate([0, 0, -0.1])
            linear_extrude(height = depth_mm + 0.2)
                rounded_rect_2d_centered(inner_w_mm, inner_d_mm, max(0.5, r_outer - gasket_groove_w));
    }
}

// ── Utility features ────────────────────────────────────────
module standoff() {
    difference() {
        cylinder(h = standoff_h, d1 = standoff_od + 0.8, d2 = standoff_od);
        translate([0, 0, standoff_h - insert_depth + 0.1])
            cylinder(h = insert_depth + 0.5, d = insert_d);
    }
}

module corner_screw_post() {
    difference() {
        cylinder(h = base_h - wall - 0.8, d = screw_post_od);
        translate([0, 0, -0.5])
            cylinder(h = base_h + 0.5, d = screw_pilot_d);
    }
}

module lid_screw_hole() {
    translate([0, 0, -0.2])
        cylinder(h = lid_h + 0.4, d = screw_clearance_d);

    translate([0, 0, lid_h - screw_head_recess_depth])
        cylinder(h = screw_head_recess_depth + 0.2, d = screw_head_recess_d);
}

module mounting_ear() {
    ear_h = wall + 2;

    difference() {
        hull() {
            cylinder(r = ear_w / 2, h = ear_h);
            translate([0, ear_w / 2, 0])
                cube([ear_w, 0.01, ear_h], center = true);
        }

        translate([0, 0, -0.5])
            cylinder(h = ear_h + 1, d = ear_hole_d);

        if (ear_keyhole)
            translate([0, ear_hole_d * 0.6, -0.5])
                cylinder(h = ear_h + 1, d = ear_hole_d * 0.55);
    }
}

module vent_slots_side(length_mm, height_mm) {
    if (enable_vents) {
        n = floor((length_mm - vent_margin * 2) / vent_spacing);
        start = (length_mm - (n - 1) * vent_spacing) / 2;

        for (i = [0 : n - 1])
            translate([-0.5,
                       start + i * vent_spacing - vent_slot_w / 2,
                       (height_mm - vent_slot_h) / 2])
                cube([wall + 1, vent_slot_w, vent_slot_h]);
    }
}

module rounded_slot_cutout(width_mm, height_mm, depth_mm, corner_r_mm) {
    rr = min(corner_r_mm, min(width_mm, height_mm) / 2 - 0.01);

    union() {
        cube([max(0.1, width_mm - rr * 2), depth_mm, height_mm], center = true);
        cube([width_mm, depth_mm, max(0.1, height_mm - rr * 2)], center = true);

        for (x = [-width_mm / 2 + rr, width_mm / 2 - rr],
             z = [-height_mm / 2 + rr, height_mm / 2 - rr])
            translate([x, 0, z])
                rotate([90, 0, 0])
                    cylinder(h = depth_mm, r = rr, center = true);
    }
}

module cutout_volume(cutout) {
    width_mm = cutout[2];
    height_mm = cutout[3];
    kind = cutout[4];

    if (kind == "round") {
        rotate([90, 0, 0])
            cylinder(h = wall + 2, d = min(width_mm, height_mm), center = true);
    } else if (kind == "usb_c") {
        rounded_slot_cutout(width_mm, height_mm, wall + 2, min(height_mm / 2, 2));
    } else if (kind == "slot") {
        rounded_slot_cutout(width_mm, height_mm, wall + 2, height_mm / 2);
    } else {
        cube([width_mm, wall + 2, height_mm], center = true);
    }
}

module wall_cutout_array(cutouts, wall_name) {
    for (cutout = cutouts) {
        cx = cutout[0];
        cz = cutout[1] + cutout[3] / 2;

        if (wall_name == "rear")
            translate([wall + cx, outer_d - wall / 2, cz])
                cutout_volume(cutout);

        if (wall_name == "front")
            translate([wall + cx, wall / 2, cz])
                cutout_volume(cutout);

        if (wall_name == "left")
            translate([wall / 2, wall + cutout[0], cz])
                rotate([0, 0, 90])
                    cutout_volume(cutout);

        if (wall_name == "right")
            translate([outer_w - wall / 2, wall + cutout[0], cz])
                rotate([0, 0, 90])
                    cutout_volume(cutout);
    }
}

function screw_post_points() = [
    [wall + screw_post_offset, wall + screw_post_offset],
    [outer_w - wall - screw_post_offset, wall + screw_post_offset],
    [outer_w - wall - screw_post_offset, outer_d - wall - screw_post_offset],
    [wall + screw_post_offset, outer_d - wall - screw_post_offset]
];

// ── Main bodies ─────────────────────────────────────────────
module base_shell() {
    difference() {
        union() {
            drafted_box(outer_w, outer_d, base_h, corner_r, draft_angle);

            translate([outer_w / 2, outer_d / 2, base_h - register_h])
                tapered_register(
                    inner_w + register_w * 2,
                    inner_d + register_w * 2,
                    inner_w,
                    inner_d,
                    max(1, corner_r - wall + register_w),
                    register_h,
                    lip_chamfer
                );

            if (enable_ears)
                for (x = [outer_w * 0.25, outer_w * 0.75])
                    translate([x, -ear_w / 2 + 1, 0])
                        mounting_ear();

            if (closure_is_screw)
                for (pt = screw_post_points())
                    translate([pt[0], pt[1], wall])
                        corner_screw_post();
        }

        translate([wall, wall, wall])
            cube([inner_w, inner_d, base_h]);

        wall_cutout_array(rear_cutouts, "rear");
        wall_cutout_array(front_cutouts, "front");
        wall_cutout_array(left_cutouts, "left");
        wall_cutout_array(right_cutouts, "right");

        translate([0, 0, wall])
            translate([-0.5, wall, 0])
                vent_slots_side(inner_d, base_h - wall);

        translate([outer_w - wall, wall, wall])
            vent_slots_side(inner_d, base_h - wall);
    }

    for (hole = pcb_hole_pattern)
        translate([wall + hole[0], wall + hole[1], wall])
            standoff();
}

module lid_shell() {
    groove_outer_w = inner_w + register_w * 2 + register_clearance * 2;
    groove_outer_d = inner_d + register_w * 2 + register_clearance * 2;
    groove_inner_w = inner_w - register_clearance * 2;
    groove_inner_d = inner_d - register_clearance * 2;

    difference() {
        drafted_box(outer_w, outer_d, lid_h, corner_r, draft_angle);

        translate([wall + register_w + register_clearance,
                   wall + register_w + register_clearance,
                   wall])
            cube([
                inner_w - register_clearance * 2 - register_w * 2,
                inner_d - register_clearance * 2 - register_w * 2,
                lid_h
            ]);

        translate([outer_w / 2, outer_d / 2, wall])
            linear_extrude(height = register_h + 0.4)
                difference() {
                    rounded_rect_2d_centered(groove_outer_w, groove_outer_d,
                                             max(1, corner_r - wall + register_w + register_clearance));
                    rounded_rect_2d_centered(groove_inner_w, groove_inner_d,
                                             max(0.8, corner_r - wall - register_clearance));
                }

        if (label_recess)
            translate([(outer_w - label_w) / 2,
                       (outer_d - label_d) / 2,
                       lid_h - label_depth])
                cube([label_w, label_d, label_depth + 0.1]);

        if (gasket_enabled)
            translate([outer_w / 2, outer_d / 2, wall + register_h - gasket_groove_d])
                ring_groove(
                    inner_w + register_w * 2 - 0.4,
                    inner_d + register_w * 2 - 0.4,
                    inner_w - gasket_groove_w * 2,
                    inner_d - gasket_groove_w * 2,
                    max(0.8, corner_r - wall + register_w),
                    gasket_groove_d
                );

        if (closure_is_screw)
            for (pt = screw_post_points())
                translate([pt[0], pt[1], 0])
                    lid_screw_hole();
    }
}

module assembly() {
    color("SlateGray") base_shell();

    color("LightSteelBlue")
        translate([0, 0, base_h + explode])
            rotate([180, 0, 0])
                translate([0, 0, -base_h - lid_h])
                    lid_shell();
}

// ── Render ──────────────────────────────────────────────────
if (show_cross_section) {
    difference() {
        assembly();
        translate([outer_w / 2, -1, -1])
            cube([outer_w, outer_d + 2, inner_h + wall * 2 + explode + 24]);
    }
} else {
    assembly();
}

// ── Echo info ───────────────────────────────────────────────
echo("── Enclosure Generator ─────────────────────");
echo(str("  Closure mode:    ", closure_mode));
echo(str("  PCB anchors:     ", len(pcb_hole_pattern)));
echo(str("  Outer envelope:  ", outer_w, " × ", outer_d, " × ", base_h + lid_h, " mm"));
echo(str("  Inner cavity:    ", inner_w, " × ", inner_d, " × ", inner_h, " mm"));
echo(str("  Gasket groove:   ", gasket_enabled ? "enabled" : "disabled"));
echo(str("  Rear cutouts:    ", len(rear_cutouts), " · Left: ", len(left_cutouts),
         " · Right: ", len(right_cutouts), " · Front: ", len(front_cutouts)));

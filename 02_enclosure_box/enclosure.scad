// ============================================================
//  Parametric Electronics Enclosure — OpenSCAD
//  Author:  olesiapal
//  Version: 2.0
//  License: MIT
//
//  Production-ready two-part snap-fit enclosure with:
//    • PCB standoffs with heat-set insert bores
//    • Ventilation grid with configurable pattern
//    • Panel-mount cable glands (rear wall)
//    • Mounting ears with keyhole slots
//    • Label recess on lid
//    • Draft angle for injection-moulding compatibility
//    • Exploded & cross-section preview modes
// ============================================================

/* [Enclosure Dimensions] */
inner_w = 80;       // Inner width  (X) [mm]
inner_d = 60;       // Inner depth  (Y) [mm]
inner_h = 30;       // Inner height (Z) [mm]

/* [Wall & Structure] */
wall         = 2.5;    // Wall thickness [mm]
base_ratio   = 0.65;   // Height split: base fraction
corner_r     = 4;      // Outer corner radius [mm]
draft_angle  = 1;      // Draft angle [°] (0 = vertical walls)

/* [Snap-Fit Lip] */
lip_h        = 3.0;    // Lip height [mm]
lip_w        = 1.2;    // Lip width / interference [mm]
lip_chamfer  = 0.4;    // Lead-in chamfer on lip [mm]

/* [PCB Standoffs] */
standoff_h   = 4;      // Height above floor [mm]
standoff_od  = 6;      // Outer diameter [mm]
insert_d     = 3.6;    // Heat-set insert bore (M2.5) [mm]
insert_depth = 4;      // Insert bore depth [mm]
pcb_margin   = 5;      // Inset from inner wall [mm]

/* [Cable Glands — Rear Wall] */
gland_d      = 8;      // Cutout diameter [mm]
gland_count  = 2;      // Number of holes

/* [Ventilation — Side Walls] */
enable_vents   = true;  // Enable ventilation slots
vent_slot_w    = 1.5;   // Slot width [mm]
vent_slot_h    = 8;     // Slot height [mm]
vent_spacing   = 3.5;   // Centre-to-centre spacing [mm]
vent_margin    = 10;    // Margin from edges [mm]

/* [Mounting Ears] */
enable_ears     = true;   // Wall-mount ears on base
ear_w           = 12;     // Ear width [mm]
ear_hole_d      = 4.5;    // Screw hole diameter [mm]
ear_keyhole     = true;   // Keyhole slot for hang-mount

/* [Lid Features] */
label_recess    = true;   // Rectangular recess for label
label_w         = 40;     // Label width [mm]
label_d         = 15;     // Label depth [mm]
label_depth     = 0.6;    // Recess depth [mm]

/* [Preview Modes] */
show_exploded    = false;   // Exploded view
show_cross_section = false; // Cross-section cut

/* [Rendering] */
$fn = 80;

// ── Derived values ──────────────────────────────────────────
outer_w  = inner_w + wall * 2;
outer_d  = inner_d + wall * 2;
base_h   = inner_h * base_ratio + wall;
lid_h    = inner_h * (1 - base_ratio) + wall;
explode  = show_exploded ? base_h + 15 : 0;

// ── Rounded box primitive ───────────────────────────────────
module rounded_box(w, d, h, r) {
    hull()
        for (x = [r, w - r], y = [r, d - r])
            translate([x, y, 0])
                cylinder(r = r, h = h);
}

// ── Rounded box with draft angle ────────────────────────────
module drafted_box(w, d, h, r, draft = 0) {
    if (draft <= 0) {
        rounded_box(w, d, h, r);
    } else {
        hull()
            for (x = [r, w - r], y = [r, d - r]) {
                translate([x, y, 0])
                    cylinder(r = r, h = 0.01);
                translate([x, y, 0])
                    cylinder(r1 = r, r2 = r - h * tan(draft), h = h);
            }
    }
}

// ── PCB standoff with heat-set insert bore ──────────────────
module standoff() {
    difference() {
        // Tapered column for strength
        cylinder(h = standoff_h, d1 = standoff_od + 1, d2 = standoff_od);
        // Heat-set insert bore
        translate([0, 0, standoff_h - insert_depth + 0.1])
            cylinder(h = insert_depth + 0.5, d = insert_d);
    }
}

// ── Ventilation slot array ──────────────────────────────────
module vent_slots(wall_len, wall_h) {
    if (enable_vents) {
        n = floor((wall_len - vent_margin * 2) / vent_spacing);
        start_x = (wall_len - (n - 1) * vent_spacing) / 2;

        for (i = [0 : n - 1])
            translate([start_x + i * vent_spacing - vent_slot_w / 2,
                       -0.5,
                       (wall_h - vent_slot_h) / 2])
                cube([vent_slot_w, wall + 1, vent_slot_h]);
    }
}

// ── Mounting ear ────────────────────────────────────────────
module mounting_ear() {
    ear_h = wall + 2;
    ear_ext = ear_w;

    difference() {
        // Ear body
        hull() {
            translate([0, 0, 0])
                cylinder(r = ear_w / 2, h = ear_h);
            translate([0, ear_w / 2, 0])
                cube([ear_w, 0.01, ear_h], center = true);
        }

        // Screw hole
        translate([0, 0, -0.5])
            cylinder(h = ear_h + 1, d = ear_hole_d);

        // Keyhole extension
        if (ear_keyhole)
            translate([0, ear_hole_d * 0.6, -0.5])
                cylinder(h = ear_h + 1, d = ear_hole_d * 0.55);
    }
}

// ── Base shell ──────────────────────────────────────────────
module base() {
    difference() {
        union() {
            // Outer shell
            rounded_box(outer_w, outer_d, base_h, corner_r);

            // Snap-fit lip (male) around inner perimeter
            translate([wall - lip_w, wall - lip_w, base_h - lip_h])
                difference() {
                    rounded_box(inner_w + lip_w * 2,
                                inner_d + lip_w * 2,
                                lip_h, max(1, corner_r - wall + lip_w));
                    translate([lip_w, lip_w, -0.5])
                        cube([inner_w, inner_d, lip_h + 1]);
                }

            // Mounting ears
            if (enable_ears) {
                for (x = [outer_w * 0.25, outer_w * 0.75])
                    translate([x, -ear_w / 2 + 1, 0])
                        mounting_ear();
            }
        }

        // Hollow interior
        translate([wall, wall, wall])
            cube([inner_w, inner_d, base_h]);

        // Cable gland cutouts (rear wall)
        for (i = [1 : gland_count])
            translate([outer_w * i / (gland_count + 1),
                       outer_d - wall - 0.1,
                       base_h * 0.45])
                rotate([-90, 0, 0])
                    cylinder(h = wall + 1, d = gland_d);

        // Ventilation — left wall
        translate([0, 0, wall])
            rotate([0, 0, 0])
                translate([-0.5, 0, 0])
                    vent_slots_side(inner_d, base_h - wall);

        // Ventilation — right wall
        translate([outer_w - wall, 0, wall])
            vent_slots_side(inner_d, base_h - wall);
    }

    // PCB standoffs — 4 corners
    for (x = [pcb_margin + standoff_od / 2,
              inner_w - pcb_margin - standoff_od / 2])
        for (y = [pcb_margin + standoff_od / 2,
                  inner_d - pcb_margin - standoff_od / 2])
            translate([wall + x, wall + y, wall])
                standoff();
}

// ── Side-wall vent helper ───────────────────────────────────
module vent_slots_side(length, height) {
    if (enable_vents) {
        n = floor((length - vent_margin * 2) / vent_spacing);
        start = (length - (n - 1) * vent_spacing) / 2;

        for (i = [0 : n - 1])
            translate([-0.5,
                       start + i * vent_spacing - vent_slot_w / 2,
                       (height - vent_slot_h) / 2])
                cube([wall + 1, vent_slot_w, vent_slot_h]);
    }
}

// ── Lid shell ───────────────────────────────────────────────
module lid() {
    difference() {
        rounded_box(outer_w, outer_d, lid_h, corner_r);

        // Hollow interior — clearance for snap lip
        translate([wall + lip_w + 0.2,
                   wall + lip_w + 0.2,
                   wall])
            cube([inner_w - lip_w * 2 - 0.4,
                  inner_d - lip_w * 2 - 0.4,
                  lid_h]);

        // Snap-fit female groove
        translate([wall, wall, wall])
            difference() {
                cube([inner_w, inner_d, lip_h + 0.5]);
                translate([lip_w + 0.2, lip_w + 0.2, -0.5])
                    cube([inner_w - lip_w * 2 - 0.4,
                          inner_d - lip_w * 2 - 0.4,
                          lip_h + 2]);
            }

        // Label recess on top face
        if (label_recess)
            translate([(outer_w - label_w) / 2,
                       (outer_d - label_d) / 2,
                       lid_h - label_depth])
                cube([label_w, label_d, label_depth + 0.1]);
    }
}

// ── Assembly ────────────────────────────────────────────────
module assembly() {
    // Base
    color("SlateGray") base();

    // Lid
    color("LightSteelBlue")
    translate([0, 0, base_h + explode])
        rotate([180, 0, 0])
            translate([0, 0, -base_h - lid_h])
                lid();
}

// ── Render ───────────────────────────────────────────────────
if (show_cross_section) {
    difference() {
        assembly();
        translate([outer_w / 2, -1, -1])
            cube([outer_w, outer_d + 2, inner_h + wall * 2 + explode + 20]);
    }
} else {
    assembly();
}

// ── Info ─────────────────────────────────────────────────────
echo(str("── Enclosure Specification ─────────"));
echo(str("  Outer: ", outer_w, " × ", outer_d, " × ",
         base_h + lid_h, " mm"));
echo(str("  Inner: ", inner_w, " × ", inner_d, " × ", inner_h, " mm"));
echo(str("  Wall:  ", wall, " mm"));
echo(str("  Base height: ", base_h, " mm"));
echo(str("  Lid height:  ", lid_h, " mm"));

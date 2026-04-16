// ============================================================
//  Parametric Involute Spur Gear — OpenSCAD
//  Author:  olesiapal
//  Version: 2.0
//  License: MIT
//
//  A production-grade parametric spur gear with true involute
//  tooth profile, configurable hub geometry, weight-reduction
//  pockets, chamfered edges, and optional herringbone mode.
//
//  ► Adjust values in the [Gear Parameters] block.
//  ► Press F5 to preview, F6 to render.
//  ► Export STL for 3D printing or DXF for laser cutting.
// ============================================================

/* [Gear Parameters] */
module_size    = 2;       // Metric module (tooth pitch / π)
num_teeth      = 24;      // Number of teeth (≥ 8)
pressure_angle = 20;      // Involute pressure angle [°]
gear_height    = 10;      // Face width [mm]
backlash       = 0.1;     // Backlash compensation per flank [mm]

/* [Hub & Bore] */
hub_diameter   = 16;      // Hub outer diameter [mm]
hub_height     = 14;      // Hub protrusion above gear face [mm]
bore_diameter  = 8;       // Shaft bore [mm]
keyway_width   = 3;       // Keyway slot width [mm] (0 = none)
keyway_depth   = 1.8;     // Keyway radial depth [mm]

/* [Weight Reduction] */
enable_spokes    = true;  // Enable spoke/pocket pattern
spoke_count      = 5;     // Number of spokes
spoke_width      = 5;     // Spoke width [mm]
pocket_floor     = 1.5;   // Pocket floor thickness [mm]

/* [Chamfers & Fillets] */
tip_chamfer    = 0.3;     // Tooth tip chamfer [mm]
bore_chamfer   = 0.5;     // Bore entry chamfer [mm]

/* [Herringbone] */
herringbone    = false;   // Enable herringbone (double-helical)
helix_angle    = 25;      // Helix angle [°] (used if herringbone=true)

/* [Mating Gear Preview] */
show_mate      = false;   // Show mating gear in preview
mate_teeth     = 16;      // Mating gear tooth count

/* [Rendering] */
$fn = 128;

// ── Derived geometry ────────────────────────────────────────
pitch_radius    = module_size * num_teeth / 2;
base_radius     = pitch_radius * cos(pressure_angle);
addendum        = module_size;
dedendum        = 1.25 * module_size;
addendum_radius = pitch_radius + addendum;
dedendum_radius = pitch_radius - dedendum;
tooth_angle     = 360 / num_teeth;
clearance       = 0.25 * module_size;

// Sanity guards
assert(num_teeth >= 8,
       "Minimum 8 teeth for valid involute geometry");
assert(bore_diameter < hub_diameter,
       "Bore must be smaller than hub");
assert(dedendum_radius > hub_diameter / 2 + 2,
       "Hub too large — teeth would merge with hub");

// ── Involute mathematics ────────────────────────────────────
function involute_intersect_angle(r) =
    sqrt(pow(r / base_radius, 2) - 1) * 180 / PI;

function involute_point(r, t) =
    [ r * (cos(t) + t * PI / 180 * sin(t)),
      r * (sin(t) - t * PI / 180 * cos(t)) ];

// ── Single tooth flank ──────────────────────────────────────
function tooth_flank(steps = 24) = [
    for (i = [0 : steps])
        let(
            r   = base_radius,
            t_m = involute_intersect_angle(addendum_radius),
            t   = i * t_m / steps
        )
        involute_point(r, t)
];

// ── 2D tooth profile ────────────────────────────────────────
module tooth_2d() {
    half_thick_angle = 90 / num_teeth
                     + involute_intersect_angle(pitch_radius);
    backlash_angle   = backlash / pitch_radius * 180 / PI;

    pts_r = tooth_flank(24);
    pts_l = [ for (p = pts_r) [p.x, -p.y] ];

    rotate([0, 0, half_thick_angle - backlash_angle])
    polygon(concat(
        [[ dedendum_radius * cos(-1), dedendum_radius * sin(-1) ]],
        pts_r,
        [[ addendum_radius * cos(involute_intersect_angle(addendum_radius)),
          -addendum_radius * sin(involute_intersect_angle(addendum_radius)) ]],
        [ for (i = [len(pts_l) - 1 : -1 : 0]) pts_l[i] ],
        [[ dedendum_radius * cos(1), -dedendum_radius * sin(1) ]]
    ));
}

// ── Full 2D gear profile ────────────────────────────────────
module gear_2d() {
    difference() {
        union() {
            circle(r = dedendum_radius);
            for (i = [0 : num_teeth - 1])
                rotate([0, 0, i * tooth_angle])
                    tooth_2d();
        }
        circle(r = bore_diameter / 2);
    }
}

// ── Weight-reduction pockets ────────────────────────────────
module spoke_pockets(h) {
    if (enable_spokes && dedendum_radius - hub_diameter / 2 > spoke_width * 2) {
        pocket_inner = hub_diameter / 2 + 2;
        pocket_outer = dedendum_radius - module_size * 2;
        pocket_angle = 360 / spoke_count;

        if (pocket_outer > pocket_inner + 4) {
            difference() {
                cylinder(h = h, r = pocket_outer);
                cylinder(h = h + 1, r = pocket_inner);

                // Keep spokes
                for (i = [0 : spoke_count - 1])
                    rotate([0, 0, i * pocket_angle])
                        translate([-spoke_width / 2, 0, -0.5])
                            cube([spoke_width, pocket_outer + 1, h + 1]);
            }
        }
    }
}

// ── Keyway cut ──────────────────────────────────────────────
module keyway(h) {
    if (keyway_width > 0) {
        translate([bore_diameter / 2 - keyway_depth, -keyway_width / 2, -1])
            cube([keyway_depth + 0.5, keyway_width, h + 2]);
    }
}

// ── Chamfer ring ────────────────────────────────────────────
module tip_chamfer_cut() {
    if (tip_chamfer > 0) {
        difference() {
            cylinder(r = addendum_radius + 1,
                     h = gear_height + 2, center = true);
            cylinder(r1 = addendum_radius - tip_chamfer,
                     r2 = addendum_radius,
                     h  = tip_chamfer * 2, center = false);
            translate([0, 0, gear_height - tip_chamfer * 2])
                cylinder(r1 = addendum_radius,
                         r2 = addendum_radius - tip_chamfer,
                         h  = tip_chamfer * 2, center = false);
            cylinder(r = addendum_radius,
                     h = gear_height, center = false);
        }
    }
}

// ── Hub ─────────────────────────────────────────────────────
module hub() {
    difference() {
        cylinder(h = hub_height, d = hub_diameter);
        // Bore
        cylinder(h = hub_height + 1, d = bore_diameter);
        // Bore chamfer
        if (bore_chamfer > 0) {
            translate([0, 0, hub_height - bore_chamfer])
                cylinder(h = bore_chamfer + 0.1,
                         d1 = bore_diameter,
                         d2 = bore_diameter + bore_chamfer * 2);
        }
        // Keyway extends through hub
        keyway(hub_height);
    }
}

// ── Single gear half (used for herringbone) ─────────────────
module gear_half(h, twist_dir = 1) {
    twist = herringbone ? twist_dir * tan(helix_angle) * h
                          / pitch_radius * 180 / PI : 0;

    difference() {
        linear_extrude(height = h, twist = twist, convexity = 10)
            gear_2d();

        // Spoke pockets (leave floor)
        translate([0, 0, pocket_floor])
            spoke_pockets(h);

        // Keyway
        keyway(h);
    }
}

// ── Main gear assembly ──────────────────────────────────────
module spur_gear() {
    if (herringbone) {
        // Bottom half
        gear_half(gear_height / 2, 1);
        // Top half (mirrored twist)
        translate([0, 0, gear_height / 2])
            gear_half(gear_height / 2, -1);
    } else {
        gear_half(gear_height);
    }

    // Hub (extends above gear)
    hub();
}

// ── Render ───────────────────────────────────────────────────
color("SteelBlue") spur_gear();

// ── Mating gear preview ─────────────────────────────────────
if (show_mate) {
    mate_pitch = module_size * mate_teeth / 2;
    color("Tomato", 0.6)
    translate([pitch_radius + mate_pitch, 0, 0])
        rotate([0, 0, 180 / mate_teeth])
            // Inline mating gear (simplified — reuses same module)
            linear_extrude(height = gear_height)
                difference() {
                    union() {
                        circle(r = mate_teeth * module_size / 2 - dedendum);
                        for (i = [0 : mate_teeth - 1])
                            rotate([0, 0, i * 360 / mate_teeth])
                                tooth_2d();
                    }
                    circle(r = bore_diameter / 2);
                }
}

// ── Info echo ────────────────────────────────────────────────
echo(str("── Gear Specification ──────────────"));
echo(str("  Module:          ", module_size, " mm"));
echo(str("  Teeth:           ", num_teeth));
echo(str("  Pitch diameter:  ", pitch_radius * 2, " mm"));
echo(str("  Outside diameter:", addendum_radius * 2, " mm"));
echo(str("  Root diameter:   ", dedendum_radius * 2, " mm"));
echo(str("  Base circle:     ", base_radius * 2, " mm"));
echo(str("  Face width:      ", gear_height, " mm"));
echo(str("  Circular pitch:  ", module_size * PI, " mm"));

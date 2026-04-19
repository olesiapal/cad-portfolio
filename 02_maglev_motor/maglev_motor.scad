// ============================================================
//  Parametric Magnetic Levitation Motor — OpenSCAD
//  Technology: Passive maglev bearing + axial-flux drive
//
//  The rotor levitates on opposing permanent-magnet rings
//  (zero mechanical friction). Three stator coil phases
//  provide the only energy input needed to sustain rotation.
//  A Halbach array on the rotor concentrates flux downward,
//  boosting coupling to the stator and shielding the top face.
//
//  Modes:
//    • assembled      — full unit with transparent shroud
//    • exploded       — all layers separated for inspection
//    • rotor_only     — Halbach rotor + shaft assembly
//    • stator_only    — stator disk + coil array
//    • field_section  — vertical cross-section cut
// ============================================================

/* [Render Mode] */
render_mode      = "assembled"; // assembled/exploded/rotor_only/stator_only/field_section
$fn              = 128;

/* [Motor Envelope] */
motor_diameter   = 140;   // Outer housing diameter [mm]
motor_height     = 90;    // Total assembly height  [mm]
shaft_diameter   = 12;    // Central shaft OD [mm]
shaft_length     = 110;   // Shaft total length [mm]

/* [Levitation Ring Bearings] */
lev_ring_od      = 60;    // Levitation ring outer diameter [mm]
lev_ring_id      = 40;    // Levitation ring inner diameter [mm]
lev_ring_h       = 8;     // Ring height [mm]
lev_gap          = 4;     // Air gap between opposing rings [mm]
lev_pairs        = 2;     // Number of levitation ring pairs

/* [Halbach Rotor] */
rotor_diameter   = 110;   // Rotor disk outer diameter [mm]
rotor_thickness  = 12;    // Rotor disk thickness [mm]
halbach_magnets  = 16;    // Magnet count (must be divisible by 4)
magnet_w         = 10;    // Magnet width [mm]
magnet_h         = 10;    // Magnet height [mm]
magnet_depth     = 10;    // Magnet depth [mm]
halbach_radius   = 44;    // Magnet array placement radius [mm]

/* [Stator] */
stator_diameter  = 120;   // Stator disk outer diameter [mm]
stator_thickness = 14;    // Stator disk thickness [mm]
coil_phases      = 3;     // Drive phases (3 = standard 3-phase)
coils_per_phase  = 4;     // Coils per phase
coil_od          = 18;    // Coil outer diameter [mm]
coil_id          = 8;     // Coil inner diameter [mm]
coil_height      = 10;    // Coil winding height [mm]
coil_radius      = 44;    // Coil placement radius [mm]

/* [Shroud & Base] */
shroud_wall      = 2.0;   // Transparent shroud wall [mm]
base_height      = 16;    // Base plinth height [mm]
base_diameter    = motor_diameter + 20; // Base OD [mm]
strut_count      = 4;     // Support struts
strut_w          = 6;     // Strut width [mm]

/* [Computed] */
total_coils      = coil_phases * coils_per_phase;
rotor_z          = base_height + stator_thickness + lev_gap + 2;
stator_z         = base_height;

// ── Helpers ──────────────────────────────────────────────────
function halbach_angle(i) = i * 360 / halbach_magnets;

// Halbach sequence: each magnet rotates 90° relative to previous
// Pattern: N↑ → N→ → N↓ → N← (repeating) — concentrates flux below
function halbach_spin(i) = i * 90;

// ── Shaft ─────────────────────────────────────────────────────
module shaft() {
    color("Silver")
        translate([0, 0, -5])
            cylinder(h = shaft_length, d = shaft_diameter);

    // Shaft collar (rotor seat)
    color("DimGray")
        translate([0, 0, rotor_z - 2])
            cylinder(h = rotor_thickness + 4, d = shaft_diameter + 6);
}

// ── Levitation ring (single) ──────────────────────────────────
module lev_ring(color_hex = "DeepSkyBlue") {
    color(color_hex, 0.85)
        difference() {
            cylinder(h = lev_ring_h, d = lev_ring_od);
            translate([0, 0, -0.1])
                cylinder(h = lev_ring_h + 0.2, d = lev_ring_id);
        }
}

// ── Levitation bearing pair (stator fixed + rotor floating) ──
module lev_bearing_pair(z_base) {
    // Fixed ring (on stator, magnetised N-up)
    color("DeepSkyBlue", 0.9)
        translate([0, 0, z_base]) lev_ring("DeepSkyBlue");

    // Floating ring (on rotor, N-up → repels fixed ring)
    color("Tomato", 0.9)
        translate([0, 0, z_base + lev_ring_h + lev_gap]) lev_ring("Tomato");

    // Gap visualisation line
    color("Yellow", 0.4)
        translate([0, 0, z_base + lev_ring_h])
            difference() {
                cylinder(h = lev_gap, d = lev_ring_od + 1);
                cylinder(h = lev_gap + 0.1, d = lev_ring_id - 1);
            }
}

// ── Halbach array rotor ───────────────────────────────────────
module halbach_magnet(index) {
    spin = halbach_spin(index);
    color(spin % 180 == 0 ? "Crimson" : "DodgerBlue", 0.92)
        rotate([0, 0, halbach_angle(index)])
            translate([halbach_radius, -magnet_w / 2, 0])
                rotate([0, 0, spin])
                    // Rotated around magnet centre
                    translate([-magnet_depth / 2, 0, 0])
                        cube([magnet_depth, magnet_w, magnet_h]);
}

module rotor_disk() {
    // Main disk body
    color("Gainsboro", 0.95)
        difference() {
            cylinder(h = rotor_thickness, d = rotor_diameter);
            // Shaft bore
            translate([0, 0, -0.1])
                cylinder(h = rotor_thickness + 0.2, d = shaft_diameter + 0.4);
            // Mass-reduction pockets (8 ×)
            for (i = [0 : 7])
                rotate([0, 0, i * 45 + 22.5])
                    translate([rotor_diameter * 0.28, 0, -0.1])
                        cylinder(h = rotor_thickness + 0.2, d = 16);
        }

    // Halbach magnet array (embedded flush on bottom face)
    translate([0, 0, (rotor_thickness - magnet_h) / 2])
        for (i = [0 : halbach_magnets - 1])
            halbach_magnet(i);

    // Top flux-return plate (steel — closes field above rotor)
    color("SlateGray", 0.7)
        translate([0, 0, rotor_thickness])
            difference() {
                cylinder(h = 3, d = rotor_diameter - 4);
                cylinder(h = 3.1, d = shaft_diameter + 0.4);
            }

    // Levitation rings (rotor side — repel stator rings)
    lev_ring_z1 = rotor_thickness + 3 + 2;
    translate([0, 0, lev_ring_z1])      lev_ring("Tomato");
    if (lev_pairs >= 2)
        translate([0, 0, lev_ring_z1 + lev_ring_h + 16]) lev_ring("Tomato");
}

// ── Stator disk ───────────────────────────────────────────────
module coil_winding(phase_index, coil_index) {
    total = coil_phases * coils_per_phase;
    angle = (phase_index * coils_per_phase + coil_index) * 360 / total;

    phase_colors = ["OrangeRed", "MediumSeaGreen", "DodgerBlue"];
    color(phase_colors[phase_index % 3], 0.88)
        rotate([0, 0, angle])
            translate([coil_radius, 0, 0]) {
                // Winding body
                difference() {
                    cylinder(h = coil_height, d = coil_od);
                    translate([0, 0, -0.1])
                        cylinder(h = coil_height + 0.2, d = coil_id);
                }
                // Lead wires (thin stub)
                color("Goldenrod")
                    for (s = [-1, 1])
                        translate([0, s * coil_id / 2, coil_height])
                            cylinder(h = 3, d = 1.2);
            }
}

module stator_disk() {
    // FR-4 / aluminium carrier disk
    color("DarkSlateGray", 0.9)
        difference() {
            cylinder(h = stator_thickness, d = stator_diameter);
            translate([0, 0, -0.1])
                cylinder(h = stator_thickness + 0.2, d = shaft_diameter + 1);

            // Coil pockets (let windings sit flush)
            for (p = [0 : coil_phases - 1])
                for (c = [0 : coils_per_phase - 1]) {
                    a = (p * coils_per_phase + c) * 360 / total_coils;
                    rotate([0, 0, a])
                        translate([coil_radius, 0, stator_thickness - coil_height])
                            cylinder(h = coil_height + 0.1, d = coil_od + 0.6);
                }

            // Cable routing channels (radial slots)
            for (p = [0 : coil_phases - 1])
                rotate([0, 0, p * 120])
                    translate([0, -1.5, -0.1])
                        cube([stator_diameter / 2, 3, stator_thickness * 0.4]);
        }

    // Coil windings
    for (p = [0 : coil_phases - 1])
        for (c = [0 : coils_per_phase - 1])
            translate([0, 0, stator_thickness - coil_height])
                coil_winding(p, c);

    // Stator levitation rings (fixed — repel rotor rings)
    lev_z1 = stator_thickness + lev_gap + rotor_thickness + 3 + 2;
    color("DeepSkyBlue", 0.9)
        translate([0, 0, stator_thickness + lev_gap + rotor_thickness + 3 + 2])
            lev_ring("DeepSkyBlue");
    if (lev_pairs >= 2)
        color("DeepSkyBlue", 0.9)
            translate([0, 0, lev_z1 + lev_ring_h + 16])
                lev_ring("DeepSkyBlue");
}

// ── Base plinth ───────────────────────────────────────────────
module base_plinth() {
    color("DimGray", 0.95)
        difference() {
            union() {
                // Main plinth
                cylinder(h = base_height, d = base_diameter);
                // Chamfer ring
                translate([0, 0, base_height - 3])
                    cylinder(h = 3,
                             d1 = base_diameter,
                             d2 = base_diameter - 6);
            }
            // Shaft bore through base
            translate([0, 0, -0.1])
                cylinder(h = base_height + 0.2, d = shaft_diameter + 2);
            // Cable exit slots (3-phase, 120° apart)
            for (i = [0 : 2])
                rotate([0, 0, i * 120 + 30])
                    translate([base_diameter / 2 - 10, -4, -0.1])
                        cube([12, 8, base_height * 0.6]);
            // Weight-reduction bore (ring)
            translate([0, 0, 4])
                difference() {
                    cylinder(h = base_height, d = base_diameter - 20);
                    cylinder(h = base_height + 0.1, d = base_diameter - 50);
                }
        }

    // Rubber feet (4 ×)
    color("Black")
        for (i = [0 : 3])
            rotate([0, 0, i * 90 + 45])
                translate([base_diameter / 2 - 12, 0, 0])
                    cylinder(h = 3, d = 10);
}

// ── Transparent shroud ────────────────────────────────────────
module shroud() {
    color("LightCyan", 0.12)
        difference() {
            cylinder(h = motor_height - base_height,
                     d = motor_diameter + shroud_wall * 2);
            translate([0, 0, -0.1])
                cylinder(h = motor_height - base_height + 0.2,
                         d = motor_diameter);
        }

    // Top cap ring
    color("LightCyan", 0.18)
        translate([0, 0, motor_height - base_height - shroud_wall])
            difference() {
                cylinder(h = shroud_wall, d = motor_diameter + shroud_wall * 2);
                translate([0, 0, -0.1])
                    cylinder(h = shroud_wall + 0.2, d = motor_diameter - 20);
            }

    // Support struts (connect shroud to base rim)
    color("Silver", 0.7)
        for (i = [0 : strut_count - 1])
            rotate([0, 0, i * 360 / strut_count])
                translate([motor_diameter / 2 - strut_w / 2,
                           -strut_w / 2, 0])
                    cube([strut_w, strut_w,
                          motor_height - base_height]);
}

// ── Echo report ───────────────────────────────────────────────
module report() {
    echo("── Magnetic Levitation Motor ──────────────────────");
    echo(str("  Motor diameter:        ", motor_diameter,    " mm"));
    echo(str("  Motor height:          ", motor_height,      " mm"));
    echo(str("  Shaft diameter:        ", shaft_diameter,    " mm"));
    echo(str("  Rotor diameter:        ", rotor_diameter,    " mm"));
    echo(str("  Rotor thickness:       ", rotor_thickness,   " mm"));
    echo(str("  Halbach magnets:       ", halbach_magnets,   " (array)"));
    echo(str("  Magnet size:           ", magnet_w, " × ", magnet_h,
             " × ", magnet_depth, " mm"));
    echo(str("  Levitation pairs:      ", lev_pairs));
    echo(str("  Lev. ring OD/ID:       ", lev_ring_od, " / ", lev_ring_id, " mm"));
    echo(str("  Air gap:               ", lev_gap,          " mm"));
    echo(str("  Stator phases:         ", coil_phases));
    echo(str("  Total coils:           ", total_coils,
             "  (", coils_per_phase, " per phase)"));
    echo(str("  Coil OD / ID:          ", coil_od, " / ", coil_id,  " mm"));

    if (halbach_magnets % 4 != 0)
        echo("  WARNING: Halbach array requires magnet count divisible by 4.");
    if (halbach_radius + magnet_depth / 2 > rotor_diameter / 2 - 3)
        echo("  WARNING: Magnets extend beyond rotor edge — reduce halbach_radius.");
    if (coil_radius + coil_od / 2 > stator_diameter / 2 - 3)
        echo("  WARNING: Coils extend beyond stator edge — reduce coil_radius.");
    if (abs(halbach_radius - coil_radius) > 6)
        echo("  WARNING: Rotor and stator radii differ > 6 mm; coupling will be weak.");
}

// ── Assembly ──────────────────────────────────────────────────
module motor_assembled() {
    base_plinth();
    shaft();
    translate([0, 0, stator_z]) stator_disk();
    translate([0, 0, rotor_z])  rotor_disk();
    translate([0, 0, base_height]) shroud();
}

module motor_exploded() {
    base_plinth();

    color("Silver")
        translate([0, 0, -5])
            cylinder(h = shaft_length + 40, d = shaft_diameter);

    // Stator — pulled down
    translate([0, 0, stator_z - 30]) stator_disk();

    // Rotor — floated up
    translate([0, 0, rotor_z + 50]) rotor_disk();

    // Shroud — lifted clear
    translate([0, 0, base_height + 60]) shroud();
}

module motor_field_section() {
    // Clip everything to the right half (x > 0)
    intersection() {
        motor_assembled();
        translate([0, -motor_diameter, -5])
            cube([motor_diameter + 30,
                  motor_diameter * 2,
                  motor_height + 20]);
    }
}

// ── Render ────────────────────────────────────────────────────
assert(render_mode == "assembled"    ||
       render_mode == "exploded"     ||
       render_mode == "rotor_only"   ||
       render_mode == "stator_only"  ||
       render_mode == "field_section",
       "render_mode must be: assembled/exploded/rotor_only/stator_only/field_section");

report();

if      (render_mode == "assembled")     { motor_assembled(); }
else if (render_mode == "exploded")      { motor_exploded(); }
else if (render_mode == "rotor_only")    { rotor_disk(); }
else if (render_mode == "stator_only")   { stator_disk(); }
else if (render_mode == "field_section") { motor_field_section(); }

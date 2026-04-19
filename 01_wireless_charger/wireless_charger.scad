// ============================================================
//  Parametric Wireless Resonant Charger — OpenSCAD
//  Technology: Magnetic resonance coupling (WPT)
//  Charges devices within configurable radius without contact
//
//  Modes:
//    • assembled     — complete unit, ready to review
//    • exploded      — all layers separated for inspection
//    • coil_only     — transmission coil + ferrite shield
//    • field_preview — assembled + range sphere overlay
// ============================================================

/* [Render Mode] */
render_mode = "assembled"; // assembled / exploded / coil_only / field_preview
$fn = 64;

/* [Housing] */
housing_diameter  = 120;   // Outer diameter [mm]
housing_height    = 32;    // Total height [mm]
wall_thickness    = 2.5;   // Shell wall [mm]
lid_height        = 6;     // Lid height [mm]
fin_count         = 16;    // Cooling fin count
fin_height        = 4;     // Fin height [mm]
fin_thickness     = 1.5;   // Fin thickness [mm]
corner_radius     = 3;     // Housing top edge radius [mm]

/* [Transmission Coil] */
coil_inner_radius = 18;    // Inner coil radius [mm]
coil_outer_radius = 46;    // Outer coil radius [mm]
coil_turns        = 7;     // Number of turns
wire_diameter     = 2.2;   // Litz wire bundle diameter [mm]
coil_layers       = 2;     // Winding layers (height)
ferrite_thickness = 3;     // Ferrite shield disk thickness [mm]

/* [PCB & Electronics] */
pcb_width         = 80;    // PCB width [mm]
pcb_depth         = 60;    // PCB depth [mm]
pcb_thickness     = 1.6;   // PCB thickness [mm]
cap_count         = 6;     // Resonant capacitors
cap_diameter      = 8;     // Capacitor body diameter [mm]
cap_height        = 16;    // Capacitor body height [mm]

/* [LED Ring] */
led_ring_radius   = 50;    // LED ring radius (centre) [mm]
led_ring_width    = 4;     // Diffuser channel width [mm]
led_count         = 24;    // LED bead count

/* [Field Visualization] */
field_radius_mm   = 1000;  // Max charging radius [mm]
show_field        = false; // Force field sphere in any mode

// ── Derived values ───────────────────────────────────────────
function coil_avg_r()        = (coil_inner_radius + coil_outer_radius) / 2;
function coil_avg_r_cm()     = coil_avg_r() / 10;
function coil_width_cm()     = (coil_outer_radius - coil_inner_radius) / 10;
function wire_length_mm()    = coil_turns * 2 * PI * coil_avg_r() * coil_layers;

// Wheeler's flat spiral approximation (μH)
function coil_inductance_uH() =
    (pow(coil_avg_r_cm(), 2) * pow(coil_turns, 2)) /
    (0.2032 * coil_avg_r_cm() + 0.254 * coil_width_cm());

// Resonant frequency assuming 470 pF capacitor bank
function resonant_freq_kHz() =
    1 / (2 * PI * sqrt(coil_inductance_uH() * 1e-6 * 470e-12)) / 1000;

base_h = housing_height - lid_height;
coil_h = wire_diameter * coil_layers;
coil_z = base_h - ferrite_thickness - coil_h - 3;
pcb_z  = wall_thickness + 9;

// ── Housing — base shell ──────────────────────────────────────
module housing_base() {
    r      = housing_diameter / 2;
    inner_r = r - wall_thickness;

    difference() {
        union() {
            cylinder(h = base_h, r = r);

            // Radial cooling fins (exterior, bottom face)
            for (i = [0 : fin_count - 1])
                rotate([0, 0, i * 360 / fin_count])
                    translate([0, -fin_thickness / 2, 0])
                        cube([r + fin_height, fin_thickness, fin_height]);
        }

        // Hollow interior
        translate([0, 0, wall_thickness])
            cylinder(h = base_h + 1, r = inner_r);

        // Trim fins flush with the housing wall (keep only exterior stub)
        cylinder(h = fin_height + 0.1, r = r - 0.4);

        // Side: IEC power inlet (C8 footprint, 24 × 18 mm)
        translate([r - wall_thickness / 2, -12, base_h * 0.38])
            cube([wall_thickness * 2 + 0.1, 24, 18], center = true);

        // Bottom: central ventilation circle
        cylinder(h = wall_thickness + 0.1, d = 22);

        // Bottom: PCB mounting holes (M3, 4 corners)
        for (x = [-1, 1]) for (y = [-1, 1])
            translate([x * (pcb_width / 2 - 8), y * (pcb_depth / 2 - 8), 0])
                cylinder(h = wall_thickness + 4, d = 3.2);
    }

    // PCB standoffs (4 ×, 8 mm tall, M3 boss)
    for (x = [-1, 1]) for (y = [-1, 1])
        difference() {
            translate([x * (pcb_width / 2 - 8), y * (pcb_depth / 2 - 8), wall_thickness])
                cylinder(h = 8, d = 6);
            translate([x * (pcb_width / 2 - 8), y * (pcb_depth / 2 - 8), wall_thickness - 0.1])
                cylinder(h = 9, d = 3.2);
        }
}

// ── Housing — lid ────────────────────────────────────────────
module housing_lid() {
    r       = housing_diameter / 2;
    inner_r = r - wall_thickness;

    difference() {
        union() {
            cylinder(h = lid_height, r = r);

            // Snap-fit retention tabs (4 ×)
            for (i = [0 : 3])
                rotate([0, 0, i * 90 + 45])
                    translate([inner_r - 1, -2, 0])
                        cube([wall_thickness + 0.5, 4, lid_height]);
        }

        // Hollow
        translate([0, 0, wall_thickness])
            cylinder(h = lid_height + 1, r = inner_r);

        // LED diffuser ring channel
        translate([0, 0, wall_thickness - 0.1])
            difference() {
                cylinder(h = lid_height, r = led_ring_radius / 2 + led_ring_width / 2);
                cylinder(h = lid_height + 0.2, r = led_ring_radius / 2 - led_ring_width / 2);
            }

        // Centre logo window (30 mm circle)
        cylinder(h = wall_thickness + 0.1, d = 30);

        // Ventilation holes — inner ring
        for (i = [0 : 11])
            rotate([0, 0, i * 30])
                translate([r * 0.55, 0, 0])
                    cylinder(h = wall_thickness + 0.1, d = 2.5);
    }
}

// ── Transmission coil (flat Archimedean spiral) ───────────────
module spiral_layer(z_off = 0, dir = 1) {
    spt         = 24; // steps per turn
    total_steps = coil_turns * spt;

    for (i = [0 : total_steps - 2]) {
        a1 = dir * i       * 360 / spt;
        a2 = dir * (i + 1) * 360 / spt;
        r1 = coil_inner_radius + (coil_outer_radius - coil_inner_radius) * i       / total_steps;
        r2 = coil_inner_radius + (coil_outer_radius - coil_inner_radius) * (i + 1) / total_steps;

        hull() {
            translate([r1 * cos(a1), r1 * sin(a1), z_off])
                sphere(d = wire_diameter, $fn = 8);
            translate([r2 * cos(a2), r2 * sin(a2), z_off])
                sphere(d = wire_diameter, $fn = 8);
        }
    }
}

module transmission_coil() {
    // Litz wire winding (gold)
    color("Goldenrod") {
        spiral_layer(z_off = 0,                      dir = 1);
        if (coil_layers >= 2)
            spiral_layer(z_off = wire_diameter * 1.05, dir = -1);
        if (coil_layers >= 3)
            spiral_layer(z_off = wire_diameter * 2.10, dir = 1);
    }

    // Coil former ring
    color("LightGray", 0.5)
        difference() {
            cylinder(h = coil_h + 1.5, r = coil_outer_radius + 3);
            translate([0, 0, -0.1])
                cylinder(h = coil_h + 2, r = coil_inner_radius - 2);
            translate([0, 0, 0.75])
                cylinder(h = coil_h + 0.2, r = coil_outer_radius + 2);
        }

    // Ferrite shielding disk (below coil)
    color("DimGray", 0.88)
        translate([0, 0, -(ferrite_thickness + 0.5)])
            difference() {
                cylinder(h = ferrite_thickness, r = coil_outer_radius + 4);
                cylinder(h = ferrite_thickness + 0.1, d = 14);
            }
}

// ── PCB with driver electronics ───────────────────────────────
module pcb_board() {
    // FR-4 board
    color("ForestGreen", 0.85)
        difference() {
            cube([pcb_width, pcb_depth, pcb_thickness], center = true);
            for (x = [-1, 1]) for (y = [-1, 1])
                translate([x * (pcb_width / 2 - 8), y * (pcb_depth / 2 - 8), 0])
                    cylinder(h = pcb_thickness + 0.1, d = 3.2, center = true);
        }

    // Resonant capacitor bank (electrolytic, 6 ×)
    color("SteelBlue")
        for (i = [0 : cap_count - 1]) {
            a = i * 360 / cap_count;
            rx = 28;
            ry = 20;
            translate([rx * cos(a), ry * sin(a), pcb_thickness / 2])
                cylinder(h = cap_height, d = cap_diameter);
        }

    // Main resonance driver IC (QFN-48 footprint stub)
    color("DarkGray")
        translate([0, 0, pcb_thickness / 2])
            cube([18, 18, 3], center = true);

    // Coil connection pads
    color("Goldenrod")
        for (x = [-1, 1])
            translate([x * 34, 0, pcb_thickness / 2])
                cube([6, 5, 3], center = true);

    // MOSFETs (4 ×, half-bridge)
    color("DimGray")
        for (i = [0 : 3])
            translate([-15 + i * 10, -22, pcb_thickness / 2])
                cube([8, 6, 3.5], center = true);
}

// ── IEC C8 power inlet ────────────────────────────────────────
module power_inlet() {
    r = housing_diameter / 2;

    color("Charcoal")
        translate([r - wall_thickness - 0.5, -10, base_h * 0.38 - 7])
            difference() {
                cube([wall_thickness + 1.5, 20, 14]);
                // Pin sockets
                for (y = [-5, 5])
                    translate([0, 10 + y, 5])
                        rotate([0, 90, 0])
                            cylinder(h = 5, d = 5);
            }
}

// ── LED ring ──────────────────────────────────────────────────
module led_ring_assembly() {
    // Diffuser strip
    color("White", 0.85)
        difference() {
            cylinder(h = 1.8, r = led_ring_radius / 2 + led_ring_width / 2 - 0.3);
            cylinder(h = 1.9, r = led_ring_radius / 2 - led_ring_width / 2 + 0.3);
        }

    // Individual LED beads
    color("Cyan", 0.75)
        for (i = [0 : led_count - 1])
            rotate([0, 0, i * 360 / led_count])
                translate([led_ring_radius / 2, 0, 1])
                    cylinder(h = 1.2, d = 2, $fn = 8);
}

// ── Charging field sphere ─────────────────────────────────────
module field_visualization() {
    // Transparent field bubble
    color("Cyan", 0.035)
        sphere(r = field_radius_mm);

    // Range rings at 25 %, 50 %, 75 %
    color("Cyan", 0.10)
        for (frac = [0.25, 0.5, 0.75])
            rotate_extrude($fn = 64)
                translate([field_radius_mm * frac, 0])
                    circle(r = 5);
}

// ── Echo report ───────────────────────────────────────────────
module report() {
    echo("── Wireless Resonant Charger ──────────────────────");
    echo(str("  Housing diameter:      ", housing_diameter,   " mm"));
    echo(str("  Housing height:        ", housing_height,     " mm"));
    echo(str("  Wall thickness:        ", wall_thickness,     " mm"));
    echo(str("  Coil inner radius:     ", coil_inner_radius,  " mm"));
    echo(str("  Coil outer radius:     ", coil_outer_radius,  " mm"));
    echo(str("  Coil turns × layers:   ", coil_turns, " × ", coil_layers));
    echo(str("  Wire diameter (Litz):  ", wire_diameter,      " mm"));
    echo(str("  Wire length (est.):    ", round(wire_length_mm()), " mm"));
    echo(str("  Inductance (Wheeler):  ",
             round(coil_inductance_uH() * 100) / 100,         " μH"));
    echo(str("  Resonant freq. (est.): ",
             round(resonant_freq_kHz()),                       " kHz  @ 470 pF"));
    echo(str("  Charging radius:       ", field_radius_mm / 10, " cm"));
    echo(str("  Cooling fins:          ", fin_count, " × ", fin_height, " mm"));
    echo(str("  LED indicators:        ", led_count));

    if (coil_inner_radius < wire_diameter * 3)
        echo("  WARNING: Inner radius too small; winding may overlap at centre.");
    if (coil_outer_radius > housing_diameter / 2 - wall_thickness - 5)
        echo("  WARNING: Coil outer radius exceeds housing clearance.");
    if (coil_inductance_uH() < 1)
        echo("  WARNING: Estimated inductance < 1 μH; increase turns or coil area.");
}

// ── Assembly helpers ──────────────────────────────────────────
module _internals() {
    translate([0, 0, pcb_z])  pcb_board();
    translate([0, 0, coil_z]) transmission_coil();
    power_inlet();
    translate([0, 0, base_h + wall_thickness]) led_ring_assembly();
}

module charger_assembled() {
    color("WhiteSmoke", 0.95) housing_base();
    color("WhiteSmoke", 0.90) translate([0, 0, base_h]) housing_lid();
    _internals();
}

module charger_exploded() {
    color("WhiteSmoke", 0.95) housing_base();
    translate([0, 0, pcb_z  + 40]) pcb_board();
    translate([0, 0, coil_z + 80]) transmission_coil();
    color("WhiteSmoke", 0.90) translate([0, 0, base_h + 60]) housing_lid();
    translate([0, 0, base_h + 78]) led_ring_assembly();
    power_inlet();
}

// ── Render ────────────────────────────────────────────────────
assert(render_mode == "assembled"     ||
       render_mode == "exploded"      ||
       render_mode == "coil_only"     ||
       render_mode == "field_preview",
       "render_mode must be: assembled / exploded / coil_only / field_preview");

report();

if      (render_mode == "coil_only")     { transmission_coil(); }
else if (render_mode == "exploded")      { charger_exploded(); }
else if (render_mode == "field_preview") {
    charger_assembled();
    translate([0, 0, housing_height / 2]) field_visualization();
} else                                   { charger_assembled(); }

if (show_field && render_mode != "field_preview")
    translate([0, 0, housing_height / 2]) field_visualization();

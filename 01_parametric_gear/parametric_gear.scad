// ============================================================
//  Parametric Transmission Generator — OpenSCAD
//  Author:  olesiapal
//  Version: 3.0
//  License: MIT
//
//  Modes:
//    • single       — one configurable spur or herringbone gear
//    • pair         — matched gear pair with auto centre distance
//    • mesh_preview — pair with visual debugging colours
//
//  The public interface is built around:
//    • gear(...)
//    • gear_pair(...)
//
//  Geometry is parameter-driven per gear, so the mate no longer
//  depends on the primary gear's global tooth definition.
// ============================================================

/* [Render Mode] */
render_mode    = "single"; // single / pair / mesh_preview
show_mate      = false;    // Legacy flag: true -> pair mode
$fn            = 128;

/* [Primary Gear] */
module_size    = 2;        // Metric module [mm]
num_teeth      = 24;       // Primary tooth count
pressure_angle = 20;       // Pressure angle [deg]
gear_height    = 10;       // Face width [mm]
backlash       = 0.10;     // Backlash per flank [mm]

hub_diameter   = 16;       // Hub OD [mm]
hub_height     = 14;       // Hub height [mm]
bore_diameter  = 8;        // Bore diameter [mm]
keyway_width   = 3;        // Keyway width [mm]
keyway_depth   = 1.8;      // Keyway radial depth [mm]

enable_spokes  = true;     // Weight-reduction pockets
spoke_count    = 5;        // Number of spokes
spoke_width    = 5;        // Spoke width [mm]
pocket_floor   = 1.5;      // Pocket floor [mm]

tip_chamfer    = 0.3;      // Tooth tip break edge [mm]
bore_chamfer   = 0.5;      // Bore chamfer [mm]

herringbone    = false;    // Enable double-helical geometry
helix_angle    = 25;       // Helix angle [deg]

/* [Mate Gear] */
mate_module_size    = 2;      // Mate module [mm]
mate_teeth          = 16;     // Mate tooth count
mate_pressure_angle = 20;     // Mate pressure angle [deg]
mate_gear_height    = 10;     // Mate face width [mm]
mate_backlash       = 0.10;   // Mate backlash [mm]

mate_hub_diameter   = 14;     // Mate hub OD [mm]
mate_hub_height     = 12;     // Mate hub height [mm]
mate_bore_diameter  = 6;      // Mate bore [mm]
mate_keyway_width   = 0;      // Mate keyway width [mm]
mate_keyway_depth   = 1.8;    // Mate keyway radial depth [mm]

mate_enable_spokes  = true;   // Mate spoke pockets
mate_spoke_count    = 4;      // Mate spoke count
mate_spoke_width    = 4;      // Mate spoke width [mm]
mate_pocket_floor   = 1.5;    // Mate pocket floor [mm]

mate_tip_chamfer    = 0.2;    // Mate tooth tip break edge [mm]
mate_bore_chamfer   = 0.4;    // Mate bore chamfer [mm]

mate_herringbone    = false;  // Mate herringbone mode
mate_helix_angle    = 25;     // Mate helix angle [deg]

/* [Preview] */
mesh_rotation_deg   = 10;     // Relative rotation for preview mode
show_centerline     = true;   // Show centre distance helper in pair modes

// ── Generic helpers ─────────────────────────────────────────
function resolved_mode() = show_mate ? "pair" : render_mode;
function pitch_radius(mod, teeth) = mod * teeth / 2;
function pitch_diameter(mod, teeth) = mod * teeth;
function base_radius(mod, teeth, pa) = pitch_radius(mod, teeth) * cos(pa);
function base_diameter(mod, teeth, pa) = pitch_diameter(mod, teeth) * cos(pa);
function addendum(mod) = mod;
function dedendum(mod) = 1.25 * mod;
function outside_radius(mod, teeth) = pitch_radius(mod, teeth) + addendum(mod);
function outside_diameter(mod, teeth) = 2 * outside_radius(mod, teeth);
function root_radius(mod, teeth) = pitch_radius(mod, teeth) - dedendum(mod);
function root_diameter(mod, teeth) = 2 * root_radius(mod, teeth);
function circular_pitch(mod) = mod * PI;
function base_pitch(mod, pa) = circular_pitch(mod) * cos(pa);
function recommended_min_teeth(pa) = ceil(2 / pow(sin(pa), 2));
function centre_distance(mod_a, teeth_a, mod_b, teeth_b) =
    pitch_radius(mod_a, teeth_a) + pitch_radius(mod_b, teeth_b);

function involute_intersect_angle(r, base_r) =
    r <= base_r ? 0 : sqrt(pow(r / base_r, 2) - 1) * 180 / PI;

function involute_point(base_r, t) =
    [base_r * (cos(t) + t * PI / 180 * sin(t)),
     base_r * (sin(t) - t * PI / 180 * cos(t))];

function tooth_flank_points(base_r, outer_r, steps = 24) = [
    for (i = [0 : steps])
        let(t_max = involute_intersect_angle(outer_r, base_r),
            t = i * t_max / steps)
        involute_point(base_r, t)
];

// ── 2D profiles ─────────────────────────────────────────────
module tooth_2d(mod, teeth, pa, backlash_mm, steps = 24) {
    pr = pitch_radius(mod, teeth);
    br = base_radius(mod, teeth, pa);
    rr = root_radius(mod, teeth);
    or_ = outside_radius(mod, teeth);
    half_thick_angle = 90 / teeth + involute_intersect_angle(pr, br);
    backlash_angle = backlash_mm / max(pr, 0.01) * 180 / PI;

    pts_r = tooth_flank_points(br, or_, steps);
    pts_l = [for (p = pts_r) [p[0], -p[1]]];

    rotate([0, 0, half_thick_angle - backlash_angle])
        polygon(concat(
            [[rr * cos(-1), rr * sin(-1)]],
            pts_r,
            [[or_ * cos(involute_intersect_angle(or_, br)),
              -or_ * sin(involute_intersect_angle(or_, br))]],
            [for (i = [len(pts_l) - 1 : -1 : 0]) pts_l[i]],
            [[rr * cos(1), -rr * sin(1)]]
        ));
}

module gear_2d(mod, teeth, pa, backlash_mm, bore_d) {
    difference() {
        union() {
            circle(r = root_radius(mod, teeth));
            for (i = [0 : teeth - 1])
                rotate([0, 0, i * 360 / teeth])
                    tooth_2d(mod, teeth, pa, backlash_mm);
        }
        circle(r = bore_d / 2);
    }
}

// ── Mechanical features ─────────────────────────────────────
module keyway_cut(bore_d, keyway_w, keyway_d, h) {
    if (keyway_w > 0)
        translate([bore_d / 2 - keyway_d, -keyway_w / 2, -1])
            cube([keyway_d + 0.5, keyway_w, h + 2]);
}

module spoke_pockets(mod, teeth, hub_d, spoke_n, spoke_w, pocket_floor_mm, h, enabled = true) {
    rr = root_radius(mod, teeth);

    if (enabled && spoke_n >= 3 && rr - hub_d / 2 > spoke_w * 2) {
        pocket_inner = hub_d / 2 + 2;
        pocket_outer = rr - mod * 2;
        pocket_angle = 360 / spoke_n;

        if (pocket_outer > pocket_inner + 4)
            translate([0, 0, pocket_floor_mm])
                difference() {
                    cylinder(h = h - pocket_floor_mm + 0.2, r = pocket_outer);
                    translate([0, 0, -0.5])
                        cylinder(h = h - pocket_floor_mm + 1.2, r = pocket_inner);

                    for (i = [0 : spoke_n - 1])
                        rotate([0, 0, i * pocket_angle])
                            translate([-spoke_w / 2, 0, -0.5])
                                cube([spoke_w, pocket_outer + 1, h - pocket_floor_mm + 1.2]);
                }
    }
}

module tip_chamfer_cut(outer_r, face_w, chamfer_mm) {
    if (chamfer_mm > 0)
        difference() {
            cylinder(r = outer_r + 1, h = face_w + 2);
            cylinder(r = outer_r, h = face_w + 2);
            cylinder(r1 = outer_r - chamfer_mm, r2 = outer_r, h = chamfer_mm);
            translate([0, 0, face_w - chamfer_mm])
                cylinder(r1 = outer_r, r2 = outer_r - chamfer_mm, h = chamfer_mm + 0.05);
        }
}

module hub_solid(hub_d, hub_h, bore_d, bore_chamfer_mm, keyway_w, keyway_d) {
    difference() {
        cylinder(h = hub_h, d = hub_d);
        cylinder(h = hub_h + 0.5, d = bore_d);

        if (bore_chamfer_mm > 0)
            translate([0, 0, hub_h - bore_chamfer_mm])
                cylinder(
                    h = bore_chamfer_mm + 0.1,
                    d1 = bore_d,
                    d2 = bore_d + bore_chamfer_mm * 2
                );

        keyway_cut(bore_d, keyway_w, keyway_d, hub_h);
    }
}

module gear_half(
    mod,
    teeth,
    pa,
    backlash_mm,
    face_w,
    bore_d,
    hub_d,
    hub_h,
    keyway_w,
    keyway_d,
    enable_spokes_flag,
    spoke_n,
    spoke_w,
    pocket_floor_mm,
    tip_chamfer_mm,
    bore_chamfer_mm,
    use_herringbone,
    helix_deg,
    twist_dir = 1
) {
    pr = pitch_radius(mod, teeth);
    or_ = outside_radius(mod, teeth);
    twist = use_herringbone ? twist_dir * tan(helix_deg) * face_w / max(pr, 0.01) * 180 / PI : 0;

    difference() {
        linear_extrude(height = face_w, twist = twist, convexity = 10)
            gear_2d(mod, teeth, pa, backlash_mm, bore_d);

        spoke_pockets(mod, teeth, hub_d, spoke_n, spoke_w, pocket_floor_mm, face_w, enable_spokes_flag);
        keyway_cut(bore_d, keyway_w, keyway_d, face_w);
        tip_chamfer_cut(or_, face_w, tip_chamfer_mm);
    }
}

module gear(
    mod,
    teeth,
    pa,
    backlash_mm,
    face_w,
    hub_d,
    hub_h,
    bore_d,
    keyway_w,
    keyway_d,
    enable_spokes_flag,
    spoke_n,
    spoke_w,
    pocket_floor_mm,
    tip_chamfer_mm,
    bore_chamfer_mm,
    use_herringbone,
    helix_deg
) {
    assert(mod > 0, "Module must be positive");
    assert(teeth >= 8, "Minimum 8 teeth for valid involute geometry");
    assert(face_w > 0, "Face width must be positive");
    assert(bore_d > 0, "Bore diameter must be positive");
    assert(hub_d > bore_d, "Hub diameter must be larger than bore");
    assert(root_radius(mod, teeth) > hub_d / 2 + 1,
           "Hub too large for selected tooth count/module");

    if (use_herringbone) {
        gear_half(
            mod, teeth, pa, backlash_mm, face_w / 2, bore_d, hub_d, hub_h,
            keyway_w, keyway_d, enable_spokes_flag, spoke_n, spoke_w,
            pocket_floor_mm, tip_chamfer_mm, bore_chamfer_mm, true, helix_deg, 1
        );
        translate([0, 0, face_w / 2])
            gear_half(
                mod, teeth, pa, backlash_mm, face_w / 2, bore_d, hub_d, hub_h,
                keyway_w, keyway_d, enable_spokes_flag, spoke_n, spoke_w,
                pocket_floor_mm, tip_chamfer_mm, bore_chamfer_mm, true, helix_deg, -1
            );
    } else {
        gear_half(
            mod, teeth, pa, backlash_mm, face_w, bore_d, hub_d, hub_h,
            keyway_w, keyway_d, enable_spokes_flag, spoke_n, spoke_w,
            pocket_floor_mm, tip_chamfer_mm, bore_chamfer_mm, false, helix_deg, 1
        );
    }

    hub_solid(hub_d, hub_h, bore_d, bore_chamfer_mm, keyway_w, keyway_d);
}

module center_distance_line(cd, z = 0) {
    if (show_centerline)
        color("OrangeRed", 0.6)
            translate([cd / 2, 0, z + 0.2])
                cube([cd, 0.8, 0.8], center = true);
}

module gear_pair(
    primary_module = module_size,
    primary_teeth = num_teeth,
    primary_pressure_angle = pressure_angle,
    primary_backlash = backlash,
    primary_face_width = gear_height,
    primary_hub_diameter = hub_diameter,
    primary_hub_height = hub_height,
    primary_bore_diameter = bore_diameter,
    primary_keyway_width = keyway_width,
    primary_keyway_depth = keyway_depth,
    primary_enable_spokes = enable_spokes,
    primary_spoke_count = spoke_count,
    primary_spoke_width = spoke_width,
    primary_pocket_floor = pocket_floor,
    primary_tip_chamfer = tip_chamfer,
    primary_bore_chamfer = bore_chamfer,
    primary_herringbone = herringbone,
    primary_helix_angle = helix_angle,
    secondary_module = mate_module_size,
    secondary_teeth = mate_teeth,
    secondary_pressure_angle = mate_pressure_angle,
    secondary_backlash = mate_backlash,
    secondary_face_width = mate_gear_height,
    secondary_hub_diameter = mate_hub_diameter,
    secondary_hub_height = mate_hub_height,
    secondary_bore_diameter = mate_bore_diameter,
    secondary_keyway_width = mate_keyway_width,
    secondary_keyway_depth = mate_keyway_depth,
    secondary_enable_spokes = mate_enable_spokes,
    secondary_spoke_count = mate_spoke_count,
    secondary_spoke_width = mate_spoke_width,
    secondary_pocket_floor = mate_pocket_floor,
    secondary_tip_chamfer = mate_tip_chamfer,
    secondary_bore_chamfer = mate_bore_chamfer,
    secondary_herringbone = mate_herringbone,
    secondary_helix_angle = mate_helix_angle
) {
    cd = centre_distance(primary_module, primary_teeth, secondary_module, secondary_teeth);
    resolved = resolved_mode();

    color(resolved == "mesh_preview" ? "SteelBlue" : "SteelBlue", 1.0)
        gear(
            primary_module, primary_teeth, primary_pressure_angle, primary_backlash, primary_face_width,
            primary_hub_diameter, primary_hub_height, primary_bore_diameter, primary_keyway_width, primary_keyway_depth,
            primary_enable_spokes, primary_spoke_count, primary_spoke_width, primary_pocket_floor, primary_tip_chamfer,
            primary_bore_chamfer, primary_herringbone, primary_helix_angle
        );

    color(resolved == "mesh_preview" ? "Tomato" : "CadetBlue", resolved == "mesh_preview" ? 0.55 : 1.0)
        translate([cd, 0, 0])
            rotate([0, 0, 180 / secondary_teeth + mesh_rotation_deg])
                gear(
                    secondary_module, secondary_teeth, secondary_pressure_angle, secondary_backlash, secondary_face_width,
                    secondary_hub_diameter, secondary_hub_height, secondary_bore_diameter, secondary_keyway_width, secondary_keyway_depth,
                    secondary_enable_spokes, secondary_spoke_count, secondary_spoke_width, secondary_pocket_floor, secondary_tip_chamfer,
                    secondary_bore_chamfer, secondary_herringbone, secondary_helix_angle
                );

    center_distance_line(cd, max(primary_face_width, secondary_face_width) / 2);
}

// ── Reporting ───────────────────────────────────────────────
module report_gear(label, mod, teeth, pa, face_w, hub_d, bore_d) {
    min_teeth = recommended_min_teeth(pa);

    echo(str("── ", label, " ─────────────────────────────"));
    echo(str("  Teeth:              ", teeth));
    echo(str("  Module:             ", mod, " mm"));
    echo(str("  Pressure angle:     ", pa, " deg"));
    echo(str("  Pitch diameter:     ", pitch_diameter(mod, teeth), " mm"));
    echo(str("  Outside diameter:   ", outside_diameter(mod, teeth), " mm"));
    echo(str("  Root diameter:      ", root_diameter(mod, teeth), " mm"));
    echo(str("  Base circle:        ", base_diameter(mod, teeth, pa), " mm"));
    echo(str("  Circular pitch:     ", circular_pitch(mod), " mm"));
    echo(str("  Base pitch:         ", base_pitch(mod, pa), " mm"));
    echo(str("  Face width:         ", face_w, " mm"));
    echo(str("  Hub / bore:         ", hub_d, " / ", bore_d, " mm"));

    if (teeth < min_teeth)
        echo(str("  WARNING: Tooth count below ~", min_teeth,
                 " for ", pa, " deg; undercut risk is high."));

    if (root_radius(mod, teeth) <= hub_d / 2 + 1)
        echo("  WARNING: Hub diameter is crowding the tooth root.");
}

module report_pair() {
    ratio = mate_teeth / num_teeth;
    cd = centre_distance(module_size, num_teeth, mate_module_size, mate_teeth);

    echo("── Pair Metrics ─────────────────────────");
    echo(str("  Ratio (mate / primary): ", ratio));
    echo(str("  Centre distance:        ", cd, " mm"));
    echo(str("  Pitch diameters:        ",
             pitch_diameter(module_size, num_teeth), " / ",
             pitch_diameter(mate_module_size, mate_teeth), " mm"));

    if (module_size != mate_module_size)
        echo("  WARNING: Modules do not match; pair is not manufacturing-compatible.");

    if (pressure_angle != mate_pressure_angle)
        echo("  WARNING: Pressure angles do not match; tooth action is not compatible.");

    if (abs(backlash - mate_backlash) > 0.15)
        echo("  WARNING: Backlash settings differ materially between the pair.");

    if (herringbone != mate_herringbone)
        echo("  WARNING: One gear is herringbone and the other is not.");

    if (herringbone && mate_herringbone && helix_angle != mate_helix_angle)
        echo("  WARNING: Herringbone helix angles do not match.");
}

// ── Render ──────────────────────────────────────────────────
mode = resolved_mode();
assert(mode == "single" || mode == "pair" || mode == "mesh_preview",
       "render_mode must be single, pair, or mesh_preview");
assert(module_size > 0 && num_teeth >= 8, "Primary gear needs positive module and at least 8 teeth");
assert(mate_module_size > 0 && mate_teeth >= 8, "Mate gear needs positive module and at least 8 teeth");

report_gear("Primary Gear", module_size, num_teeth, pressure_angle, gear_height, hub_diameter, bore_diameter);

if (mode == "single") {
    color("SteelBlue")
        gear(
            module_size, num_teeth, pressure_angle, backlash, gear_height,
            hub_diameter, hub_height, bore_diameter, keyway_width, keyway_depth,
            enable_spokes, spoke_count, spoke_width, pocket_floor, tip_chamfer,
            bore_chamfer, herringbone, helix_angle
        );
} else {
    report_gear("Mate Gear", mate_module_size, mate_teeth, mate_pressure_angle, mate_gear_height,
                mate_hub_diameter, mate_bore_diameter);
    report_pair();
    gear_pair();
}

// ============================================================
//  Parametric Involute Gear — OpenSCAD
//  Author: Portfolio Project
//  Description: Fully parametric spur gear with involute tooth
//               profile. Adjust parameters below to regenerate.
// ============================================================

/* [Gear Parameters] */
module_size   = 2;      // Gear module (tooth size)
num_teeth     = 24;     // Number of teeth
pressure_angle = 20;    // Pressure angle in degrees
gear_height   = 10;     // Thickness / height
hub_diameter  = 12;     // Central hub diameter
bore_diameter = 5;      // Shaft bore diameter
fillet_r      = 0.5;    // Root fillet radius

/* [Rendering] */
$fn = 120;              // Smoothness

// ── Derived values ───────────────────────────────────────────
pitch_radius     = module_size * num_teeth / 2;
base_radius      = pitch_radius * cos(pressure_angle);
addendum_radius  = pitch_radius + module_size;
dedendum_radius  = pitch_radius - 1.25 * module_size;

// ── Involute point at parameter t ───────────────────────────
function involute(r, t) =
    [r * (cos(t) + t * sin(t)),
     r * (sin(t) - t * cos(t))];

// ── Single involute tooth flank (right side) ─────────────────
function involute_points(n = 20) = [
    for (i = [0 : n])
        let(t = i * sqrt((addendum_radius/base_radius)^2 - 1) / n)
        involute(base_radius, t * 180 / PI)
];

// ── Full gear ────────────────────────────────────────────────
module gear_2d() {
    tooth_angle = 360 / num_teeth;
    half_thick  = asin(module_size / (2 * pitch_radius));

    difference() {
        union() {
            circle(r = dedendum_radius);
            for (i = [0 : num_teeth - 1]) {
                rotate([0, 0, i * tooth_angle])
                    tooth_profile(half_thick);
            }
        }
        // Bore hole
        circle(r = bore_diameter / 2);
    }
}

module tooth_profile(half_thick) {
    pts = involute_points(16);
    mirror_pts = [for (p = pts) [p[0], -p[1]]];

    rotate([0, 0, half_thick])
    polygon(concat(
        [[0, 0]],
        pts,
        [for (i = [len(pts)-1 : -1 : 0]) mirror_pts[i]],
        [[0, 0]]
    ));
}

// ── Hub ──────────────────────────────────────────────────────
module hub() {
    difference() {
        cylinder(h = gear_height * 1.4, d = hub_diameter, center = false);
        cylinder(h = gear_height * 2,   d = bore_diameter, center = true);
    }
}

// ── Final assembly ───────────────────────────────────────────
module spur_gear() {
    difference() {
        union() {
            linear_extrude(height = gear_height)
                gear_2d();
            hub();
        }
        // Key slot
        translate([-bore_diameter * 0.4, -0.8, -1])
            cube([bore_diameter * 0.4 + 0.2, 1.6, gear_height + 2]);
    }
}

spur_gear();

// ── Quick-render companion: mating gear ─────────────────────
// Uncomment to preview meshing pair
/*
translate([pitch_radius * 2, 0, 0])
    rotate([0, 0, 360 / num_teeth / 2])
        spur_gear();
*/

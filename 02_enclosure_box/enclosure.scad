// ============================================================
//  Parametric Electronics Enclosure — OpenSCAD
//  Author: Portfolio Project
//  Description: Snap-fit two-part enclosure with PCB standoffs,
//               cable gland cutouts, and lid retention pegs.
//               All dimensions driven by parameters.
// ============================================================

/* [Enclosure Dimensions] */
inner_w = 80;    // Inner width  (X)
inner_d = 60;    // Inner depth  (Y)
inner_h = 30;    // Inner height (Z), split between base + lid

/* [Wall & Features] */
wall        = 2.5;   // Wall thickness
base_ratio  = 0.65;  // Fraction of height for base (rest = lid)
corner_r    = 4;     // Outer corner radius
lip_h       = 3;     // Snap-fit lip height
lip_w       = 1.2;   // Lip width / interference

/* [PCB Standoffs] */
standoff_h  = 3;     // Height above floor
standoff_d  = 6;     // Outer diameter
screw_d     = 2.5;   // M2.5 screw bore
pcb_margin  = 4;     // Inset from inner wall

/* [Cable Glands] */
gland_d     = 8;     // Cutout diameter
gland_count = 2;     // Holes on rear wall

/* [Rendering] */
print_exploded = false;   // true = exploded view for preview
$fn = 64;

// ── Derived ─────────────────────────────────────────────────
outer_w  = inner_w + wall * 2;
outer_d  = inner_d + wall * 2;
base_h   = inner_h * base_ratio + wall;
lid_h    = inner_h * (1 - base_ratio) + wall;
explode  = print_exploded ? base_h + 10 : 0;

// ── Rounded box primitive ────────────────────────────────────
module rounded_box(w, d, h, r, center = false) {
    translate(center ? [-w/2, -d/2, -h/2] : [0,0,0])
    hull() {
        for (x = [r, w-r]) for (y = [r, d-r])
            translate([x, y, 0]) cylinder(r=r, h=h);
    }
}

// ── Standoff column ─────────────────────────────────────────
module standoff() {
    difference() {
        cylinder(h = standoff_h, d = standoff_d);
        cylinder(h = standoff_h + 1, d = screw_d);
    }
}

// ── Base shell ───────────────────────────────────────────────
module base() {
    difference() {
        rounded_box(outer_w, outer_d, base_h, corner_r);

        // Hollow interior
        translate([wall, wall, wall])
            cube([inner_w, inner_d, base_h]);

        // Cable gland cutouts on rear wall
        for (i = [1 : gland_count])
            translate([outer_w * i/(gland_count+1),
                       outer_d - 0.1,
                       base_h * 0.5])
                rotate([-90,0,0])
                    cylinder(h = wall+1, d = gland_d);
    }

    // PCB standoffs (4 corners)
    for (x = [pcb_margin + standoff_d/2,
              inner_w - pcb_margin - standoff_d/2])
        for (y = [pcb_margin + standoff_d/2,
                  inner_d - pcb_margin - standoff_d/2])
            translate([wall + x, wall + y, wall])
                standoff();

    // Snap-fit male lip around perimeter
    translate([wall - lip_w, wall - lip_w, base_h - lip_h])
        difference() {
            rounded_box(inner_w + lip_w*2,
                        inner_d + lip_w*2,
                        lip_h, corner_r - lip_w + 0.5);
            translate([lip_w, lip_w, -0.5])
                cube([inner_w, inner_d, lip_h + 1]);
        }
}

// ── Lid shell ────────────────────────────────────────────────
module lid() {
    difference() {
        rounded_box(outer_w, outer_d, lid_h, corner_r);

        // Hollow interior
        translate([wall + lip_w + 0.2,
                   wall + lip_w + 0.2,
                   wall])
            cube([inner_w - lip_w*2 - 0.4,
                  inner_d - lip_w*2 - 0.4,
                  lid_h]);

        // Snap-fit female groove
        translate([wall, wall, wall])
            difference() {
                cube([inner_w, inner_d, lip_h + 0.5]);
                translate([lip_w + 0.2, lip_w + 0.2, -0.5])
                    cube([inner_w - lip_w*2 - 0.4,
                          inner_d - lip_w*2 - 0.4,
                          lip_h + 2]);
            }
    }
}

// ── Assembly ─────────────────────────────────────────────────
base();
translate([0, 0, base_h + explode])
    rotate([180, 0, 0])
        translate([0, 0, -base_h - lid_h])
            lid();

# 01 · Parametric Wireless Resonant Charger

**Tool:** OpenSCAD ≥ 2021.01  
**Outputs:** `.stl` · `.dxf` · `.amf`

---

![Wireless Charger Preview](../assets/previews/wireless-charger-cover.png)

## Engineering Problem

Design a compact mains-powered wireless power transmitter that charges devices within a ~1 m radius without physical contact, using magnetic resonance coupling (WPT — Wireless Power Transfer). The geometry must be fully parametric so coil specifications, housing size, and field radius can all be adjusted from a single parameter block.

> **Why this matters:** magnetic resonance WPT (as developed in MIT's WiTricity research) works differently from inductive Qi charging: it uses resonant LC circuits tuned to the same frequency on transmitter and receiver, allowing energy transfer over distances well beyond the coil gap. This project models the transmitter side as a CAD prototype.

## Render Modes

| Mode | Description |
|---|---|
| `assembled` | Complete unit — housing, coil, PCB, LED ring |
| `exploded` | All layers separated vertically for inspection |
| `coil_only` | Transmission coil + ferrite shield only |
| `field_preview` | Assembled + charging radius sphere overlay |

## Core Parameters

| Group | Parameter | Default | Notes |
|---|---|---|---|
| Housing | `housing_diameter` | 120 mm | Outer shell diameter |
| Housing | `housing_height` | 32 mm | Total unit height |
| Housing | `fin_count` / `fin_height` | 16 / 4 mm | Passive cooling |
| Coil | `coil_inner_radius` | 18 mm | Winding start |
| Coil | `coil_outer_radius` | 46 mm | Winding end |
| Coil | `coil_turns` | 7 | Primary turn count |
| Coil | `wire_diameter` | 2.2 mm | Litz wire bundle |
| Coil | `coil_layers` | 2 | Stacked winding layers |
| Electronics | `cap_count` | 6 | Resonant capacitors |
| Electronics | `cap_height` | 16 mm | Electrolytic body |
| Field | `field_radius_mm` | 1000 mm | Charging range sphere |

## Computed Output (via echo)

The script computes and reports:

- **Wire length** — total estimated Litz wire needed [mm]
- **Inductance** — Wheeler flat-spiral approximation [μH]
- **Resonant frequency** — estimated operating frequency at 470 pF [kHz]
- **Warning flags** — inner radius clearance, housing fit, inductance floor

## What the Model Contains

**Housing base** — cylindrical shell with 16 passive cooling fins, IEC C8 power inlet cutout, bottom ventilation circle, and PCB standoffs with M3 boss geometry.

**Housing lid** — snap-fit retention tabs, LED diffuser ring channel, centre logo window, and ventilation hole ring.

**Transmission coil** — parametric flat Archimedean spiral in Litz wire geometry. Up to 3 stacked layers, reversing wind direction between layers to cancel axial flux components. Backed by a ferrite shielding disk to direct field forward.

**PCB module** — FR-4 board with resonant capacitor bank (6 ×), half-bridge MOSFET array (4 ×), main driver IC footprint, and coil connection pads.

**LED ring** — 24-bead indicator ring with diffuser channel, used to signal charging activity and field state.

## Usage

```bash
# Default assembled view
openscad wireless_charger.scad

# Exploded inspection view
openscad -o exploded.stl \
  -D 'render_mode="exploded"' \
  wireless_charger.scad

# Coil assembly only
openscad -o coil.stl \
  -D 'render_mode="coil_only"' \
  wireless_charger.scad

# Field preview — assembled + 1 m radius sphere
openscad -D 'render_mode="field_preview"' \
  wireless_charger.scad

# Adjust coil geometry
openscad -D 'coil_turns=10' \
  -D 'coil_outer_radius=55' \
  -D 'coil_layers=3' \
  wireless_charger.scad
```

## Case Study Notes

- **Constraint:** model a WPT transmitter that signals real engineering decisions — coil sizing, resonance tuning, thermal management — not just outer shape.
- **Decision:** use flat Archimedean spiral geometry because it is manufacturable as a wound PCB coil or a hand-wound Litz assembly, and its inductance is well-described by Wheeler's formula.
- **Thermal decision:** passive fins on the base face; the housing is designed to sit flat so convection flows up through the ventilation holes in the lid.
- **Limitation:** the model is geometry-first. It does not simulate field strength, SAR compliance, or power efficiency curves — those belong in electromagnetic simulation.

## Next-Step Realism

Natural upgrades: a receiver coil module (parametric, matched to primary), inter-coil coupling coefficient visualisation, PCB trace routing pass, and integration of EMC shielding geometry on the lid face.

# RwG DayZ SP Shader — Wiki

Custom **Substance 3D Painter** viewport shaders that make texturing for
**DayZ** less of a guessing game: see your metal/rough material the way DayZ's
**Super shader** and in-game light render it, and preview the DayZ **`_mc` macro**
live. Viewport only — nothing about your export changes.

> Each `##` section is self-contained and can become its own wiki page. Companion
> to the RwG DayZ Texture Exporter — tools & guides at
> [rwg-addon.com](https://rwg-addon.com/RwG-DayZ-SP-Plugin/).

---

## Table of contents

1. [Why these shaders](#why-these-shaders)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [`dayz-ingame` — DayZ in-game preview](#dayz-ingame--dayz-in-game-preview)
5. [Working with the plugin](#working-with-the-plugin)
6. [`pbr-metal-rough-mc` — metal/rough + macro](#pbr-metal-rough-mc--metalrough--macro)
7. [`dayz-super` — DayZ Super approximation](#dayz-super--dayz-super-approximation)
8. [The `_mc` macro preview](#the-_mc-macro-preview)
9. [Which shader when](#which-shader-when)
10. [How it works](#how-it-works)
11. [Troubleshooting & FAQ](#troubleshooting--faq)
12. [Known limitations](#known-limitations)
13. [Changelog](#changelog)
14. [Credits & license](#credits--license)

---

## Why these shaders

DayZ's Enfusion engine uses the **Super shader**: `_co` colour, an `_smdi` whose
G scales the reflection and whose B scales the highlight exponent, a physical
`fresnel(N,K)` stage, and a metal's hue in the rvmat's `specular[]`. Substance
Painter's default shader is **metal/rough**, so its viewport doesn't show you how
DayZ will read your maps. These shaders close that gap:

- **`dayz-ingame.glsl`** converts your channels live the way the RwG exporter
  does and renders them with a reimplementation of the Super shader and DayZ's
  measured in-game light.
- **`pbr-metal-rough-mc.glsl`** keeps normal metal/rough shading and adds a live
  preview of the DayZ `_mc` macro.
- **`dayz-super.glsl`** — the older, HDRI-based approximation (still included).

---

## Requirements

- **Substance 3D Painter.** The shaders compile as-is on current versions.
- For the `_mc` preview: the texture set needs **User0–User2** channels. Add them
  with the RwG exporter's *Prepare DayZ channels*, or manually in Texture Set
  Settings.
- Optional: the **RwG DayZ Texture Exporter** plugin (v0.6.0+) to send the rvmat
  values to `dayz-ingame`.

---

## Installation

1. Copy the `.glsl` file(s) into a Painter shelf `shaders` folder — simplest is
   the user shelf:
   ```
   C:\Users\<you>\Documents\Adobe\Adobe Substance 3D Painter\shelf\shaders\
   ```
2. Reload the shelf (right-click → *Reload*) or restart Painter. **Reload after
   every edit** — Painter caches compiled shaders.
3. **Texture Set Settings → Shader** → pick `dayz-ingame` (or one of the others).
4. The shader's parameters appear in **Shader Settings**.

See [`INSTALL.md`](INSTALL.md) for the full walkthrough.

---

## `dayz-ingame` — DayZ in-game preview

Keep painting metal/rough — materials and smart materials work unchanged. Per
pixel, the shader does what the export and the game would do:

1. **PBR → DayZ maps**, like the plugin's export: `_co` = base colour,
   `_smdi` G = `F0 / F0(fresnel N,K) × B`, `_smdi` B = `(2/r⁴ − 2) / specularPower`,
   `_as` G = AO, Painter's normal = `_nohq`.
2. **Super shader** with those maps: hemispherical sky/ground ambient, back light,
   Blinn-Phong with the engine's specular scale over `specularPower`, the physical
   complex-IOR `fresnel(N,K)` stage, terminator, AO and shadow handling like the
   game.
3. **In-game light**, measured with RenderDoc in DayZ: clear noon, morning,
   evening, dusk, overcast, half overcast, full-moon night, moonless night and the
   inventory preview. The sun is raised to ≥ 15° like in the engine; its direction
   follows Painter's environment rotation (Shift + drag). Output is clamped like
   the game's 8-bit scene buffer, then DayZ's filmic tone curve.

**Display settings:** the shader already outputs the final DayZ image. Set
Painter's tone mapping to **Linear** and turn its post effects (bloom, glare,
colour correction, vignette) off, or the image is tone-mapped twice.

**Reflections:** by default Painter's HDRI (clamped to 0…1 like DayZ's LDR env
maps). For the real look, convert a DayZ `env_*_co.paa` to PNG, load it as
*Environment texture* and enable *Use environment texture*.

| Group | Parameters |
|---|---|
| DayZ rvmat | `ambient[]`, `diffuse[]`, `forcedDiffuse[]`, `emmisive[]`, `specular[]`, `specularPower`, `fresnel N/K` |
| PBR to DayZ | `_smdi` method, G × gloss, G/B factors (1 = as exported), macro preview (User0–2) |
| DayZ light | light preset, direction from environment, exposure (EV), environment texture, filmic on/off |
| Debug | view `_co`, `_smdi` G, `_smdi` B, Fresnel stage, G × Fresnel, lighting only |

Not included: bloom, point lights, SSAO and the game's eye adaptation over time
(the DayZ Material Viewer has those).

---

## Working with the plugin

The **RwG DayZ Texture Exporter** (v0.6.0+) drives the shader from its RVMAT tab:

- **Live to DayZ In-Game shader** — every change of `ambient` … `specularPower`,
  fresnel N/K and the macro source goes to the shader while you edit.
- **To shader** — sends the current values once.
- **One instance per texture set.** The values go to the shader instance of the
  *active* texture set. If that instance is shared with other texture sets (or is
  Painter's default "Main shader"), the plugin first creates a copy named
  `DayZ <texture set>` and assigns it — so body, stock and magazine of a weapon
  each keep their own material.

Values you change in the **DayZ Material Viewer** come back into the plugin and
from there into the shader, so all three stay in sync.

---

## `pbr-metal-rough-mc` — metal/rough + macro

Standard metal/rough shading, plus a preview of a DayZ `_mc` macro from a **User**
channel. Controls (group *Macro (_mc) preview*):

| Parameter | Meaning |
|---|---|
| **Macro source** | User0 / User1 / User2 |
| **Preview mode** | *Unlit (always visible)* or *Blend into base (realistic)* |
| **Macro intensity** | 0…1 (0 = off = plain metal/rough) |
| **Mask** | *Auto (max RGB)* or *Luminance* |

---

## `dayz-super` — DayZ Super approximation

The first DayZ preview: Painter's IBL fed with a Fresnel-N/K tinted specular and
gloss from `1 − roughness`. Groups **DayZ Material**, **DayZ Specular**
(fresnel N/K, specular tint, level, gloss boost, specularPower, metal-from-base),
**DayZ Environment** (env intensity + tint) and **DayZ Macro (_mc)**. It follows
the plugin's older `_smdi` methods; for the current export use `dayz-ingame`.

---

## The `_mc` macro preview

DayZ's `_mc` lays a colour over the surface, blended by a mask. The shaders
preview that from a **User** channel, using the exporter's rule:

**Black = transparent, white = opaque.** The mask is the macro's own brightness
(`max(R,G,B)`), so paint the accents (e.g. brass rivets) on a **black** User0
background and only they show.

1. Add **User0–User2** (RwG exporter → *Prepare DayZ channels*).
2. Fill User0 **black**, paint the accent colour where it belongs.
3. Enable the macro preview and pick **User0**.

In `pbr-metal-rough-mc` / `dayz-super`, *Unlit* shows the macro flat on any
surface (to find accents), *Blend into base* mixes it in the DayZ way.

---

## Which shader when

- **Look-dev'ing a DayZ material before export** → `dayz-ingame` (with the
  plugin's *Live to DayZ In-Game shader*).
- **Painting a normal asset, want to see your `_mc` accents** → `pbr-metal-rough-mc`.
- `dayz-super` only for older projects set up with it.

---

## How it works

- **`dayz-ingame`** reads base colour, roughness, metallic, AO, normal and the
  User channels, builds `_co` / `_smdi` / `_as` per pixel with the export formulas,
  then evaluates the Super shader's lighting with the measured light table of the
  selected preset (sun, sky and ground colours, pre-exposed like the engine), the
  physical Fresnel stage and DayZ's tone curve.
- **`pbr-metal-rough-mc`** and **`dayz-super`** are derived from the stock
  `pbr-metal-rough` shader.
- **Viewport only** — none of this touches your exported maps or `.rvmat`.

---

## Troubleshooting & FAQ

**Shader isn't in the dropdown.** — Reload the shelf or restart Painter after
copying the `.glsl`.

**Assigned it, but normal shading and its parameters are missing.** — It failed
to compile; open **Window → Views → Log**, re-assign, read the GLSL error line.

**`dayz-ingame` looks washed out / too contrasty.** — Painter's own tone mapping
or post effects are still on. Set tone mapping to Linear, post effects off.

**All texture sets show the same values.** — They share one shader instance. Click
**To shader** in the plugin once per texture set; each gets `DayZ <texture set>`.

**Macro doesn't show.** — Make sure the User channel exists and is painted, and
that the macro preview is enabled. The background must be black.

---

## Known limitations

- `dayz-ingame` matches the Super shader's lighting maths and the measured light
  presets, but Painter's mesh, normals and HDRI are not DayZ's: no bloom, point
  lights, SSAO or eye adaptation. For a pixel-identical check use the DayZ
  Material Viewer or Buldozer.
- The Painter shader API varies slightly between versions; if a helper name
  differs, a shader may need a one-line tweak.

---

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md). **v0.2.0** — `dayz-ingame` (Super shader +
measured in-game light), plugin link with one instance per texture set.
**v0.1.0** — `dayz-super` and `pbr-metal-rough-mc` with the `_mc` macro preview.

---

## Credits & license

Built by **RwG** for the DayZ modding community. Non-commercial license — free to
use, share and adapt with credit; not for sale; all IP stays with RwG. Anything
you make with it is yours. See [`LICENSE`](LICENSE).

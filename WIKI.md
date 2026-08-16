# RwG DayZ SP Shader — Wiki

Two custom **Substance 3D Painter** viewport shaders that make texturing for
**DayZ** less of a guessing game: preview the DayZ **Super-shader** look while you
paint in metal/rough, and preview the DayZ **`_mc` macro** live. Viewport only —
nothing about your export changes.

> Each `##` section is self-contained and can become its own wiki page. Companion
> to the RwG DayZ Texture Exporter — tools & guides at
> [rwg-addon.com](https://rwg-addon.com/RwG-DayZ-SP-Plugin/).

---

## Table of contents

1. [Why these shaders](#why-these-shaders)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [`pbr-metal-rough-mc` — metal/rough + macro](#pbr-metal-rough-mc--metalrough--macro)
5. [`dayz-super` — DayZ Super preview](#dayz-super--dayz-super-preview)
6. [The `_mc` macro preview](#the-_mc-macro-preview)
7. [Which shader when](#which-shader-when)
8. [Getting closer to the game look](#getting-closer-to-the-game-look)
9. [How it works](#how-it-works)
10. [Troubleshooting & FAQ](#troubleshooting--faq)
11. [Known limitations](#known-limitations)
12. [Changelog](#changelog)
13. [Credits & license](#credits--license)

---

## Why these shaders

DayZ's Enfusion engine uses the **Super shader** — a **specular/glossiness**
model where a metal's colour lives in the material's specular tint, not its
albedo. Substance Painter's default shader is **metal/rough**, so its viewport
doesn't show you how DayZ will read your maps: metals look wrong, the `_mc` macro
isn't visible at all. These shaders close that gap:

- **`dayz-super.glsl`** shades the surface the DayZ way (tinted, Fresnel-driven
  specular; gloss from `1 − roughness`), so the viewport ≈ the in-game look.
- **`pbr-metal-rough-mc.glsl`** keeps normal metal/rough shading but adds a live
  preview of the DayZ `_mc` macro.

Both are **viewport only** and are companions to the RwG DayZ Texture Exporter —
the DayZ shader's parameters mirror that plugin's `.rvmat` editor.

---

## Requirements

- **Substance 3D Painter.** Both shaders are built from the stock
  `pbr-metal-rough` shader and compile as-is on current versions.
- For the `_mc` preview: the texture set needs **User0–User2** channels. Add them
  with the RwG exporter's *Prepare DayZ channels*, or manually in Texture Set
  Settings.

---

## Installation

1. Copy the `.glsl` file(s) into a Painter shelf `shaders` folder — simplest is
   the user shelf:
   ```
   C:\Users\<you>\Documents\Adobe\Adobe Substance 3D Painter\shelf\shaders\
   ```
2. Reload the shelf (right-click → *Reload*) or restart Painter. **Reload after
   every edit** — Painter caches compiled shaders.
3. **Texture Set Settings → Shader** → pick `dayz-super` or `pbr-metal-rough-mc`.
4. The shader's parameters appear in **Shader Settings**.

See [`INSTALL.md`](INSTALL.md) for the full walkthrough.

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

Use it to spot where your macro lands while you paint, without changing the
familiar metal/rough shading.

---

## `dayz-super` — DayZ Super preview

Previews the DayZ / Enfusion Super shading. Parameters are grouped to match the
`.rvmat` editor; defaults are neutral, so a fresh assign looks like plain
metal/rough until you dial values in.

**DayZ Material**

| Parameter | `.rvmat` field |
|---|---|
| ambient | `ambient[]` |
| diffuse | `diffuse[]` |
| forcedDiffuse (unlit constant) | `forcedDiffuse[]` |
| emmisive tint + intensity | `emmisive[]` |

**DayZ Specular**

| Parameter | `.rvmat` field |
|---|---|
| fresnel N / fresnel K → F0 | `fresnel(N,K)` |
| specular tint (the metal colour) | `specular[]` |
| specular level (G) | `_smdi` G |
| gloss (B) boost | `_smdi` B |
| specularPower | `specularPower` |
| metal spec from base colour | `_smdi` PBR method |

**DayZ Environment** — env intensity + env tint (the viewport uses the scene
HDRI as the Stage7 stand-in).

**DayZ Macro (_mc)** — Show macro, Macro source, Macro mode (*Unlit* / *Blend into
base*), intensity, mask.

Suggested starting values: **Brass** tint `0.91,0.74,0.42` N`0.44` K`3.0`;
**Copper** `0.95,0.64,0.54` N`2.08` K`7.15`; **Steel/Iron** near-white N`3.12`
K`3.87`; **dielectric** white N`1.5` K`0`. Same numbers as the exporter's material
presets.

---

## The `_mc` macro preview

DayZ's `_mc` lays a colour over the surface, blended by a mask. These shaders
preview that from a **User** channel, using the exporter's rule:

**Black = transparent, white = opaque.** The mask is the macro's own brightness
(`max(R,G,B)`), so paint the accents (e.g. brass rivets) on a **black** User0
background and only they show.

Steps:

1. Add **User0–User2** (RwG exporter → *Prepare DayZ channels*).
2. Fill User0 **black**, paint the accent colour where it belongs.
3. Assign the shader, set **Macro source = User0**, **Macro mode = Unlit**,
   **intensity = 1**.

**Unlit vs Blend:** *Unlit* fades the shaded surface out where the macro sits and
adds the pure macro colour — visible on **any** surface (incl. pure metal), always
saturated; use it to *find* accents. *Blend into base* mixes the macro into the
base colour the DayZ way (on metal it then shows only in the reflection) — use it
for the realistic look.

---

## Which shader when

- **Painting a normal asset, want to see your `_mc` accents** → `pbr-metal-rough-mc`.
- **Look-dev'ing a DayZ material (metal colour, gloss, fresnel) before export** →
  `dayz-super` (it also has the macro preview).

---

## Getting closer to the game look

Load a DayZ-ish **HDRI** in Painter's *Display Settings* — an outdoor, slightly
overcast environment is a good stand-in for the DayZ `env_land` cubemap. Adjust
exposure/rotation; the `dayz-super` shader honours it through **env intensity**.
It's an approximation: Painter uses HDRI-based IBL, DayZ its own ambient / env
cubemaps / tonemap / post — close, never pixel-identical.

---

## How it works

- Both shaders are derived from the stock **`pbr-metal-rough`** shader, so the
  base pipeline (parallax, normal, AO, emissive, SSS) is unchanged.
- **`dayz-super`** replaces the specular colour with a **Fresnel-N/K F0**, tinted
  by the specular tint and scaled by the specular level; gloss = `1 − roughness`
  with a `specularPower` tightening factor; ambient/diffuse/forcedDiffuse/emmisive
  applied as the DayZ material vectors; the reflected environment tinted/scaled.
- **`_mc`** reads the selected User channel via `textureSparse`, computes the mask
  (`max(R,G,B)` or luminance), and either blends it into the base colour (realistic)
  or fades the shaded surface and adds it unlit (find accents).
- **Viewport only** — none of this touches your exported maps or `.rvmat`.

---

## Troubleshooting & FAQ

**Shader isn't in the dropdown.** — Reload the shelf (right-click → Reload) or
restart Painter after copying the `.glsl`.

**Assigned it, but nothing/normal shading, and its parameters are missing.** —
It failed to compile and Painter fell back to a default shader. Open **Window →
Views → Log**, re-assign, and read the GLSL error line.

**Macro doesn't show.** — Set **Macro mode = Unlit**, **intensity = 1**, and make
sure the **User channel exists and is painted** (check via the viewport channel
view → User0). On pure metal, *Blend* mode shows the macro only in reflections —
use *Unlit*.

**Macro colour looks pale.** — Fixed in Unlit mode (the surface under the macro is
faded so the colour stays saturated). If you're in *Blend* mode over a white/empty
base, that's expected — switch to Unlit.

**The whole object turned one colour.** — Your User0 background wasn't black.
Black = transparent; paint the macro on black.

---

## Known limitations

- An **approximation**, not a 1:1 match to the in-game render.
- The Painter shader API varies slightly between versions; if a helper name
  differs, the shader may need a one-line tweak (see Troubleshooting).
- *Blend into base* on pure metal shows the macro only via the reflection (that's
  DayZ-accurate) — use *Unlit* to see it flat.

---

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md). **v0.1.0** — first release: `dayz-super` and
`pbr-metal-rough-mc`, both with the `_mc` macro preview (Unlit / Blend).

---

## Credits & license

Built by **RwG** for the DayZ modding community. Non-commercial license — free to
use, share and adapt with credit; not for sale; all IP stays with RwG. Anything
you make with it is yours. See [`LICENSE`](LICENSE).

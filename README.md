# RwG DayZ Substance Painter viewport shaders

> **Preview · v0.1.0**

Two custom **Substance 3D Painter** viewport shaders for DayZ authoring. You keep
painting in the normal **PBR metal/rough** workflow; these change how Painter
*previews* the surface — closer to how DayZ will actually render it, and with a
live preview of the DayZ **`_mc` macro**.

- **`dayz-super.glsl`** — previews the DayZ / Enfusion **"Super" shading** (a
  Fresnel-N/K driven, tinted specular, gloss from `1 − roughness`), plus a
  **DayZ Macro (_mc)** group.
- **`pbr-metal-rough-mc.glsl`** — the standard metal/rough shading **plus a live
  `_mc` macro preview**.

Both are **viewport only** — they change nothing on export. They're companions to
the **RwG DayZ Texture Exporter** plugin: the DayZ shader's parameters mirror that
plugin's `.rvmat` editor.

---

## `pbr-metal-rough-mc.glsl` — metal/rough + macro preview

Normal metal/rough shading, plus a preview of a DayZ `_mc` macro from a **User**
channel. The chosen User channel (User0 / User1 / User2) is shown over the
surface using the **same mask rule as the exporter's "Auto (macro)"** —
`max(R,G,B)`, so **black = transparent, white = opaque**. Paint the macro on
black and your accents (e.g. brass rivets) appear in the shaded viewport while
everything else keeps the base texture.

**Parameters (group *Macro (_mc) preview*):**

| Parameter | Meaning |
|---|---|
| **Macro source** | User0 / User1 / User2 |
| **Preview mode** | *Unlit (always visible)* — flat, saturated, visible on any surface incl. pure metal; *Blend into base (realistic)* — mixes into the base colour (metals show it only in the reflection) |
| **Macro intensity** | 0…1 (0 = off = plain metal/rough) |
| **Mask** | *Auto (max RGB)* or *Luminance* |

Use this when you just want to see where your macro lands while painting.

---

## `dayz-super.glsl` — DayZ "Super" preview

Preview the surface the way the DayZ / Enfusion Super shader will treat it — the
metal colour riding in a tinted, **Fresnel N/K** driven specular, dielectrics on
the `0.04` floor, gloss from `1 − roughness`. The missing "what-you-see-is-close-
to-what-you-get" preview, so you stop guessing how the game reads your maps.

### What it is (and isn't)

- **Viewport only** — export is unchanged.
- An **approximation**, not a 1:1 match. DayZ has its own ambient, env cubemaps,
  tonemap and post; Painter uses an HDRI-based IBL. Close, not pixel-identical.
- It reuses Painter's IBL and feeds it a **DayZ-style specular colour + gloss**
  instead of the standard metal/rough specular.

### Parameters

Grouped to match the `.rvmat` editor. Defaults are neutral, so a fresh assign
looks like plain metal/rough until you dial values in.

**DayZ Material** — the material colour vectors:

| Parameter | `.rvmat` field |
|---|---|
| **ambient** | `ambient[]` |
| **diffuse** | `diffuse[]` |
| **forcedDiffuse** (unlit constant) | `forcedDiffuse[]` |
| **emmisive tint** + **emmisive intensity** | `emmisive[]` |

**DayZ Specular** — the reflectance model:

| Parameter | `.rvmat` field |
|---|---|
| **fresnel N** / **fresnel K** → F0 | `fresnel(N,K)` |
| **specular tint** (the metal colour) | `specular[]` |
| **specular level (G)** | `_smdi` G slider |
| **gloss (B) boost** | `_smdi` B slider |
| **specularPower** (highlight tightness) | `specularPower` |
| **metal spec from base colour** | `_smdi` PBR method |

**DayZ Environment** — Stage7 stand-in (viewport uses the scene HDRI):

| Parameter | Notes |
|---|---|
| **env intensity** | strength of the reflected environment |
| **env tint** | colour cast of the reflection (approximates a warmer/cooler env) |

**DayZ Macro (_mc)** — preview a User channel as the macro (black = transparent):

| Parameter | Notes |
|---|---|
| **Show macro (_mc)** | on/off (off by default) |
| **Macro source** | User0 / User1 / User2 |
| **Macro mode** | *Unlit (find accents)* or *Blend into base (DayZ)* |
| **Macro intensity** / **Macro mask** | 0…1 · Auto max-RGB / Luminance |

### Suggested starting values

- **Brass**: tint `~0.91, 0.74, 0.42`, N `0.44`, K `3.0`.
- **Copper**: tint `~0.95, 0.64, 0.54`, N `2.08`, K `7.15`.
- **Steel / Iron**: tint near white, N `3.12`, K `3.87`.
- **Painted / plastic / dielectric**: tint white, N `1.5`, K `0`.

Same numbers as the exporter's material presets — save them there as **My
presets** and you have a matching pair on both sides.

### Getting closer to the game look

Load a DayZ-ish outdoor/overcast **HDRI** in Painter's *Display Settings* (a
stand-in for the DayZ `env_land` cubemap) and tune exposure/rotation. The shader
honours it through **env intensity**.

---

## Which shader to use

- **Just painting a normal asset and want to spot your `_mc` accents?** →
  `pbr-metal-rough-mc`.
- **Look-dev'ing a DayZ material (metal colour, gloss, fresnel) before you
  export the `.rvmat`?** → `dayz-super` (it also has the macro preview).

---

## Install & use

See [`INSTALL.md`](INSTALL.md). Short version: drop the `.glsl` into a Painter
shelf `shaders` folder, reload the shelf, then **Texture Set Settings → Shader →**
pick the shader. Its parameters appear in the Shader Settings.

---

## License

Non-commercial — see [`LICENSE`](LICENSE). Free to use, share and adapt with
credit to **RwG**; not for sale. Anything you make with it (your textures /
`.rvmat`) is entirely yours. Tools & guides: [rwg-addon.com](https://rwg-addon.com/RwG-DayZ-SP-Plugin/).

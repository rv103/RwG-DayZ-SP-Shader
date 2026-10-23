# Changelog

## Unreleased

- **`dayz-ingame-specgloss.glsl`** (new) — `dayz-ingame` for spec/gloss texture
  sets: `_co` from Base Color or Diffuse, `_smdi` G from Specular Level or
  Specular, B from Glossiness; `_smdi` method *Direct* (as painted, the classic
  Arma/DayZ way) or *PBR spec/gloss, DayZ shader-matched*.

## v0.2.0 (2026-10-21)

- **`dayz-ingame.glsl`** (new) — a reimplementation of DayZ's Super shader and
  in-game light, measured with RenderDoc: metal/rough channels converted per pixel
  like the RwG exporter (`_co` = base colour, DayZ shader-matched `_smdi`,
  `_as` = AO), sky/ground ambient, engine specular scale, physical complex-IOR
  `fresnel(N,K)`, nine light presets (clear day to moonless night, inventory
  preview), 8-bit clamp and DayZ's filmic tone curve, optional DayZ env texture,
  debug views.
- **Plugin link** (RwG DayZ Texture Exporter v0.6.0): *Live to DayZ In-Game
  shader* / *To shader* send the rvmat values to the active texture set's
  instance; shared instances are split into `DayZ <texture set>`.
- `dayz-super` stays as the older approximation.

## v0.1.0 — Preview (2026-08-15)

First release — two Substance 3D Painter viewport shaders for DayZ authoring.

- **`dayz-super.glsl`** — previews the DayZ / Enfusion "Super" shading: a
  Fresnel-N/K driven tinted specular, dielectric `0.04` floor, gloss from
  `1 − roughness`. Parameter groups mirror the RwG `.rvmat` editor: **DayZ
  Material** (ambient / diffuse / forcedDiffuse / emmisive), **DayZ Specular**
  (fresnel N/K, specular tint, level, gloss, specularPower, metal-from-basecolor),
  **DayZ Environment** (env intensity + tint), and **DayZ Macro (_mc)**.
- **`pbr-metal-rough-mc.glsl`** — standard metal/rough shading plus a live `_mc`
  macro preview from a User channel.
- **`_mc` macro preview** in both: reads User0/1/2, uses the exporter's mask rule
  (`max(R,G,B)`, black = transparent), with **Unlit** (always visible, incl. pure
  metal — the shaded surface is faded where the macro sits so the colour stays
  saturated) and **Blend into base** modes, plus intensity and mask (Auto /
  Luminance).
- Viewport-only; export is unchanged. Built from the stock `pbr-metal-rough`
  shader.

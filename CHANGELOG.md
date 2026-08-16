# Changelog

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

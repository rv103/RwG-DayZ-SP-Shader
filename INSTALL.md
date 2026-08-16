# Install — RwG DayZ Substance Painter shaders

Applies to both **`dayz-super.glsl`** and **`pbr-metal-rough-mc.glsl`**.

## 1. Copy the shader(s) into a Painter shelf

Substance Painter loads `.glsl` shaders from a `shaders` folder inside any shelf.
The simplest is your **user shelf**:

```
Windows:
C:\Users\<you>\Documents\Adobe\Adobe Substance 3D Painter\shelf\shaders\
```

Create the `shaders` subfolder if it isn't there, and copy the `.glsl` file(s)
into it. (Any folder Painter watches as a shelf works; the user shelf is the safe
default.)

## 2. Reload / restart

Restart Substance Painter, or in the **Shelf** right-click → *Reload*. The shaders
now appear under **Shaders** in the shelf. **Reload the shelf after every edit** —
Painter caches the compiled shader.

## 3. Assign it to your texture set

**Texture Set Settings → Shader** dropdown → pick **`dayz-super`** or
**`pbr-metal-rough-mc`**. The viewport switches immediately.

## 4. Tune the parameters

The shader's controls appear in **Shader Settings** (bottom of Texture Set
Settings):

- `dayz-super` — groups **DayZ Material / DayZ Specular / DayZ Environment / DayZ
  Macro (_mc)**.
- `pbr-metal-rough-mc` — group **Macro (_mc) preview**.

## 5. Preview the `_mc` macro

For the macro preview you need the **User0–User2** channels in the texture set
(the RwG exporter's *Prepare DayZ channels* adds them). Paint the macro on a
**black** background (black = transparent), set **Macro source = User0**, and —
for guaranteed visibility on any surface — **Macro mode = Unlit**.

## 6. A DayZ-ish environment (optional, recommended for `dayz-super`)

In **Display Settings**, load an outdoor/overcast HDRI as the environment and
adjust exposure/rotation. It stands in for the DayZ `env_land` reflection.

## Troubleshooting — shader won't compile / no effect

Painter's shader API differs slightly between versions.

1. Open the **Log** (Window → Views → Log) right after assigning the shader — a
   compile error there means Painter fell back to a default shader (you'll see
   normal shading but none of the shader's parameters).
2. If the parameters *do* appear but the macro doesn't show: make sure the User
   channel exists and is painted (check via the viewport channel view → User0),
   and that **Macro intensity > 0** with **mode = Unlit**.
3. Send the log line to RwG for a version fix — the shading math stays the same,
   only API helper names change.

Both shaders are built from the stock `pbr-metal-rough` shader, so on current
Painter versions they compile as-is.

## Requirements

- Substance 3D Painter (PySide6 on 2024+, PySide2 on older — irrelevant to the
  GLSL). The `_mc` preview reads **User** channels; add them with *Prepare DayZ
  channels* in the RwG exporter, or manually in Texture Set Settings.

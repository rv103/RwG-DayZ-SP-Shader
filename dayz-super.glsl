/*
 * RwG DayZ Super - Substance 3D Painter viewport shader
 * -----------------------------------------------------------------------------
 * Paint in the normal PBR (metal/rough) workflow, but preview the surface the
 * way the DayZ / Enfusion "Super" shader treats it. The parameter set mirrors
 * the RwG DayZ Texture Exporter .rvmat editor as closely as a viewport shader
 * can: ambient / diffuse / forcedDiffuse / emmisive tints, a Fresnel-N/K driven
 * specular with tint + level + gloss + specularPower, and an environment tint.
 * It also previews the DayZ _mc macro from a User channel (black = transparent):
 * "Blend into base (DayZ)" mixes it in the DayZ way, "Unlit" shows accents flat.
 *
 * It reuses Painter's own IBL, so it is an APPROXIMATION of the in-game look -
 * close enough to author against, never a 1:1 match (the game has its own
 * ambient / env cubemaps / tonemap / post). Viewport only; export is unchanged.
 *
 * Built from the stock pbr-metal-rough shader; only the material response is
 * replaced with the DayZ model. Defaults are all neutral, so a fresh assign
 * looks like plain metal/rough until you dial the DayZ values in.
 *
 * Non-commercial license - see LICENSE. (c) RwG.
 */

import lib-sss.glsl
import lib-pbr.glsl
import lib-emissive.glsl
import lib-pom.glsl
import lib-utils.glsl
import lib-sampler.glsl

// --- PBR channels (same inputs as the standard metal/rough shader) ---------- //
//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;
//: param auto channel_metallic
uniform SamplerSparse metallic_tex;
//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;

// --- User channels used as the _mc macro source ----------------------------- //
//: param auto channel_user0
uniform SamplerSparse user0_tex;
//: param auto channel_user1
uniform SamplerSparse user1_tex;
//: param auto channel_user2
uniform SamplerSparse user2_tex;

// =========================================================================== //
//  DayZ material colours  (mirror ambient/diffuse/forcedDiffuse/emmisive)      //
// =========================================================================== //
//: param custom {
//:   "default": [1.0, 1.0, 1.0],
//:   "label": "ambient",
//:   "widget": "color",
//:   "group": "DayZ Material"
//: }
uniform vec3 u_ambient;

//: param custom {
//:   "default": [1.0, 1.0, 1.0],
//:   "label": "diffuse",
//:   "widget": "color",
//:   "group": "DayZ Material"
//: }
uniform vec3 u_diffuse;

//: param custom {
//:   "default": [0.0, 0.0, 0.0],
//:   "label": "forcedDiffuse",
//:   "widget": "color",
//:   "group": "DayZ Material"
//: }
uniform vec3 u_forced_diffuse;

//: param custom {
//:   "default": [1.0, 1.0, 1.0],
//:   "label": "emmisive tint",
//:   "widget": "color",
//:   "group": "DayZ Material"
//: }
uniform vec3 u_emissive_tint;

//: param custom {
//:   "default": 1.0,
//:   "label": "emmisive intensity",
//:   "min": 0.0,
//:   "max": 8.0,
//:   "group": "DayZ Material"
//: }
uniform float u_emissive_intensity;

// =========================================================================== //
//  DayZ specular  (fresnel N/K, tint, level, gloss, specularPower, metal src)  //
// =========================================================================== //
//: param custom {
//:   "default": 1.5,
//:   "label": "fresnel N",
//:   "min": 0.0,
//:   "max": 12.0,
//:   "group": "DayZ Specular"
//: }
uniform float u_fresnel_n;

//: param custom {
//:   "default": 0.0,
//:   "label": "fresnel K",
//:   "min": 0.0,
//:   "max": 12.0,
//:   "group": "DayZ Specular"
//: }
uniform float u_fresnel_k;

//: param custom {
//:   "default": [1.0, 1.0, 1.0],
//:   "label": "specular tint",
//:   "widget": "color",
//:   "group": "DayZ Specular"
//: }
uniform vec3 u_spec_tint;

//: param custom {
//:   "default": 1.0,
//:   "label": "specular level (G)",
//:   "min": 0.0,
//:   "max": 2.0,
//:   "group": "DayZ Specular"
//: }
uniform float u_spec_level;

//: param custom {
//:   "default": 1.0,
//:   "label": "gloss (B) boost",
//:   "min": 0.0,
//:   "max": 2.0,
//:   "group": "DayZ Specular"
//: }
uniform float u_gloss_boost;

//: param custom {
//:   "default": 60.0,
//:   "label": "specularPower",
//:   "min": 1.0,
//:   "max": 1000.0,
//:   "group": "DayZ Specular"
//: }
uniform float u_spec_power;

//: param custom {
//:   "default": false,
//:   "label": "metal spec from base colour",
//:   "group": "DayZ Specular"
//: }
uniform bool u_metal_from_basecolor;

// =========================================================================== //
//  Environment (Stage7 stand-in - viewport uses the scene HDRI)                //
// =========================================================================== //
//: param custom {
//:   "default": 1.0,
//:   "label": "env intensity",
//:   "min": 0.0,
//:   "max": 3.0,
//:   "group": "DayZ Environment"
//: }
uniform float u_env_intensity;

//: param custom {
//:   "default": [1.0, 1.0, 1.0],
//:   "label": "env tint",
//:   "widget": "color",
//:   "group": "DayZ Environment"
//: }
uniform vec3 u_env_tint;

// =========================================================================== //
//  DayZ Macro (_mc) - preview a User channel as the macro overlay              //
// =========================================================================== //
//: param custom {
//:   "default": false,
//:   "label": "Show macro (_mc)",
//:   "group": "DayZ Macro (_mc)"
//: }
uniform bool u_mc_show;

//: param custom {
//:   "default": 0,
//:   "label": "Macro source",
//:   "widget": "combobox",
//:   "values": { "User0": 0, "User1": 1, "User2": 2 },
//:   "group": "DayZ Macro (_mc)"
//: }
uniform int u_mc_source;

//: param custom {
//:   "default": 0,
//:   "label": "Macro mode",
//:   "widget": "combobox",
//:   "values": { "Unlit (find accents)": 0, "Blend into base (DayZ)": 1 },
//:   "group": "DayZ Macro (_mc)"
//: }
uniform int u_mc_mode;

//: param custom {
//:   "default": 1.0,
//:   "label": "Macro intensity",
//:   "min": 0.0,
//:   "max": 1.0,
//:   "group": "DayZ Macro (_mc)"
//: }
uniform float u_mc_intensity;

//: param custom {
//:   "default": 0,
//:   "label": "Macro mask",
//:   "widget": "combobox",
//:   "values": { "Auto (max RGB)": 0, "Luminance": 1 },
//:   "group": "DayZ Macro (_mc)"
//: }
uniform int u_mc_mask;

// Read the selected User channel (no #ifdef: some Painter versions don't define
// channel_userN, which would silently compile the macro out).
vec3 sampleMacro(SparseCoord coord)
{
    if (u_mc_source == 1) return textureSparse(user1_tex, coord).rgb;
    if (u_mc_source == 2) return textureSparse(user2_tex, coord).rgb;
    return textureSparse(user0_tex, coord).rgb;
}

// Reflectance at normal incidence from a complex index of refraction (N, K).
// Dielectric (N=1.5, K=0) -> ~0.04; conductors go high. This scalar tints the
// specular the DayZ way.
float dayzF0(float n, float k)
{
    float num = (n - 1.0) * (n - 1.0) + k * k;
    float den = (n + 1.0) * (n + 1.0) + k * k;
    return clamp(num / max(den, 1e-4), 0.0, 1.0);
}

void shade(V2F inputs)
{
    // Parallax occlusion mapping (height), same as the stock shader.
    vec3 viewTS = worldSpaceToTangentSpace(getEyeVec(inputs.position), inputs);
    applyParallaxOffset(inputs, viewTS);

    // PBR inputs.
    float roughness   = getRoughness(roughness_tex, inputs.sparse_coord);
    vec3  baseColor   = getBaseColor(basecolor_tex, inputs.sparse_coord);
    float metallic    = getMetallic(metallic_tex, inputs.sparse_coord);
    float specLevelCh = getSpecularLevel(specularlevel_tex, inputs.sparse_coord);

    // --- DayZ macro (_mc) -----------------------------------------------------
    // Mask rule matches the exporter's "Auto (macro)" alpha: black = transparent.
    // "Blend into base (DayZ)" mixes it into the base colour BEFORE shading (so it
    // also drives the metal specular tint, the DayZ way). "Unlit" shows it flat.
    vec3  macro = sampleMacro(inputs.sparse_coord);
    float macroAmount = 0.0;
    if (u_mc_show && u_mc_intensity > 0.0)
    {
        float mask = (u_mc_mask == 1)
            ? dot(macro, vec3(0.299, 0.587, 0.114))
            : max(macro.r, max(macro.g, macro.b));
        macroAmount = clamp(mask * u_mc_intensity, 0.0, 1.0);
        if (u_mc_mode == 1)
            baseColor = mix(baseColor, macro, macroAmount);   // blend before shading
    }

    // --- DayZ specular colour -------------------------------------------------
    // Dielectric floor from the Fresnel N/K (default 1.5/0 -> 0.04).
    float f0 = dayzF0(u_fresnel_n, u_fresnel_k);
    // Metals take their reflectance either from the base colour (the physical
    // DayZ "PBR _smdi" method) or from the flat F0, then everything is tinted.
    vec3 metalSpec = u_metal_from_basecolor ? baseColor : vec3(f0);
    vec3 specColor = u_spec_tint * mix(vec3(f0), metalSpec, metallic)
                     * (specLevelCh * 2.0) * u_spec_level;
    specColor = clamp(specColor, 0.0, 1.0);

    // Diffuse: metals lose their diffuse; the DayZ diffuse[] tint multiplies it.
    vec3 diffColor = baseColor * (1.0 - metallic) * u_diffuse;

    // Gloss: DayZ gloss = 1 - roughness (scaled by the B boost). specularPower
    // then tightens the highlight globally (relative to a 60 reference), the way
    // the .rvmat specularPower does - higher = sharper/shinier.
    float gloss = clamp((1.0 - roughness) * u_gloss_boost, 0.0, 1.0);
    float powerFactor = clamp(sqrt(u_spec_power / 60.0), 0.35, 3.0);
    float dayzRoughness = clamp((1.0 - gloss) / powerFactor, 0.0, 1.0);

    // Occlusion.
    float occlusion = getAO(inputs.sparse_coord) * getShadowFactor();
    float specOcclusion = specularOcclusionCorrection(occlusion, metallic, dayzRoughness);

    LocalVectors vectors = computeLocalFrame(inputs);

    // Emissive channel * tint * intensity, plus forcedDiffuse as an unlit add
    // (emissive output is added directly, not multiplied by the albedo - which
    // is exactly how DayZ forcedDiffuse behaves).
    vec3 emissive = pbrComputeEmissive(emissive_tex, inputs.sparse_coord)
                    * u_emissive_tint * u_emissive_intensity;

    // Macro "Unlit" mode: fade the shaded surface out where the macro sits and add
    // the pure macro colour unlit, so accents stay saturated on any surface.
    if (u_mc_show && u_mc_mode == 0 && macroAmount > 0.0)
    {
        diffColor *= (1.0 - macroAmount);
        specColor *= (1.0 - macroAmount);
        emissive  += macro * macroAmount;
    }

    // Feed Painter's IBL integration with the DayZ-derived values. Albedo and
    // diffuse shading stay separate - Painter multiplies them internally, so
    // diffuseShadingOutput must NOT be pre-multiplied by the albedo. The ambient
    // tint scales the (ambient) irradiance.
    emissiveColorOutput(emissive + u_forced_diffuse);
    albedoOutput(diffColor);
    diffuseShadingOutput(occlusion * envIrradiance(vectors.normal) * u_ambient);
    specularShadingOutput(u_env_intensity * u_env_tint * specOcclusion
                          * pbrComputeSpecular(vectors, specColor, dayzRoughness));
    sssCoefficientsOutput(getSSSCoefficients(inputs.sparse_coord));
}

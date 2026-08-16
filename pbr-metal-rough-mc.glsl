/*
 * RwG PBR Metal/Rough + Macro (_mc) preview
 * -----------------------------------------------------------------------------
 * The standard Substance Painter metal/rough shading, plus a live preview of a
 * DayZ _mc macro: the chosen User channel (User0 / User1 / User2) is shown over
 * the surface using the SAME mask rule as the exporter's "Auto (macro)" alpha -
 * max(R,G,B), so BLACK = transparent, WHITE = opaque.
 *
 * Preview mode:
 *   - "Unlit (always visible)" (default): the macro is drawn as an unlit colour
 *     overlay (via emissive), so it is visible on ANY surface - including pure
 *     metal, where a base-colour blend would vanish into the reflection.
 *   - "Blend into base (realistic)": the macro is blended into the base colour,
 *     the physically DayZ-like behaviour (metals show it only in the reflection).
 *
 * Viewport only - it changes nothing on export. Normal metal/rough shading; the
 * DayZ-style shading lives in the separate dayz-super.glsl.
 *
 * Non-commercial license - see LICENSE. (c) RwG.
 */

import lib-sss.glsl
import lib-pbr.glsl
import lib-emissive.glsl
import lib-pom.glsl
import lib-utils.glsl
import lib-sampler.glsl

// --- standard metal/rough channels ---------------------------------------- //
//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;
//: param auto channel_metallic
uniform SamplerSparse metallic_tex;
//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;

// --- User channels used as the macro source ------------------------------- //
//: param auto channel_user0
uniform SamplerSparse user0_tex;
//: param auto channel_user1
uniform SamplerSparse user1_tex;
//: param auto channel_user2
uniform SamplerSparse user2_tex;

// --- Macro (_mc) preview controls ----------------------------------------- //
//: param custom {
//:   "default": 0,
//:   "label": "Macro source",
//:   "widget": "combobox",
//:   "values": { "User0": 0, "User1": 1, "User2": 2 },
//:   "group": "Macro (_mc) preview"
//: }
uniform int u_mc_source;

//: param custom {
//:   "default": 0,
//:   "label": "Preview mode",
//:   "widget": "combobox",
//:   "values": { "Unlit (always visible)": 0, "Blend into base (realistic)": 1 },
//:   "group": "Macro (_mc) preview"
//: }
uniform int u_mc_mode;

//: param custom {
//:   "default": 1.0,
//:   "label": "Macro intensity",
//:   "min": 0.0,
//:   "max": 1.0,
//:   "group": "Macro (_mc) preview"
//: }
uniform float u_mc_intensity;

//: param custom {
//:   "default": 0,
//:   "label": "Mask",
//:   "widget": "combobox",
//:   "values": { "Auto (max RGB)": 0, "Luminance": 1 },
//:   "group": "Macro (_mc) preview"
//: }
uniform int u_mc_mask;

// Read the selected User channel. No #ifdef guard on purpose: some Painter
// versions don't define channel_userN, which would silently compile the macro
// out. If a User channel is absent, the auto sampler just returns its default.
vec3 sampleMacro(SparseCoord coord)
{
    if (u_mc_source == 1) return textureSparse(user1_tex, coord).rgb;
    if (u_mc_source == 2) return textureSparse(user2_tex, coord).rgb;
    return textureSparse(user0_tex, coord).rgb;
}

void shade(V2F inputs)
{
    // Parallax occlusion mapping (height).
    vec3 viewTS = worldSpaceToTangentSpace(getEyeVec(inputs.position), inputs);
    applyParallaxOffset(inputs, viewTS);

    // Standard metal/rough inputs.
    float roughness = getRoughness(roughness_tex, inputs.sparse_coord);
    vec3  baseColor = getBaseColor(basecolor_tex, inputs.sparse_coord);
    float metallic  = getMetallic(metallic_tex, inputs.sparse_coord);
    float specularLevel = getSpecularLevel(specularlevel_tex, inputs.sparse_coord);

    // Macro (_mc) mask: black = transparent, white = opaque (matches the export).
    vec3 macro = sampleMacro(inputs.sparse_coord);
    float macroAmount = 0.0;
    if (u_mc_intensity > 0.0)
    {
        float mask = (u_mc_mask == 1)
            ? dot(macro, vec3(0.299, 0.587, 0.114))     // luminance
            : max(macro.r, max(macro.g, macro.b));       // auto (max RGB)
        macroAmount = clamp(mask * u_mc_intensity, 0.0, 1.0);
        // Realistic mode blends the macro into the base colour before shading.
        if (u_mc_mode == 1)
            baseColor = mix(baseColor, macro, macroAmount);
    }

    // Metal/rough -> diffuse + specular.
    vec3 diffColor = generateDiffuseColor(baseColor, metallic);
    vec3 specColor = generateSpecularColor(specularLevel, baseColor, metallic);

    float occlusion = getAO(inputs.sparse_coord) * getShadowFactor();
    float specOcclusion = specularOcclusionCorrection(occlusion, metallic, roughness);

    LocalVectors vectors = computeLocalFrame(inputs);

    // Emissive. In "Unlit" mode the macro replaces the shaded surface where it is
    // present: the lit diffuse/specular underneath is faded out by the same amount
    // and the pure macro colour is added unlit - so it reads saturated, not washed
    // out by the (possibly white/empty) surface below.
    vec3 emissive = pbrComputeEmissive(emissive_tex, inputs.sparse_coord);
    if (u_mc_mode == 0)
    {
        diffColor *= (1.0 - macroAmount);
        specColor *= (1.0 - macroAmount);
        emissive  += macro * macroAmount;
    }

    emissiveColorOutput(emissive);
    albedoOutput(diffColor);
    diffuseShadingOutput(occlusion * envIrradiance(vectors.normal));
    specularShadingOutput(specOcclusion * pbrComputeSpecular(vectors, specColor, roughness));
    sssCoefficientsOutput(getSSSCoefficients(inputs.sparse_coord));
}

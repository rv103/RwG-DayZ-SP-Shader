/*
 * RwG DayZ In-Game (Spec/Gloss) - Substance 3D Painter viewport shader
 * -----------------------------------------------------------------------------
 * The spec/gloss variant of dayz-ingame.glsl: for projects with Painter's
 * Diffuse / Specular / Glossiness channels ("PBR - Specular Glossiness"
 * template). Shows the surface the way DayZ renders it:
 *
 *   1. the channels become the DayZ maps like the RwG DayZ Painter plugin
 *      exports them: _co = Diffuse, _as G = AO, Painter's normal = _nohq, and
 *      _smdi either "Direct" (Specular -> G, Glossiness -> B as painted, the
 *      classic DayZ way) or "PBR spec/gloss" (Specular = F0, Glossiness =
 *      1 - roughness, converted like the metal/rough "DayZ shader-matched"
 *      method);
 *   2. those maps run through a reimplementation of the game's "Super" shader
 *      (hemispherical ambient with ground light, unnormalised Blinn-Phong with
 *      the engine's specular scale, complex-IOR Fresnel stage, terminator, AO);
 *   3. the light comes from values measured in the game (RenderDoc captures of
 *      DayZ 1.30), the scene is clamped to 0..1 like the game's 8-bit scene
 *      buffer, and DayZ's filmic tone curve is applied.
 *
 * Set Painter's display to plain sRGB without its own tone mapping (see
 * README) - this shader already outputs the final DayZ image.
 * Viewport only; the export is unchanged. Non-commercial license - see LICENSE.
 */

import lib-sampler.glsl
import lib-env.glsl
import lib-pbr.glsl
import lib-vectors.glsl
import lib-alpha.glsl
import lib-emissive.glsl

// --- Spec/gloss channels ------------------------------------------------------ //
// Either the classic Arma/DayZ layout (Base Color, Specular Level, Glossiness -
// painted straight as _co, _smdi G, _smdi B) or Painter's "PBR - Specular
// Glossiness" template (Diffuse, Specular colour, Glossiness). Whichever
// channel the texture set has is used.
//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_basecolor_is_set
uniform bool basecolor_is_set;
//: param auto channel_diffuse
uniform SamplerSparse diffuse_tex;
//: param auto channel_specularlevel
uniform SamplerSparse specularlevel_tex;
//: param auto channel_specularlevel_is_set
uniform bool specularlevel_is_set;
//: param auto channel_specular
uniform SamplerSparse specularcolor_tex;
//: param auto channel_glossiness
uniform SamplerSparse glossiness_tex;
//: param auto channel_user0
uniform SamplerSparse user0_tex;
//: param auto channel_user1
uniform SamplerSparse user1_tex;
//: param auto channel_user2
uniform SamplerSparse user2_tex;

//: param auto main_light
uniform vec4 light_main;

// =========================================================================== //
//  rvmat values (the ones the plugin writes)                                   //
// =========================================================================== //
//: param custom { "default": [1.0, 1.0, 1.0], "label": "ambient[]", "widget": "color", "group": "DayZ rvmat" }
uniform vec3 u_ambient;
//: param custom { "default": [1.0, 1.0, 1.0], "label": "diffuse[]", "widget": "color", "group": "DayZ rvmat" }
uniform vec3 u_diffuse;
//: param custom { "default": [0.0, 0.0, 0.0], "label": "forcedDiffuse[]", "widget": "color", "group": "DayZ rvmat" }
uniform vec3 u_forced;
//: param custom { "default": [0.0, 0.0, 0.0], "label": "emmisive[]", "widget": "color", "group": "DayZ rvmat" }
uniform vec3 u_emmisive;
//: param custom { "default": [1.0, 1.0, 1.0], "label": "specular[]", "widget": "color", "group": "DayZ rvmat" }
uniform vec3 u_specular;
//: param custom { "default": 30.0, "label": "specularPower", "min": 1.0, "max": 2048.0, "group": "DayZ rvmat" }
uniform float u_power;
//: param custom { "default": 0.4, "label": "fresnel N", "min": 0.0, "max": 12.0, "group": "DayZ rvmat" }
uniform float u_fresnel_n;
//: param custom { "default": 0.2, "label": "fresnel K", "min": 0.0, "max": 12.0, "group": "DayZ rvmat" }
uniform float u_fresnel_k;

// =========================================================================== //
//  Spec/gloss -> DayZ conversion (mirrors the plugin export)                   //
// =========================================================================== //
//: param custom { "default": 0, "label": "_smdi method", "widget": "combobox", "values": { "Direct: Specular = G, Glossiness = B (as painted)": 0, "PBR spec/gloss, DayZ shader-matched": 1 }, "group": "Spec/Gloss to DayZ" }
uniform int u_smdi_method;
//: param custom { "default": true, "label": "G x gloss (energy, PBR method only)", "group": "Spec/Gloss to DayZ" }
uniform bool u_normalize;
//: param custom { "default": 1.0, "label": "_smdi G slider", "min": 0.0, "max": 2.0, "group": "Spec/Gloss to DayZ" }
uniform float u_g_factor;
//: param custom { "default": 1.0, "label": "_smdi B slider", "min": 0.0, "max": 2.0, "group": "Spec/Gloss to DayZ" }
uniform float u_b_factor;
//: param custom { "default": false, "label": "Show macro (_mc)", "group": "Spec/Gloss to DayZ" }
uniform bool u_mc_show;
//: param custom { "default": 0, "label": "Macro source", "widget": "combobox", "values": { "User0": 0, "User1": 1, "User2": 2 }, "group": "Spec/Gloss to DayZ" }
uniform int u_mc_source;

// =========================================================================== //
//  Light (measured in DayZ 1.30)                                               //
// =========================================================================== //
//: param custom { "default": 0, "label": "Light", "widget": "combobox", "values": { "Clear, noon (sun 60)": 0, "Clear, morning (sun 35)": 1, "Clear, evening (sun 8)": 2, "Dusk (sun 3.5)": 3, "Overcast, noon": 4, "Half overcast, morning": 5, "Night, full moon": 6, "Night, no moon": 7, "Inventory preview": 8 }, "group": "DayZ light" }
uniform int u_light;
//: param custom { "default": true, "label": "Sun direction from Painter's environment (Shift+drag)", "group": "DayZ light" }
uniform bool u_dir_from_env;
//: param custom { "default": 0.0, "label": "Exposure (EV)", "min": -4.0, "max": 4.0, "group": "DayZ light" }
uniform float u_ev;
//: param custom { "default": "", "label": "Environment texture (env_*_co; the plugin sets the rvmat's one)", "usage": "texture", "group": "DayZ light" }
uniform sampler2D u_env_tex;
//: param custom { "default": false, "label": "Use environment texture (else Painter's HDRI)", "group": "DayZ light" }
uniform bool u_use_env_tex;
//: param custom { "default": true, "label": "DayZ filmic tone curve", "group": "DayZ light" }
uniform bool u_filmic;

//: param custom { "default": 0, "label": "View", "widget": "combobox", "values": { "Final": 0, "_co (surface colour)": 1, "_smdi G (specular)": 2, "_smdi B (gloss)": 3, "Fresnel stage": 4, "Reflectivity G x Fresnel": 5, "Lighting only": 6 }, "group": "Debug" }
uniform int u_view;

// --------------------------------------------------------------------------- //
//  Light presets: pre-exposed colours as the game uploads them for a material  //
//  with diffuse[] = ambient[] = 1 (sun, sky, ground), bidirect factor, sun      //
//  elevation for the shading direction, fEnvSaturation.                        //
// --------------------------------------------------------------------------- //
struct DayZLight { vec3 sun; vec3 sky; vec3 ground; vec3 bidirect; float elevation; float envSat; bool inventory; };

DayZLight dayzLight(int i)
{
    DayZLight l;
    l.inventory = false; l.envSat = 1.0; l.bidirect = vec3(0.08);
    if (i == 1)      { l.sun = vec3(1.99593, 1.73646, 1.69654); l.sky = vec3(0.36782, 0.55172, 0.73563); l.ground = vec3(0.04496, 0.06744, 0.08991); l.elevation = 35.0; }
    else if (i == 2) { l.sun = vec3(0.96086, 0.58036, 0.38434); l.sky = vec3(0.27806, 0.41709, 0.64881); l.ground = vec3(0.05277, 0.07916, 0.12314); l.elevation = 8.0; l.bidirect = vec3(0.03); }
    else if (i == 3) { l.sun = vec3(0.51374, 0.20687, 0.0685);  l.sky = vec3(0.19675, 0.29412, 0.45884); l.ground = vec3(0.038, 0.04391, 0.08574);  l.elevation = 3.5; l.bidirect = vec3(0.03); }
    else if (i == 4) { l.sun = vec3(0.01036, 0.01036, 0.01151); l.sky = vec3(0.16413, 0.19695, 0.23799); l.ground = vec3(0.0099, 0.01188, 0.01435);  l.elevation = 60.0; l.bidirect = vec3(0.33); l.envSat = 0.0; }
    else if (i == 5) { l.sun = vec3(0.65448, 0.57122, 0.55997); l.sky = vec3(0.25355, 0.35774, 0.46192); l.ground = vec3(0.03099, 0.04373, 0.05646); l.elevation = 35.0; l.bidirect = vec3(0.149); l.envSat = 0.35; }
    else if (i == 6) { l.sun = vec3(0.04944, 0.07415, 0.14831); l.sky = vec3(0.01746, 0.03274, 0.05238); l.ground = vec3(0.00208, 0.00374, 0.00624); l.elevation = 40.0; l.bidirect = vec3(0.0); }
    else if (i == 7) { l.sun = vec3(0.0);                       l.sky = vec3(0.03969, 0.07441, 0.11906); l.ground = vec3(0.00248, 0.00446, 0.00744); l.elevation = 15.0; l.bidirect = vec3(0.0); }
    else if (i == 8) { l.sun = vec3(1.2, 1.2, 1.14);            l.sky = vec3(2.4, 2.4, 2.58);            l.ground = vec3(0.11, 0.125, 0.1);           l.elevation = 15.0; l.bidirect = vec3(0.22, 0.25, 0.2); l.inventory = true; }
    else             { l.sun = vec3(2.38829, 2.07781, 2.03004); l.sky = vec3(0.38315, 0.57472, 0.76629); l.ground = vec3(0.02311, 0.03466, 0.04622); l.elevation = 60.0; }
    return l;
}

// --------------------------------------------------------------------------- //
//  Engine formulas                                                              //
// --------------------------------------------------------------------------- //
float fresnelF0(float n, float k) { return ((n - 1.0) * (n - 1.0) + k * k) / ((n + 1.0) * (n + 1.0) + k * k); }

// Unpolarised reflectance for a complex index n + ik (the engine's fresnel(n,k) stage).
float fresnelStage(float n, float k, float c)
{
    c = clamp(c, 1e-6, 1.0);
    float s2 = 1.0 - c * c;
    float t = n * n - k * k - s2;
    float root = sqrt(t * t + 4.0 * n * n * k * k);
    float a2 = max(0.0, 0.5 * (root + t)), b2 = max(0.0, 0.5 * (root - t));
    float a = sqrt(a2);
    float rs = (a2 + b2 - 2.0 * a * c + c * c) / (a2 + b2 + 2.0 * a * c + c * c);
    float st = s2 / c;
    float rp = rs * (a2 + b2 - 2.0 * a * st + st * st) / (a2 + b2 + 2.0 * a * st + st * st);
    return clamp(0.5 * (rs + rp), 0.0, 1.0);
}

// The stage is a 64-texel texture with texel i at cos = i/63, sampled at min(|N.V|, 0.96875).
float sampleFresnelStage(float ndv)
{
    float u = min(abs(ndv), 0.96875);
    return fresnelStage(u_fresnel_n, u_fresnel_k, clamp((u * 64.0 - 0.5) / 63.0, 0.0, 1.0));
}

// Engine scale on the highlight over specularPower (linear, capped).
float specularScale(float p) { return min(0.10986 * p + 0.0254, 24.05); }

vec3 filmic(vec3 x)
{
    const float A = 0.153, B = 0.357, C = 0.423, D = 0.1573, E = 0.011, F = 3.75;
    x *= 4.0;
    vec3 f = (x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F) - E / F;
    return f * 1.28917;   // 1 / f(1.5 * 4)
}

float perceived(vec3 c) { return sqrt(0.299 * c.r * c.r + 0.587 * c.g * c.g + 0.114 * c.b * c.b); }

vec3 srgbToLinear(vec3 c)
{
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 linearToSrgb(vec3 c)
{
    c = clamp(c, 0.0, 1.0);
    return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

vec3 sampleMacro(SparseCoord coord)
{
    if (u_mc_source == 1) return textureSparse(user1_tex, coord).rgb;
    if (u_mc_source == 2) return textureSparse(user2_tex, coord).rgb;
    return textureSparse(user0_tex, coord).rgb;
}

void shade(V2F inputs)
{
    alphaKill(inputs.sparse_coord);
    inputs.normal = normalize(inputs.normal);
    LocalVectors vectors = computeLocalFrame(inputs);
    vec3 N = vectors.normal, V = vectors.eye;

    // --- spec/gloss -> DayZ maps (as the plugin exports them) ------------------
    vec3 base = basecolor_is_set ? getBaseColor(basecolor_tex, inputs.sparse_coord)
                                 : getDiffuse(diffuse_tex, inputs.sparse_coord);   // _co (linear)
    float glossiness = getGlossiness(glossiness_tex, inputs.sparse_coord);
    float ao = getAO(inputs.sparse_coord);                                // _as G

    // Specular Level is a raw grey channel = the stored _smdi G. A Specular colour (sRGB
    // channel, decoded by Painter) becomes the grey value of the exported image (sRGB
    // bytes, ITU-R 601 weights like the plugin's converter) - or its linear F0 for the
    // PBR method.
    vec3 specColor = specularlevel_is_set ? vec3(0.0) : getSpecularColor(specularcolor_tex, inputs.sparse_coord);
    float specLevel = specularlevel_is_set ? textureSparse(specularlevel_tex, inputs.sparse_coord).r
                                           : dot(linearToSrgb(specColor), vec3(0.299, 0.587, 0.114));

    float gloss, specG;
    if (u_smdi_method == 0)
    {
        // Direct: Specular -> G, Glossiness -> B as painted (the classic DayZ way).
        specG = specLevel;
        gloss = glossiness;
    }
    else
    {
        // PBR: Specular = F0, roughness = 1 - glossiness, then the metal/rough DayZ method.
        float f0 = specularlevel_is_set ? specLevel : perceived(specColor);
        float r = clamp(1.0 - glossiness, 0.02, 1.0);
        gloss = clamp((2.0 / (r * r * r * r) - 2.0) / max(u_power, 1.0), 0.0, 1.0);
        specG = f0 / max(fresnelF0(u_fresnel_n, u_fresnel_k), 1e-3);
        if (u_normalize) specG *= gloss;
    }
    specG = clamp(specG * u_g_factor, 0.0, 1.0);
    gloss = clamp(gloss * u_b_factor, 0.0, 1.0);

    if (u_mc_show)
    {
        vec3 mc = sampleMacro(inputs.sparse_coord);
        base = mix(base, mc, max(mc.r, max(mc.g, mc.b)));               // _mc, alpha = max RGB
    }

    // --- light --------------------------------------------------------------------
    DayZLight light = dayzLight(u_light);
    float exposure = exp2(u_ev);
    vec3 sun = light.sun * exposure, sky = light.sky * exposure, ground = light.ground * exposure;
    vec3 L;
    float el = radians(max(light.elevation, 15.0));                       // the engine raises it to >= 15 deg
    if (u_dir_from_env)
    {
        vec2 h = light_main.xz;
        h = length(h) > 1e-4 ? normalize(h) : vec2(0.0, 1.0);
        L = vec3(h.x * cos(el), sin(el), h.y * cos(el));
    }
    else
        L = vec3(0.0, sin(el), cos(el));

    // Material constants as the engine fills them.
    vec3 cAmbient = u_ambient * sky;
    vec3 cGround = ground;
    vec3 cDiffuse = u_diffuse * sun;
    vec3 cForced = u_forced * sun;
    vec3 cBidirect = u_diffuse * light.bidirect * sun;
    float power = gloss * u_power;
    vec3 cSpecular = u_specular * sun * specularScale(u_power);
    vec3 cRefl = u_specular * (0.5 * sun + sky);

    // --- Super shader ---------------------------------------------------------------
    float F = sampleFresnelStage(dot(N, V));
    float ks = specG * F;
    vec3 H = normalize(V + L);
    float NdotL = dot(N, L);
    float NdotH = clamp(dot(N, H), 0.0, 1.0);
    float terminator = clamp(NdotL * 111.111115 - 0.111111, 0.0, 1.0);
    float highlight = min(exp(power * log(max(NdotH, 1e-8))), 1.0) * terminator;

    vec3 R = reflect(-V, N);
    float mip = pow(1.0 - clamp(power / 2048.0, 0.0, 1.0), 8.0);
    // The game binds the env map (Stage7, env_*_co) as sRGB: decoded here too (a custom texture comes raw).
    vec3 env = u_use_env_tex
        ? srgbToLinear(textureLod(u_env_tex, R.xy * 0.5 + 0.5, mip * 10.0).rgb)
        : clamp(envSampleLOD(R, mip * maxLod) / max(environment_exposure, 1e-4), 0.0, 1.0);
    env *= cRefl;

    float shadow = getShadowFactor();
    float lum = dot(env, vec3(0.299, 0.587, 0.114));
    vec3 envShadowed = mix(vec3(lum), env, light.envSat) * 0.5;
    env = mix(envShadowed, env, shadow);

    vec3 ambient = N.y > 0.0
        ? cAmbient * 0.15 + clamp(N.y, 0.0, 1.0) * cAmbient * 0.85
        : mix(cGround, cAmbient * 0.15, clamp(N.y + 1.0, 0.0, 1.0));
    ambient += cBidirect * clamp(-NdotL, 0.0, 1.0);
    ambient *= ao * 0.5 + 0.5;

    vec3 emissive = pbrComputeEmissive(emissive_tex, inputs.sparse_coord) * u_emmisive;
    vec3 direct = (clamp(NdotL, 0.0, 1.0) * cDiffuse * clamp(1.0 - F * specG, 0.0, 1.0) + cForced) * ao;
    vec3 diffuse = (direct * shadow + emissive + ambient) * base;
    vec3 color = diffuse + highlight * cSpecular * ks * shadow + ks * env;

    if (u_view == 1) color = base;
    else if (u_view == 2) color = vec3(specG);
    else if (u_view == 3) color = vec3(gloss);
    else if (u_view == 4) color = vec3(F);
    else if (u_view == 5) color = vec3(ks);
    else if (u_view == 6) color = direct * shadow + ambient;

    if (u_view == 0 || u_view == 6)
    {
        // The game's scene buffer is 8-bit (clamped); item previews skip the tone curve.
        color = clamp(color, 0.0, 1.0);
        if (u_filmic && !light.inventory) color = filmic(color);
    }
    diffuseShadingOutput(color);
}

// Simple screen-space GI approximation (SSGI)
// Lightweight, sampling the scene color texture around the current UV.
// This is a shader-pack-side approximation and intended to be enabled opt-in
// via a `#define SSGI` in the material shader or by the host passing a define.

// Configurable constants (can be tuned from host if exposed as uniforms)
const int SSGI_SAMPLES = 8;
const float SSGI_RADIUS = 0.006; // screen-space sampling radius (in UV)
const float SSGI_STRENGTH = 0.45; // final contribution multiplier

// Simple fixed sample kernel (8 samples)
const vec2 ssgiKernel[8] = vec2[8](
    vec2( 0.0,  1.0),
    vec2( 0.707,  0.707),
    vec2( 1.0,  0.0),
    vec2( 0.707, -0.707),
    vec2( 0.0, -1.0),
    vec2(-0.707, -0.707),
    vec2(-1.0,  0.0),
    vec2(-0.707,  0.707)
);

// Estimate an indirect lighting contribution by sampling nearby pixels
// Requires the shader to provide `gtexture` and the fragment UV (`uv`).
// Returns an RGB offset to add to the base color.
vec3 ssgi_compute(in vec2 uv, in vec3 baseColor) {
    // If the scene doesn't expose a texture sampler named `gtexture`, this
    // function will be optimized out when not referenced. Call sites should
    // only invoke this when TEXTURE is defined.
    vec3 accum = vec3(0.0);
    float totalWeight = 0.0;

    // Sample a small ring around the pixel and accumulate color difference
    // as a cheap proxy for bounced light contribution.
    for (int i = 0; i < SSGI_SAMPLES; ++i) {
        vec2 sampleUV = uv + ssgiKernel[i] * SSGI_RADIUS;
        vec3 sampleCol = texture(gtexture, sampleUV).rgb;

        // weight by similarity to base luminance (favor brighter samples)
        float lumBase = dot(baseColor, vec3(0.299, 0.587, 0.114));
        float lumSample = dot(sampleCol, vec3(0.299, 0.587, 0.114));
        float weight = max(lumSample - lumBase, 0.0);

        // small smoothstep to avoid harsh discontinuities
        weight *= smoothstep(0.0, 1.0, lumSample);

        accum += sampleCol * weight;
        totalWeight += weight;
    }

    if (totalWeight <= 0.0) return vec3(0.0);

    vec3 bounced = accum / totalWeight;

    // final contribution scaled down to avoid overpowering direct lighting
    return (bounced - baseColor) * SSGI_STRENGTH;
}

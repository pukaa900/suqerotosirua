// Minimal Temporal Anti-Aliasing (TAA)
// This implementation performs a history blend and optional clamping.
// Usage: call `taa_resolve(uv, currentColor)` when `TAA` is defined.

// Host should provide a history texture (`t_history`) and optionally uniforms:
// - `uniform sampler2D t_history;` (previous-frame color)
// - `uniform float taa_historyWeight;` (0..1, e.g. 0.85)
// - `uniform float taa_clamp;` (max color difference to accept from history)

#ifndef TAA_HISTORY_WEIGHT
const float TAA_HISTORY_WEIGHT_DEFAULT = 0.85;
#endif

vec3 taa_resolve(in vec2 uv, in vec3 currentColor) {
#ifdef TAA_HISTORY
    vec3 history = texture(t_history, uv).rgb;
    float w = TAA_HISTORY_WEIGHT_DEFAULT;
    #ifdef taa_historyWeight
        // Some loaders may provide a `taa_historyWeight` uniform.
        w = taa_historyWeight;
    #endif

    // Optional clamping to avoid ghosting. If `taa_clamp` uniform present, use it.
    #ifdef taa_clamp
        float diff = length(history - currentColor);
        if (diff > taa_clamp) {
            // too far — prefer current
            history = currentColor;
        }
    #endif

    return mix(currentColor, history, w);
#else
    return currentColor;
#endif
}

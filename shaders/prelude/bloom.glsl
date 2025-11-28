// Simple bloom approximation: bright-pass + small gaussian-ish blur
// Usage: call `bloom_compute(uv, color)` when `BLOOM` is defined and
// `gtexture` is available. This returns an additive bloom color.

const float BLOOM_THRESHOLD = 1.0; // luminance threshold
const float BLOOM_GAIN = 0.8; // how strong the bloom is
const int BLOOM_SAMPLES = 9;

const vec2 bloomKernel[9] = vec2[9](
    vec2(0.0, 0.0),
    vec2(0.0, 1.0),
    vec2(1.0, 0.0),
    vec2(0.0, -1.0),
    vec2(-1.0, 0.0),
    vec2(0.7, 0.7),
    vec2(0.7, -0.7),
    vec2(-0.7, 0.7),
    vec2(-0.7, -0.7)
);

// uvRadius expected in UV units; pass a small value like 0.004 - 0.02
vec3 bloom_compute(in vec2 uv, in vec3 color) {
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    if (lum <= BLOOM_THRESHOLD * 0.5) return vec3(0.0);

    // bright-pass: sample center and compare to threshold
    vec3 accum = vec3(0.0);
    float weightSum = 0.0;
    float radius = 0.006; // default sampling radius in UV

    for (int i = 0; i < BLOOM_SAMPLES; ++i) {
        vec2 sampleUV = uv + bloomKernel[i] * radius;
        vec3 sampleCol = texture(gtexture, sampleUV).rgb;
        float sampleLum = dot(sampleCol, vec3(0.299, 0.587, 0.114));
        float weight = max(sampleLum - BLOOM_THRESHOLD, 0.0);
        // simple distance falloff
        float d = length(bloomKernel[i]);
        float fall = 1.0 / (1.0 + d * 2.0);
        weight *= fall;
        accum += sampleCol * weight;
        weightSum += weight;
    }

    if (weightSum <= 0.0) return vec3(0.0);

    vec3 bloom = (accum / weightSum) * BLOOM_GAIN;
    return bloom;
}

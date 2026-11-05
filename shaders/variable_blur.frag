#version 460 core

// Progressive ("variable") Gaussian blur for the iOS 26 soft scroll edge
// effect. Used as a backdrop image filter, run twice (horizontal, then
// vertical). The blur radius depends on the distance from the screen edge
// the effect is attached to, so it falls off smoothly with no steps.

#include <flutter/runtime_effect.glsl>

precision highp float;

// Size of the backdrop texture in physical pixels (set by the engine).
uniform vec2 uSize;
// x: y of the screen edge the effect starts at (physical px)
// y: length of the effect (physical px)
// z: maximum Gaussian sigma (physical px)
// w: +1 when the effect runs downwards from a top edge, -1 upwards
uniform vec4 uEdge;
// Pass direction: (1, 0) horizontal, (0, 1) vertical.
uniform vec2 uDir;

uniform sampler2D uTexture;

out vec4 fragColor;

const int kTaps = 16;

// Per-pixel hash in [0, 1), used to jitter the taps so that sampling never
// lines up with regular content (stripes, text) into visible patterns.
float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float falloff(float t) {
  float x = clamp((t - 0.15) / 0.85, 0.0, 1.0);
  return 1.0 - x * x * (3.0 - 2.0 * x);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 uv = p / uSize;
  float t = uEdge.w > 0.0 ? (p.y - uEdge.x) / uEdge.y
                          : (uEdge.x - p.y) / uEdge.y;
  float sigma = uEdge.z * falloff(t);
  if (sigma < 0.4) {
    fragColor = texture(uTexture, uv);
    return;
  }
  // kTaps samples per side covering +-2.5 sigma, shifted by a per-pixel
  // fraction of the spacing.
  float spacing = sigma * 2.5 / float(kTaps);
  float jitter = hash(p + uDir * 17.0) - 0.5;
  float inv = -0.5 / (sigma * sigma);
  vec2 texel = 1.0 / uSize;
  vec4 acc = vec4(0.0);
  float total = 0.0;
  for (int i = -kTaps; i <= kTaps; i++) {
    float d = (float(i) + jitter) * spacing;
    float w = exp(d * d * inv);
    // Clamp to the texture: samples outside it read as transparent, which
    // would let the unblurred content show through near the screen edge.
    vec2 q = clamp(uv + uDir * (d / uSize), texel * 0.5, 1.0 - texel * 0.5);
    acc += texture(uTexture, q) * w;
    total += w;
  }
  fragColor = acc / total;
}

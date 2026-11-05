// Liquid glass backdrop filter.
//
// Used with BackdropFilter(ImageFilter.shader(...)) on Impeller: the engine
// binds the backdrop as `uTexture` and its size (physical pixels) as `uSize`.
// The glass shape is a rounded rectangle given in the same pixel space.
//
// The look follows Apple's "Liquid Glass" material: the centre stays clear,
// the rim behaves like the edge of a convex lens (background is magnified
// and slightly dispersed), and a thin specular highlight runs along the rim.

#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // backdrop texture size (set by the engine)
uniform vec4 uRect;      // glass rect: x, y, width, height (px)
uniform float uRadius;   // corner radius (px)
uniform vec4 uTint;      // tint rgb + amount
uniform vec4 uParams;    // refraction (px), bevel width (px), dispersion, saturation
uniform vec4 uLight;     // highlight strength, brightness, light dir x, light dir y

uniform sampler2D uTexture;

out vec4 fragColor;

float sdRoundRect(vec2 p, vec2 halfSize, float r) {
  vec2 q = abs(p) - halfSize + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 sampleAt(vec2 px) {
  vec2 uv = clamp(px / uSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;

  vec2 halfSize = uRect.zw * 0.5;
  vec2 p = frag - (uRect.xy + halfSize);
  float r = min(uRadius, min(halfSize.x, halfSize.y));
  float d = sdRoundRect(p, halfSize, r);  // < 0 inside the glass

  vec4 background = sampleAt(frag);
  if (d > 1.0) {
    fragColor = background;
    return;
  }

  // Outward surface normal from the SDF gradient.
  const float e = 1.0;
  vec2 grad = vec2(
      sdRoundRect(p + vec2(e, 0.0), halfSize, r) -
          sdRoundRect(p - vec2(e, 0.0), halfSize, r),
      sdRoundRect(p + vec2(0.0, e), halfSize, r) -
          sdRoundRect(p - vec2(0.0, e), halfSize, r));
  vec2 n = grad / max(length(grad), 1e-4);

  // 0 on the flat centre, 1 right at the rim.
  float bevel = max(uParams.y, 1.0);
  float t = clamp(1.0 + d / bevel, 0.0, 1.0);
  // Circular lens profile: flat in the middle, steep near the edge.
  float bend = 1.0 - sqrt(max(1.0 - t * t, 0.0));

  // Convex lens: the ray bends inwards, so the rim shows magnified content
  // from slightly inside the shape.
  vec2 offset = -n * bend * uParams.x;
  float dispersion = uParams.z * bend;

  vec3 color;
  color.r = sampleAt(frag + offset * (1.0 + dispersion)).r;
  color.g = sampleAt(frag + offset).g;
  color.b = sampleAt(frag + offset * (1.0 - dispersion)).b;

  // Vibrancy: a touch more saturation and brightness than the backdrop.
  float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
  color = mix(vec3(luma), color, uParams.w);
  color *= uLight.y;

  // Tint.
  color = mix(color, uTint.rgb, uTint.a);

  // Specular rim: a thin bright line, strongest where the rim faces the
  // light and on the opposite side (light passing through the glass).
  vec2 lightDir = normalize(uLight.zw);
  float facing = dot(n, lightDir);
  float rimWidth = max(bevel * 0.12, 1.5);
  float rim = (1.0 - smoothstep(0.0, rimWidth, -d)) * step(d, 0.5);
  float spec = rim * (0.25 + 0.75 * pow(abs(facing), 1.5)) *
               (facing > 0.0 ? 1.0 : 0.55);
  // Soft inner glow along the bevel.
  float glow = bend * bend * (0.35 + 0.65 * max(facing, 0.0));
  color += vec3(uLight.x * (spec * 0.9 + glow * 0.12));

  // Anti-aliased edge.
  float alpha = 1.0 - smoothstep(-0.75, 0.75, d);
  fragColor = vec4(mix(background.rgb, clamp(color, 0.0, 1.0), alpha), 1.0);
}

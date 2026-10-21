// Port of ComicBookScreen_PbjSource (kernel "HalfToneFilter").
// Each of R, G, B is a halftone dot screen at its own angle; a pixel's channel
// is 1 when it falls inside that channel's dot, else 0. Uses sample_linear.
// Params: dot_spacing, max_dot_size (set by ComicBookScreen to 5.5 and 5),
// gamma (never set, so its PBJ default 0.8 applies).
uniform sampler2D src; uniform vec2 u_texSize;
uniform float dot_spacing; uniform float max_dot_size; uniform float gamma;
float dotHit(mat2 rot, vec2 c, float level) {
   vec2 p = rot * c;
   vec2 cell = floor(p / vec2(dot_spacing) + 0.5) * vec2(dot_spacing);
   float size = floor(level * max_dot_size + 0.5);
   return length(p - cell) < size ? 1.0 : 0.0;
}
void main() {
   vec2 c = outCoord();
   vec4 col = unpre(texel(src, u_texSize, c)) * gamma;
   vec4 result = vec4(0.0, 0.0, 0.0, 1.0);
   result.r = dotHit(mat2(0.258819, -0.9659258, 0.9659258, 0.258819), c, col.r * 1.0);
   result.b = dotHit(mat2(-0.258819, -0.9659258, 0.9659258, -0.258819), c, col.b * 0.9);
   result.g = dotHit(mat2(0.0, -1.0, 1.0, 0.0), c, col.g * 0.8);
   gl_FragColor = result;
}

// Port of PinchScreen_PbjSource (kernel "fisheye").
// k = (1 + 60*m*s / r^1.001) * (1 - 0.3*m*s), s = image_width / 640.
// Out-of-range coordinates are mirrored back inside. Uses sample_nearest.
uniform sampler2D src; uniform vec2 u_texSize;
uniform float x; uniform float y; uniform float image_width; uniform float image_height; uniform float magnitude;
vec2 mirrorEdges(vec2 p) {
   if (p.x < 1.0) p.x = 1.0 - p.x;
   if (p.y < 1.0) p.y = 1.0 - p.y;
   if (image_width - 1.0 < p.x) p.x = 2.0 * image_width - p.x - 2.0;
   if (image_height - 1.0 < p.y) p.y = 2.0 * image_height - p.y - 2.0;
   return p;
}
void main() {
   vec2 center = vec2(x, y);
   float s = image_width / 640.0;
   vec2 d = outCoord() - center;
   float r = length(d);
   float ms = magnitude * s;
   float k = 1.0 + (ms * 60.0) / max(pow(r, 1.001), 1e-6);
   vec2 p = center + (d * k) * (1.0 - 0.3 * ms);
   p = mirrorEdges(p);
   gl_FragColor = texel(src, u_texSize, floor(p) + 0.5);
}

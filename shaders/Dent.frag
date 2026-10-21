// Port of DentScreen_PbjSource (kernel "fisheye", "Dent filter").
// Zoom k = 1 + 0.8m inside r < 0.1*m*W, 1 outside r > m*W/2, and a cosine
// blend between. Out-of-range coordinates are mirrored. Uses sample_nearest.
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
   vec2 d = outCoord() - center;
   float r = length(d);
   float m = magnitude * 1.0;
   float k = 1.0 + m * 0.8;
   float outer = m * image_width / 2.0;
   float inner = (m * image_width * 0.2) / 2.0;
   if (r < inner) {
   } else if (outer < r) {
      k = 1.0;
   } else {
      float t = (r - inner) / (outer - inner);
      float blend = (-cos(t * 3.1415927) + 1.0) / 2.0;
      k = k - blend * (k - 1.0);
   }
   vec2 p = mirrorEdges(center + k * d);
   gl_FragColor = texel(src, u_texSize, floor(p) + 0.5);
}

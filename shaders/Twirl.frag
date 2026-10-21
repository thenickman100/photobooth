// Port of TwirlScreen_PbjSource (kernel "twirl", "photobooth twist filter").
// Rotation angle = max_angle * magnitude degrees, falling off as
// exp(-(r/R)^2) with R = 0.5 * image_height * magnitude. max_angle is never
// set by TwirlScreen, so its PBJ default 200 applies. Edges are mirrored.
// Uses sample_linear.
uniform sampler2D src; uniform vec2 u_texSize;
uniform float x; uniform float y; uniform float magnitude; uniform float image_width; uniform float image_height; uniform float max_angle;
vec2 mirrorEdges(vec2 p) {
   if (p.x < 1.0) p.x = 1.0 - p.x;
   if (p.y < 1.0) p.y = 1.0 - p.y;
   if (image_width - 1.0 < p.x) p.x = 2.0 * image_width - p.x - 2.0;
   if (image_height - 1.0 < p.y) p.y = 2.0 * image_height - p.y - 2.0;
   return p;
}
void main() {
   float radius = 0.5 * image_height * magnitude;
   float angle = 0.0174533 * (max_angle * magnitude);
   vec2 center = vec2(x, y);
   vec2 d = outCoord() - center;
   float r = radius > 0.0 ? length(d) / radius : 1e9;
   float a = exp(-r * r) * angle;
   mat2 rot = mat2(cos(a), sin(a), -sin(a), cos(a));
   vec2 p = mirrorEdges(center + rot * d);
   gl_FragColor = texel(src, u_texSize, p);
}

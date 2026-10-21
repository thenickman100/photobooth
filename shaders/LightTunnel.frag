// Port of LightTunnelScreen_PbjSource (kernel "twirl").
// Inside a circle of radius 0.5 * image_height * magnitude the image is
// untouched; outside, each pixel samples the circle's edge along its ray.
// Uses sample_linear.
uniform sampler2D src; uniform vec2 u_texSize;
uniform float x; uniform float y; uniform float magnitude; uniform float image_width; uniform float image_height;
void main() {
   float radius = 0.5 * image_height * magnitude;
   vec2 center = vec2(x, y);
   vec2 d = outCoord() - center;
   float r = radius > 0.0 ? length(d) / radius : 1e9;
   vec2 p;
   if (r <= 1.0) p = center + d;
   else p = center + d / r;
   gl_FragColor = texel(src, u_texSize, p);
}

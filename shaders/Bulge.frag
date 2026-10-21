// Port of BulgeScreen_PbjSource (kernel "fisheye", "Fish eye filter using
// cosine falloff function"). Radius is 130 * magnitude pixels; the kernel
// computes image_width / 640 but never uses it. Uses sample_linear.
uniform sampler2D src; uniform vec2 u_texSize;
uniform float x; uniform float y; uniform float image_width; uniform float magnitude;
void main() {
   vec2 center = vec2(x, y);
   vec2 d = outCoord() - center;
   float radius = magnitude * 130.0;
   float r = radius > 0.0 ? length(d) / radius : 1e9;
   float k = 1.0 - magnitude * exp(-1.0 * abs(r));
   gl_FragColor = texel(src, u_texSize, center + mat2(k, 0.0, 0.0, k) * d);
}

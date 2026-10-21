// Port of StretchScreen_PbjSource (kernel "fisheye").
// Squeezes each axis by 1 - scale * exp(-(d/(mag*s))^2), s = image_width/640.
// StretchScreen sets x, y and image_width only; scale (0.67) and mag (120)
// keep their PBJ defaults. Uses sample_linear.
uniform sampler2D src; uniform vec2 u_texSize;
uniform float x; uniform float y; uniform float scale; uniform float image_width; uniform float mag;
void main() {
   vec2 center = vec2(x, y);
   float s = image_width / 640.0;
   vec2 d = outCoord() - center;
   float ny = d.y / (mag * s);
   float nx = d.x / (mag * s);
   float a = scale * exp(-ny * ny);
   float b = scale * exp(-nx * nx);
   mat2 m = mat2(1.0, 0.0, 0.0, 1.0 - a) * mat2(1.0 - b, 0.0, 0.0, 1.0);
   gl_FragColor = texel(src, u_texSize, m * d + center);
}

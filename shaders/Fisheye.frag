// Port of FisheyeScreen_PbjSource (kernel "fisheye", "Fish eye filter using
// cosine falloff function"). FisheyeScreen sets only x and y, so cutoff (486)
// and scale (1.5) keep their PBJ defaults. Uses sample_linear.
uniform sampler2D src; uniform vec2 u_texSize;
uniform float x; uniform float y; uniform float cutoff; uniform float scale;
void main() {
   vec2 center = vec2(x, y);
   vec2 d = outCoord() - center;
   float c = cos(length(d) / cutoff) * 1.0;
   gl_FragColor = texel(src, u_texSize, center + (d / c) / (scale * 1.0));
}

// Port of BGRemovedScreen_PbjSource (kernel "sepia", described as "Chroma key").
// Keeps a camera pixel when its weighted YIQ distance from the stored empty
// background exceeds thresh / 1000; otherwise the pixel becomes transparent.
// BGRemovedScreen sets only the bg input, so thresh (3), weight_y (0.48),
// weight_i (0.56) and weight_q (0.48) keep their PBJ defaults.
uniform sampler2D src; uniform vec2 u_texSize;
uniform sampler2D bg; uniform vec2 bgSize;
uniform float thresh; uniform float weight_y; uniform float weight_i; uniform float weight_q;
void main() {
   mat4 rgb2yiq = mat4(0.299, 0.596, 0.212, 0.0,
                       0.587, -0.275, -0.523, 0.0,
                       0.114, -0.321, 0.311, 0.0,
                       0.0, 0.0, 0.0, 1.0);
   vec2 c = outCoord();
   vec4 s = unpre(texel(src, u_texSize, c));
   vec4 a = rgb2yiq * s;
   vec4 b = rgb2yiq * unpre(texel(bg, bgSize, c));
   vec3 d = a.xyz - b.xyz;
   float dist = weight_y * d.x * d.x + weight_i * d.y * d.y + weight_q * d.z * d.z;
   if (thresh / 1000.0 < dist) gl_FragColor = pre(s);
   else gl_FragColor = vec4(0.0);
}

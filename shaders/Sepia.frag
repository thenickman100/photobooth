// Port of SepiaScreen_PbjSource (kernel "sepia", Karthik / PhotoBooth).
// RGB -> YIQ, force I = 0.16 and Q = 0, YIQ -> RGB. Uses sample_nearest.
uniform sampler2D src; uniform vec2 u_texSize;
void main() {
   vec4 p = unpre(texel(src, u_texSize, floor(outCoord()) + 0.5));
   mat4 rgb2yiq = mat4(0.299, 0.596, 0.212, 0.0,
                       0.587, -0.275, -0.523, 0.0,
                       0.114, -0.321, 0.311, 0.0,
                       0.0, 0.0, 0.0, 1.0);
   mat4 yiq2rgb = mat4(1.0, 1.0, 1.0, 0.0,
                       0.956, -0.272, -1.1, 0.0,
                       0.621, -0.647, 1.7, 0.0,
                       0.0, 0.0, 0.0, 1.0);
   vec4 yiq = rgb2yiq * p;
   yiq.y = 0.16;
   yiq.z = 0.0;
   gl_FragColor = pre(clamp(yiq2rgb * yiq, 0.0, 1.0));
}

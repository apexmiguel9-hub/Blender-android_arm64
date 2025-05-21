
void main()
{
  ivec2 ivecTextureSize=ivec2(textureSize(depthBuf, 0));
  vec2 vecTextureSize=vec2(float(ivecTextureSize.x),float(ivecTextureSize.y));
  vec2 vec=gl_FragCoord.xy / vecTextureSize;
  float depth = textureLod(depthBuf, vec, 0.0).r;
  if (strokeOrder3d) {
    gl_FragDepth = depth;
  }
  else {
    gl_FragDepth = (depth != 0.0) ? gl_FragCoord.z : 1.0;
  }
}

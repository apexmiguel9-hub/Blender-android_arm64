
void main()
{
  vec2 phase = mod(gl_FragCoord.xy, float(size) * 2.0);

  if ((phase.x > float(size) && phase.y < float(size)) || (phase.x < float(size) && phase.y > float(size))) {
    fragColor = color1;
  }
  else {
    fragColor = color2;
  }
}

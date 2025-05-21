
void main()
{
  float phase = mod((gl_FragCoord.x + gl_FragCoord.y), float(size1 + size2));

  if (phase < float(size1)) {
    fragColor = color1;
  }
  else {
    fragColor = color2;
  }
}

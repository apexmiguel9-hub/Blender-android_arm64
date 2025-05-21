void node_blackbody(float temperature, sampler2DArray spectrummap, float layer, out vec4 color)
{
  float t = (temperature - 800.0) / (12000.0 - 800.0);
  color = vec4(texture(spectrummap, vec3(t,0.0, layer)).rgb, 1.0);
}

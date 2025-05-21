
void main()
{
  gl_Position = ModelViewProjectionMatrix * vec4(pos, 1.0);
  #  ifdef USE_WORLD_CLIP_PLANES
  gl_ClipDistance[0] = dot(ModelMatrix * vec4(pos, 1.0), ClipPlane);
  #  endif
}

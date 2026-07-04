
#pragma BLENDER_REQUIRE(common_view_lib.glsl)
#pragma BLENDER_REQUIRE(workbench_common_lib.glsl)
#pragma BLENDER_REQUIRE(workbench_matcap_lib.glsl)
#pragma BLENDER_REQUIRE(workbench_world_light_lib.glsl)

void main()
{
  /* Normal and Incident vector are in viewspace. Lighting is evaluated in viewspace. */
  vec3 I = get_view_vector_from_screen_uv(uvcoordsvar.st);
  vec3 N = workbench_normal_decode(texture(normalBuffer, uvcoordsvar.st));
  vec4 mat_data = texture(materialBuffer, uvcoordsvar.st);

  vec3 base_color = mat_data.rgb;

  float roughness, metallic;
  workbench_float_pair_decode(mat_data.a, roughness, metallic);

#ifdef WORKBENCH_LIGHTING_MATCAP
  /* When using matcaps, mat_data.a is the back-face sign. */
  N = (mat_data.a > 0.0) ? N : -N;

  // DEBUG: remove after diagnosis
  vec3 matcap_test = texture(matcap_diffuse_tx, vec2(0.5)).rgb;
  if (length(matcap_test) < 0.001) {
    fragColor.rgb = vec3(1, 0, 0); // Red: Matcap texture empty
    fragColor.a = 1.0;
    return;
  }
  if (length(base_color) < 0.001) {
    fragColor.rgb = vec3(0, 1, 0); // Green: Base color zero
    fragColor.a = 1.0;
    return;
  }

  vec3 lighting = get_matcap_lighting(matcap_diffuse_tx, matcap_specular_tx, base_color, N, I);
  float shadow = get_shadow(N, forceShadowing);
  if (shadow < 0.001) {
    fragColor.rgb = vec3(0, 0, 1); // Blue: Shadow total black
    fragColor.a = 1.0;
    return;
  }
  fragColor.rgb = max(lighting * shadow, vec3(0.05));
#else
#ifdef WORKBENCH_LIGHTING_STUDIO
  fragColor.rgb = get_world_lighting(base_color, roughness, metallic, N, I);
#endif

#ifdef WORKBENCH_LIGHTING_FLAT
  fragColor.rgb = base_color;
#endif

  fragColor.rgb *= get_shadow(N, forceShadowing);
#endif

  fragColor.a = 1.0;
}

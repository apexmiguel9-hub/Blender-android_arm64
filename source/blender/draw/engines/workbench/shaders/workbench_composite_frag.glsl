
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

  // DEBUG: Output raw base color to verify prepass writes
  fragColor.rgb = base_color;
  fragColor.a = 1.0;
}

  fragColor.a = 1.0;
}

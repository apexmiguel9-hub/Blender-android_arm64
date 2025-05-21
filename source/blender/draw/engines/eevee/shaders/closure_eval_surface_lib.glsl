
#pragma BLENDER_REQUIRE(closure_eval_diffuse_lib.glsl)
#pragma BLENDER_REQUIRE(closure_eval_glossy_lib.glsl)
#pragma BLENDER_REQUIRE(closure_eval_refraction_lib.glsl)
#pragma BLENDER_REQUIRE(closure_eval_translucent_lib.glsl)
#pragma BLENDER_REQUIRE(renderpass_lib.glsl)

#if defined(USE_SHADER_TO_RGBA) || defined(USE_ALPHA_BLEND)
bool do_sss = false;
bool do_ssr = false;
#else
bool do_sss = true;
bool do_ssr = true;
#endif

vec3 out_sss_radiance;
vec3 out_sss_color;
float out_sss_radius;

float out_ssr_roughness;
vec3 out_ssr_color;
vec3 out_ssr_N;

bool aov_is_valid = false;
vec3 out_aov;

bool output_sss(ClosureDiffuse diffuse, ClosureOutputDiffuse diffuse_out)
{
  if (diffuse.sss_id == 0u || !do_sss || !sssToggle || outputSssId == 0) {
    return false;
  }
  if (renderPassSSSColor) {
    return false;
  }
  out_sss_radiance = diffuse_out.radiance;
  out_sss_color = diffuse.color * diffuse.weight;
  out_sss_radius = avg(diffuse.sss_radius);
  do_sss = false;
  return true;
}

bool output_ssr(ClosureReflection reflection)
{
  if (!do_ssr || !ssrToggle || outputSsrId == 0) {
    return false;
  }
  out_ssr_roughness = reflection.roughness;
  out_ssr_color = reflection.color * reflection.weight;
  out_ssr_N = reflection.N;
  do_ssr = false;
  return true;
}

void output_aov(vec4 color, float value, uint hash)
{
  /* Keep in sync with `render_pass_aov_hash` and `EEVEE_renderpasses_aov_hash`. */
  hash <<= 1u;

  if (renderPassAOV && !aov_is_valid && hash == render_pass_aov_hash()) {
    aov_is_valid = true;
    if (render_pass_aov_is_color()) {
      out_aov = color.rgb;
    }
    else {
      out_aov = vec3(value);
    }
  }
}

/* Single BSDFs. */
void closure_DiffuseBSDF_eval(ClosureInputCommon in_common, inout ClosureInputDiffuse in_Diffuse_0,
                              inout ClosureOutput in_Dummy_1, inout ClosureOutput in_Dummy_2,
                              inout ClosureOutput in_Dummy_3, out ClosureOutputDiffuse out_Diffuse_0,
                              out ClosureOutput out_Dummy_1, out ClosureOutput out_Dummy_2,
                              out ClosureOutput out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalDiffuse eval_Diffuse_0 = closure_Diffuse_eval_init(in_Diffuse_0, cl_common,
                                                                  out_Diffuse_0);
    ClosureOutput eval_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Diffuse_cubemap_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, cube,
                                         out_Diffuse_0);;;;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Diffuse_grid_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, grid,
                                      out_Diffuse_0);;;;;
        }
    }
    closure_Diffuse_indirect_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);;;;;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Diffuse_planar_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, planar,
                                    out_Diffuse_0);;;;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Diffuse_light_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, light,
                                       out_Diffuse_0);;;;;
        }
    }
    closure_Diffuse_eval_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);;;;;
}
Closure closure_eval(ClosureDiffuse diffuse)
{
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputDiffuse in_Diffuse_0 = CLOSURE_INPUT_Diffuse_DEFAULT;
    ClosureOutput in_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputDiffuse out_Diffuse_0;
    ClosureOutput out_Dummy_1;
    ClosureOutput out_Dummy_2;
    ClosureOutput out_Dummy_3;

  in_Diffuse_0.N = diffuse.N;
  in_Diffuse_0.albedo = diffuse.color;

    closure_DiffuseBSDF_eval(in_common, in_Diffuse_0, in_Dummy_1, in_Dummy_2, in_Dummy_3, out_Diffuse_0,
                             out_Dummy_1, out_Dummy_2, out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;
  if (!output_sss(diffuse, out_Diffuse_0)) {
    closure.radiance += out_Diffuse_0.radiance * diffuse.color * diffuse.weight;
  }
  return closure;
}

void closure_TranslucentBSDF_eval(ClosureInputCommon in_common, inout ClosureInputTranslucent
                                  in_Translucent_0, inout ClosureOutput in_Dummy_1,
                                  inout ClosureOutput in_Dummy_2, inout ClosureOutput in_Dummy_3,
                                  out ClosureOutputTranslucent out_Translucent_0, out ClosureOutput
                                  out_Dummy_1, out ClosureOutput out_Dummy_2, out ClosureOutput
                                  out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalTranslucent eval_Translucent_0 = closure_Translucent_eval_init(in_Translucent_0,
                                                                              cl_common,
                                                                              out_Translucent_0);
    ClosureOutput eval_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Translucent_cubemap_eval(in_Translucent_0, eval_Translucent_0, cl_common, cube,
                                             out_Translucent_0);;;;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Translucent_grid_eval(in_Translucent_0, eval_Translucent_0, cl_common, grid,
                                          out_Translucent_0);;;;;
        }
    }
    closure_Translucent_indirect_end(in_Translucent_0, eval_Translucent_0, cl_common,
                                     out_Translucent_0);;;;;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Translucent_planar_eval(in_Translucent_0, eval_Translucent_0, cl_common, planar,
                                        out_Translucent_0);;;;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Translucent_light_eval(in_Translucent_0, eval_Translucent_0, cl_common, light,
                                           out_Translucent_0);;;;;
        }
    }
    closure_Translucent_eval_end(in_Translucent_0, eval_Translucent_0, cl_common,
                                 out_Translucent_0);;;;;
}
Closure closure_eval(ClosureTranslucent translucent)
{
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputTranslucent in_Translucent_0 = CLOSURE_INPUT_Translucent_DEFAULT;
    ClosureOutput in_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputTranslucent out_Translucent_0;
    ClosureOutput out_Dummy_1;
    ClosureOutput out_Dummy_2;
    ClosureOutput out_Dummy_3;

  in_Translucent_0.N = translucent.N;

    closure_TranslucentBSDF_eval(in_common, in_Translucent_0, in_Dummy_1, in_Dummy_2, in_Dummy_3,
                                 out_Translucent_0, out_Dummy_1, out_Dummy_2, out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;
  closure.radiance += out_Translucent_0.radiance * translucent.color * translucent.weight;
  return closure;
}

void closure_GlossyBSDF_eval(ClosureInputCommon in_common, inout ClosureInputGlossy in_Glossy_0,
                             inout ClosureOutput in_Dummy_1, inout ClosureOutput in_Dummy_2,
                             inout ClosureOutput in_Dummy_3, out ClosureOutputGlossy out_Glossy_0,
                             out ClosureOutput out_Dummy_1, out ClosureOutput out_Dummy_2,
                             out ClosureOutput out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalGlossy eval_Glossy_0 = closure_Glossy_eval_init(in_Glossy_0, cl_common,
                                                               out_Glossy_0);
    ClosureOutput eval_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Glossy_cubemap_eval(in_Glossy_0, eval_Glossy_0, cl_common, cube,
                                        out_Glossy_0);;;;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Glossy_grid_eval(in_Glossy_0, eval_Glossy_0, cl_common, grid, out_Glossy_0);;;;;
        }
    }
    closure_Glossy_indirect_end(in_Glossy_0, eval_Glossy_0, cl_common, out_Glossy_0);;;;;
    
    
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Glossy_planar_eval(in_Glossy_0, eval_Glossy_0, cl_common, planar, out_Glossy_0);;;;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Glossy_light_eval(in_Glossy_0, eval_Glossy_0, cl_common, light,
                                      out_Glossy_0);;;;;
        }
    }
    closure_Glossy_eval_end(in_Glossy_0, eval_Glossy_0, cl_common, out_Glossy_0);;;;;
}
Closure closure_eval(ClosureReflection reflection, const bool do_output_ssr)
{
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputGlossy in_Glossy_0 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureOutput in_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputGlossy out_Glossy_0;
    ClosureOutput out_Dummy_1;
    ClosureOutput out_Dummy_2;
    ClosureOutput out_Dummy_3;

  in_Glossy_0.N = reflection.N;
  in_Glossy_0.roughness = reflection.roughness;

  
  closure_GlossyBSDF_eval(in_common, in_Glossy_0, in_Dummy_1, in_Dummy_2, in_Dummy_3, out_Glossy_0,
                            out_Dummy_1, out_Dummy_2, out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;

  bool output_radiance = true;
  if (do_output_ssr) {
    output_radiance = !output_ssr(reflection);
  }
  if (output_radiance) {
    closure.radiance += out_Glossy_0.radiance * reflection.color * reflection.weight;
  }
  return closure;
}

Closure closure_eval(ClosureReflection reflection)
{
  return closure_eval(reflection, true);
}

void closure_RefractionBSDF_eval(ClosureInputCommon in_common, inout ClosureInputRefraction
                                 in_Refraction_0, inout ClosureOutput in_Dummy_1,
                                 inout ClosureOutput in_Dummy_2, inout ClosureOutput in_Dummy_3,
                                 out ClosureOutputRefraction out_Refraction_0, out ClosureOutput
                                 out_Dummy_1, out ClosureOutput out_Dummy_2, out ClosureOutput
                                 out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalRefraction eval_Refraction_0 = closure_Refraction_eval_init(in_Refraction_0,
                                                                           cl_common,
                                                                           out_Refraction_0);
    ClosureOutput eval_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Refraction_cubemap_eval(in_Refraction_0, eval_Refraction_0, cl_common, cube,
                                            out_Refraction_0);;;;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Refraction_grid_eval(in_Refraction_0, eval_Refraction_0, cl_common, grid,
                                         out_Refraction_0);;;;;
        }
    }
    closure_Refraction_indirect_end(in_Refraction_0, eval_Refraction_0, cl_common,
                                    out_Refraction_0);;;;;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Refraction_planar_eval(in_Refraction_0, eval_Refraction_0, cl_common, planar,
                                       out_Refraction_0);;;;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Refraction_light_eval(in_Refraction_0, eval_Refraction_0, cl_common, light,
                                          out_Refraction_0);;;;;
        }
    }
    closure_Refraction_eval_end(in_Refraction_0, eval_Refraction_0, cl_common,
                                out_Refraction_0);;;;;
}
Closure closure_eval(ClosureRefraction refraction)
{
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputRefraction in_Refraction_0 = CLOSURE_INPUT_Refraction_DEFAULT;
    ClosureOutput in_Dummy_1 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputRefraction out_Refraction_0;
    ClosureOutput out_Dummy_1;
    ClosureOutput out_Dummy_2;
    ClosureOutput out_Dummy_3;

  in_Refraction_0.N = refraction.N;
  in_Refraction_0.roughness = refraction.roughness;
  in_Refraction_0.ior = refraction.ior;

    closure_RefractionBSDF_eval(in_common, in_Refraction_0, in_Dummy_1, in_Dummy_2, in_Dummy_3,
                                out_Refraction_0, out_Dummy_1, out_Dummy_2, out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;
  closure.radiance += out_Refraction_0.radiance * refraction.color * refraction.weight;
  return closure;
}

Closure closure_eval(ClosureEmission emission)
{
  Closure closure = CLOSURE_DEFAULT;
  closure.radiance += render_pass_emission_mask(emission.emission) * emission.weight;
  return closure;
}

Closure closure_eval(ClosureTransparency transparency)
{
  Closure closure = CLOSURE_DEFAULT;
  closure.transmittance += transparency.transmittance * transparency.weight;
  closure.holdout += transparency.holdout * transparency.weight;
  return closure;
}

/* Glass BSDF. */
void closure_GlassBSDF_eval(ClosureInputCommon in_common, inout ClosureInputGlossy in_Glossy_0,
                            inout ClosureInputRefraction in_Refraction_1, inout ClosureOutput
                            in_Dummy_2, inout ClosureOutput in_Dummy_3, out ClosureOutputGlossy
                            out_Glossy_0, out ClosureOutputRefraction out_Refraction_1,
                            out ClosureOutput out_Dummy_2, out ClosureOutput out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalGlossy eval_Glossy_0 = closure_Glossy_eval_init(in_Glossy_0, cl_common,
                                                               out_Glossy_0);
    ClosureEvalRefraction eval_Refraction_1 = closure_Refraction_eval_init(in_Refraction_1,
                                                                           cl_common,
                                                                           out_Refraction_1);
    ClosureOutput eval_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Glossy_cubemap_eval(in_Glossy_0, eval_Glossy_0, cl_common, cube, out_Glossy_0);
            closure_Refraction_cubemap_eval(in_Refraction_1, eval_Refraction_1, cl_common, cube,
                                            out_Refraction_1);;;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Glossy_grid_eval(in_Glossy_0, eval_Glossy_0, cl_common, grid, out_Glossy_0);
            closure_Refraction_grid_eval(in_Refraction_1, eval_Refraction_1, cl_common, grid,
                                         out_Refraction_1);;;;
        }
    }
    closure_Glossy_indirect_end(in_Glossy_0, eval_Glossy_0, cl_common, out_Glossy_0);
    closure_Refraction_indirect_end(in_Refraction_1, eval_Refraction_1, cl_common,
                                    out_Refraction_1);;;;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Glossy_planar_eval(in_Glossy_0, eval_Glossy_0, cl_common, planar, out_Glossy_0);
        closure_Refraction_planar_eval(in_Refraction_1, eval_Refraction_1, cl_common, planar,
                                       out_Refraction_1);;;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Glossy_light_eval(in_Glossy_0, eval_Glossy_0, cl_common, light, out_Glossy_0);
            closure_Refraction_light_eval(in_Refraction_1, eval_Refraction_1, cl_common, light,
                                          out_Refraction_1);;;;
        }
    }
    closure_Glossy_eval_end(in_Glossy_0, eval_Glossy_0, cl_common, out_Glossy_0);
    closure_Refraction_eval_end(in_Refraction_1, eval_Refraction_1, cl_common, out_Refraction_1);;;;
}
Closure closure_eval(ClosureReflection reflection, ClosureRefraction refraction)
{

#if defined(DO_SPLIT_CLOSURE_EVAL)
  Closure closure = closure_eval(refraction);
  Closure closure_reflection = closure_eval(reflection);
  closure.radiance += closure_reflection.radiance;
  return closure;
#else
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputGlossy in_Glossy_0 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureInputRefraction in_Refraction_1 = CLOSURE_INPUT_Refraction_DEFAULT;
    ClosureOutput in_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputGlossy out_Glossy_0;
    ClosureOutputRefraction out_Refraction_1;
    ClosureOutput out_Dummy_2;
    ClosureOutput out_Dummy_3;

  in_Glossy_0.N = reflection.N;
  in_Glossy_0.roughness = reflection.roughness;
  in_Refraction_1.N = refraction.N;
  in_Refraction_1.roughness = refraction.roughness;
  in_Refraction_1.ior = refraction.ior;

    closure_GlassBSDF_eval(in_common, in_Glossy_0, in_Refraction_1, in_Dummy_2, in_Dummy_3,
                           out_Glossy_0, out_Refraction_1, out_Dummy_2, out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;
  closure.radiance += out_Refraction_1.radiance * refraction.color * refraction.weight;
  if (!output_ssr(reflection)) {
    closure.radiance += out_Glossy_0.radiance * reflection.color * reflection.weight;
  }
  return closure;
#endif
}

/* Dielectric BSDF */
void
closure_DielectricBSDF_eval(ClosureInputCommon in_common, inout ClosureInputDiffuse in_Diffuse_0,
                            inout ClosureInputGlossy in_Glossy_1, inout ClosureOutput in_Dummy_2,
                            inout ClosureOutput in_Dummy_3, out ClosureOutputDiffuse out_Diffuse_0,
                            out ClosureOutputGlossy out_Glossy_1, out ClosureOutput out_Dummy_2,
                            out ClosureOutput out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalDiffuse eval_Diffuse_0 = closure_Diffuse_eval_init(in_Diffuse_0, cl_common,
                                                                  out_Diffuse_0);
    ClosureEvalGlossy eval_Glossy_1 = closure_Glossy_eval_init(in_Glossy_1, cl_common,
                                                               out_Glossy_1);
    ClosureOutput eval_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Diffuse_cubemap_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, cube,
                                         out_Diffuse_0);
            closure_Glossy_cubemap_eval(in_Glossy_1, eval_Glossy_1, cl_common, cube,
                                        out_Glossy_1);;;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Diffuse_grid_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, grid, out_Diffuse_0);
            closure_Glossy_grid_eval(in_Glossy_1, eval_Glossy_1, cl_common, grid, out_Glossy_1);;;;
        }
    }
    closure_Diffuse_indirect_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);
    closure_Glossy_indirect_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);;;;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Diffuse_planar_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, planar, out_Diffuse_0);
        closure_Glossy_planar_eval(in_Glossy_1, eval_Glossy_1, cl_common, planar, out_Glossy_1);;;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
      
        if (light.vis > 1e-8) {
            closure_Diffuse_light_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, light,
                                       out_Diffuse_0);
            closure_Glossy_light_eval(in_Glossy_1, eval_Glossy_1, cl_common, light,
                                      out_Glossy_1);;;;
        }
    }
    closure_Diffuse_eval_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);
    closure_Glossy_eval_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);;;;
}

Closure closure_eval(ClosureDiffuse diffuse, ClosureReflection reflection)
{
#if defined(DO_SPLIT_CLOSURE_EVAL)
  Closure closure = closure_eval(diffuse);
  Closure closure_reflection = closure_eval(reflection);
  closure.radiance += closure_reflection.radiance;
  return closure;
#else
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputDiffuse in_Diffuse_0 = CLOSURE_INPUT_Diffuse_DEFAULT;
    ClosureInputGlossy in_Glossy_1 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureOutput in_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputDiffuse out_Diffuse_0;
    ClosureOutputGlossy out_Glossy_1;
    ClosureOutput out_Dummy_2;
    ClosureOutput out_Dummy_3;

  /* WORKAROUND: This is to avoid regression in 3.2 and avoid messing with EEVEE-Next. */
  in_common.occlusion = (diffuse.sss_radius.g == -1.0) ? diffuse.sss_radius.r : 1.0;
  in_Diffuse_0.N = diffuse.N;
  in_Diffuse_0.albedo = diffuse.color;
  in_Glossy_1.N = reflection.N;
  in_Glossy_1.roughness = reflection.roughness;

    closure_DielectricBSDF_eval(in_common, in_Diffuse_0, in_Glossy_1, in_Dummy_2, in_Dummy_3,
                                out_Diffuse_0, out_Glossy_1, out_Dummy_2, out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;
  if (!output_sss(diffuse, out_Diffuse_0)) {
    closure.radiance += out_Diffuse_0.radiance * diffuse.color * diffuse.weight;
  }
  if (!output_ssr(reflection)) {
    closure.radiance += out_Glossy_1.radiance * reflection.color * reflection.weight;
  }
  return closure;
#endif
}

/* Specular BSDF */
void closure_SpecularBSDF_eval(ClosureInputCommon in_common, inout ClosureInputDiffuse in_Diffuse_0,
                               inout ClosureInputGlossy in_Glossy_1, inout ClosureInputGlossy
                               in_Glossy_2, inout ClosureOutput in_Dummy_3, out ClosureOutputDiffuse
                               out_Diffuse_0, out ClosureOutputGlossy out_Glossy_1,
                               out ClosureOutputGlossy out_Glossy_2, out ClosureOutput out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalDiffuse eval_Diffuse_0 = closure_Diffuse_eval_init(in_Diffuse_0, cl_common,
                                                                  out_Diffuse_0);
    ClosureEvalGlossy eval_Glossy_1 = closure_Glossy_eval_init(in_Glossy_1, cl_common,
                                                               out_Glossy_1);
    ClosureEvalGlossy eval_Glossy_2 = closure_Glossy_eval_init(in_Glossy_2, cl_common,
                                                               out_Glossy_2);
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Diffuse_cubemap_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, cube,
                                         out_Diffuse_0);
            closure_Glossy_cubemap_eval(in_Glossy_1, eval_Glossy_1, cl_common, cube, out_Glossy_1);
            closure_Glossy_cubemap_eval(in_Glossy_2, eval_Glossy_2, cl_common, cube,
                                        out_Glossy_2);;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Diffuse_grid_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, grid, out_Diffuse_0);
            closure_Glossy_grid_eval(in_Glossy_1, eval_Glossy_1, cl_common, grid, out_Glossy_1);
            closure_Glossy_grid_eval(in_Glossy_2, eval_Glossy_2, cl_common, grid, out_Glossy_2);;;
        }
    }
    closure_Diffuse_indirect_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);
    closure_Glossy_indirect_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);
    closure_Glossy_indirect_end(in_Glossy_2, eval_Glossy_2, cl_common, out_Glossy_2);;;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Diffuse_planar_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, planar, out_Diffuse_0);
        closure_Glossy_planar_eval(in_Glossy_1, eval_Glossy_1, cl_common, planar, out_Glossy_1);
        closure_Glossy_planar_eval(in_Glossy_2, eval_Glossy_2, cl_common, planar, out_Glossy_2);;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Diffuse_light_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, light,
                                       out_Diffuse_0);
            closure_Glossy_light_eval(in_Glossy_1, eval_Glossy_1, cl_common, light, out_Glossy_1);
            closure_Glossy_light_eval(in_Glossy_2, eval_Glossy_2, cl_common, light, out_Glossy_2);;;
        }
    }
    closure_Diffuse_eval_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);
    closure_Glossy_eval_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);
    closure_Glossy_eval_end(in_Glossy_2, eval_Glossy_2, cl_common, out_Glossy_2);;;
}
Closure closure_eval(ClosureDiffuse diffuse,
                     ClosureReflection reflection,
                     ClosureReflection clearcoat)
{
#if defined(DO_SPLIT_CLOSURE_EVAL)
  Closure closure = closure_eval(diffuse);
  Closure closure_reflection = closure_eval(reflection);
  Closure closure_clearcoat = closure_eval(clearcoat, false);
  closure.radiance += closure_reflection.radiance + closure_clearcoat.radiance;
  return closure;
#else
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputDiffuse in_Diffuse_0 = CLOSURE_INPUT_Diffuse_DEFAULT;
    ClosureInputGlossy in_Glossy_1 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureInputGlossy in_Glossy_2 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputDiffuse out_Diffuse_0;
    ClosureOutputGlossy out_Glossy_1;
    ClosureOutputGlossy out_Glossy_2;
    ClosureOutput out_Dummy_3;;

  /* WORKAROUND: This is to avoid regression in 3.2 and avoid messing with EEVEE-Next. */
  in_common.occlusion = (diffuse.sss_radius.g == -1.0) ? diffuse.sss_radius.r : 1.0;
  in_Diffuse_0.N = diffuse.N;
  in_Diffuse_0.albedo = diffuse.color;
  in_Glossy_1.N = reflection.N;
  in_Glossy_1.roughness = reflection.roughness;
  in_Glossy_2.N = clearcoat.N;
  in_Glossy_2.roughness = clearcoat.roughness;

    closure_SpecularBSDF_eval(in_common, in_Diffuse_0, in_Glossy_1, in_Glossy_2, in_Dummy_3,
                              out_Diffuse_0, out_Glossy_1, out_Glossy_2, out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;
  if (!output_sss(diffuse, out_Diffuse_0)) {
    closure.radiance += out_Diffuse_0.radiance * diffuse.color * diffuse.weight;
  }
  closure.radiance += out_Glossy_2.radiance * clearcoat.color * clearcoat.weight;
  if (!output_ssr(reflection)) {
    closure.radiance += out_Glossy_1.radiance * reflection.color * reflection.weight;
  }
  return closure;
#endif
}

/* Principled BSDF */
void
closure_PrincipledBSDF_eval(ClosureInputCommon in_common, inout ClosureInputDiffuse in_Diffuse_0,
                            inout ClosureInputGlossy in_Glossy_1, inout ClosureInputGlossy
                            in_Glossy_2, inout ClosureInputRefraction in_Refraction_3,
                            out ClosureOutputDiffuse out_Diffuse_0, out ClosureOutputGlossy
                            out_Glossy_1, out ClosureOutputGlossy out_Glossy_2,
                            out ClosureOutputRefraction out_Refraction_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalDiffuse eval_Diffuse_0 = closure_Diffuse_eval_init(in_Diffuse_0, cl_common,
                                                                  out_Diffuse_0);
    ClosureEvalGlossy eval_Glossy_1 = closure_Glossy_eval_init(in_Glossy_1, cl_common,
                                                               out_Glossy_1);
    ClosureEvalGlossy eval_Glossy_2 = closure_Glossy_eval_init(in_Glossy_2, cl_common,
                                                               out_Glossy_2);
    ClosureEvalRefraction eval_Refraction_3 = closure_Refraction_eval_init(in_Refraction_3,
                                                                           cl_common,
                                                                           out_Refraction_3);;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Diffuse_cubemap_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, cube,
                                         out_Diffuse_0);
            closure_Glossy_cubemap_eval(in_Glossy_1, eval_Glossy_1, cl_common, cube, out_Glossy_1);
            closure_Glossy_cubemap_eval(in_Glossy_2, eval_Glossy_2, cl_common, cube, out_Glossy_2);
            closure_Refraction_cubemap_eval(in_Refraction_3, eval_Refraction_3, cl_common, cube,
                                            out_Refraction_3);;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Diffuse_grid_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, grid, out_Diffuse_0);
            closure_Glossy_grid_eval(in_Glossy_1, eval_Glossy_1, cl_common, grid, out_Glossy_1);
            closure_Glossy_grid_eval(in_Glossy_2, eval_Glossy_2, cl_common, grid, out_Glossy_2);
            closure_Refraction_grid_eval(in_Refraction_3, eval_Refraction_3, cl_common, grid,
                                         out_Refraction_3);;
        }
    }
    closure_Diffuse_indirect_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);
    closure_Glossy_indirect_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);
    closure_Glossy_indirect_end(in_Glossy_2, eval_Glossy_2, cl_common, out_Glossy_2);
    closure_Refraction_indirect_end(in_Refraction_3, eval_Refraction_3, cl_common,
                                    out_Refraction_3);;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Diffuse_planar_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, planar, out_Diffuse_0);
        closure_Glossy_planar_eval(in_Glossy_1, eval_Glossy_1, cl_common, planar, out_Glossy_1);
        closure_Glossy_planar_eval(in_Glossy_2, eval_Glossy_2, cl_common, planar, out_Glossy_2);
        closure_Refraction_planar_eval(in_Refraction_3, eval_Refraction_3, cl_common, planar,
                                       out_Refraction_3);;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Diffuse_light_eval(in_Diffuse_0, eval_Diffuse_0, cl_common, light,
                                       out_Diffuse_0);
            closure_Glossy_light_eval(in_Glossy_1, eval_Glossy_1, cl_common, light, out_Glossy_1);
            closure_Glossy_light_eval(in_Glossy_2, eval_Glossy_2, cl_common, light, out_Glossy_2);
            closure_Refraction_light_eval(in_Refraction_3, eval_Refraction_3, cl_common, light,
                                          out_Refraction_3);;
        }
    }
    closure_Diffuse_eval_end(in_Diffuse_0, eval_Diffuse_0, cl_common, out_Diffuse_0);
    closure_Glossy_eval_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);
    closure_Glossy_eval_end(in_Glossy_2, eval_Glossy_2, cl_common, out_Glossy_2);
    closure_Refraction_eval_end(in_Refraction_3, eval_Refraction_3, cl_common, out_Refraction_3);;
}
Closure closure_eval(ClosureDiffuse diffuse,
                     ClosureReflection reflection,
                     ClosureReflection clearcoat,
                     ClosureRefraction refraction)
{
#if defined(DO_SPLIT_CLOSURE_EVAL)
  Closure closure = closure_eval(diffuse);
  Closure closure_reflection = closure_eval(reflection);
  Closure closure_clearcoat = closure_eval(clearcoat, false);
  Closure closure_refraction = closure_eval(refraction);
  closure.radiance += closure_reflection.radiance + closure_clearcoat.radiance +
                      closure_refraction.radiance;
  return closure;
#else
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputDiffuse in_Diffuse_0 = CLOSURE_INPUT_Diffuse_DEFAULT;
    ClosureInputGlossy in_Glossy_1 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureInputGlossy in_Glossy_2 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureInputRefraction in_Refraction_3 = CLOSURE_INPUT_Refraction_DEFAULT;
    ClosureOutputDiffuse out_Diffuse_0;
    ClosureOutputGlossy out_Glossy_1;
    ClosureOutputGlossy out_Glossy_2;
    ClosureOutputRefraction out_Refraction_3;

  in_Diffuse_0.N = diffuse.N;
  in_Diffuse_0.albedo = diffuse.color;
  in_Glossy_1.N = reflection.N;
  in_Glossy_1.roughness = reflection.roughness;
  in_Glossy_2.N = clearcoat.N;
  in_Glossy_2.roughness = clearcoat.roughness;
  in_Refraction_3.N = refraction.N;
  in_Refraction_3.roughness = refraction.roughness;
  in_Refraction_3.ior = refraction.ior;

    closure_PrincipledBSDF_eval(in_common, in_Diffuse_0, in_Glossy_1, in_Glossy_2, in_Refraction_3,
                                out_Diffuse_0, out_Glossy_1, out_Glossy_2, out_Refraction_3);

  Closure closure = CLOSURE_DEFAULT;
  closure.radiance += out_Glossy_2.radiance * clearcoat.color * clearcoat.weight;
  closure.radiance += out_Refraction_3.radiance * refraction.color * refraction.weight;
  if (!output_sss(diffuse, out_Diffuse_0)) {
    closure.radiance += out_Diffuse_0.radiance * diffuse.color * diffuse.weight;
  }
  if (!output_ssr(reflection)) {
    closure.radiance += out_Glossy_1.radiance * reflection.color * reflection.weight;
  }
  return closure;
#endif
}

void
closure_PrincipledBSDFMetalClearCoat_eval(ClosureInputCommon in_common, inout ClosureInputGlossy
                                          in_Glossy_0, inout ClosureInputGlossy in_Glossy_1,
                                          inout ClosureOutput in_Dummy_2, inout ClosureOutput
                                          in_Dummy_3, out ClosureOutputGlossy out_Glossy_0,
                                          out ClosureOutputGlossy out_Glossy_1, out ClosureOutput
                                          out_Dummy_2, out ClosureOutput out_Dummy_3) {
    ClosureEvalCommon cl_common = closure_Common_eval_init(in_common);
    ClosureEvalGlossy eval_Glossy_0 = closure_Glossy_eval_init(in_Glossy_0, cl_common,
                                                               out_Glossy_0);
    ClosureEvalGlossy eval_Glossy_1 = closure_Glossy_eval_init(in_Glossy_1, cl_common,
                                                               out_Glossy_1);
    ClosureOutput eval_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput eval_Dummy_3 = ClosureOutput(vec3(0));;
    for (int i = 1; cl_common.specular_accum > 0.0 && i < prbNumRenderCube && i < MAX_PROBE; i++) {
        ClosureCubemapData cube = closure_cubemap_eval_init(i, cl_common);
        if (cube.attenuation > 1e-8) {
            closure_Glossy_cubemap_eval(in_Glossy_0, eval_Glossy_0, cl_common, cube, out_Glossy_0);
            closure_Glossy_cubemap_eval(in_Glossy_1, eval_Glossy_1, cl_common, cube,
                                        out_Glossy_1);;;;
        }
    }
    for (int i = 1; cl_common.diffuse_accum > 0.0 && i < prbNumRenderGrid && i < MAX_GRID; i++) {
        ClosureGridData grid = closure_grid_eval_init(i, cl_common);
        if (grid.attenuation > 1e-8) {
            closure_Glossy_grid_eval(in_Glossy_0, eval_Glossy_0, cl_common, grid, out_Glossy_0);
            closure_Glossy_grid_eval(in_Glossy_1, eval_Glossy_1, cl_common, grid, out_Glossy_1);;;;
        }
    }
    closure_Glossy_indirect_end(in_Glossy_0, eval_Glossy_0, cl_common, out_Glossy_0);
    closure_Glossy_indirect_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);;;;
    ClosurePlanarData planar = closure_planar_eval_init(cl_common);
    if (planar.attenuation > 1e-8) {
        closure_Glossy_planar_eval(in_Glossy_0, eval_Glossy_0, cl_common, planar, out_Glossy_0);
        closure_Glossy_planar_eval(in_Glossy_1, eval_Glossy_1, cl_common, planar, out_Glossy_1);;;;
    }
    for (int i = 0; i < laNumLight && i < MAX_LIGHT; i++) {
        ClosureLightData light = closure_light_eval_init(cl_common, i);
        if (light.vis > 1e-8) {
            closure_Glossy_light_eval(in_Glossy_0, eval_Glossy_0, cl_common, light, out_Glossy_0);
            closure_Glossy_light_eval(in_Glossy_1, eval_Glossy_1, cl_common, light,
                                      out_Glossy_1);;;;
        }
    }
    closure_Glossy_eval_end(in_Glossy_0, eval_Glossy_0, cl_common, out_Glossy_0);
    closure_Glossy_eval_end(in_Glossy_1, eval_Glossy_1, cl_common, out_Glossy_1);;;;
}
Closure closure_eval(ClosureReflection reflection, ClosureReflection clearcoat)
{
#if defined(DO_SPLIT_CLOSURE_EVAL)
  Closure closure = closure_eval(clearcoat);
  Closure closure_reflection = closure_eval(reflection);
  closure.radiance += closure_reflection.radiance;
  return closure;
#else
  /* Glue with the old system. */
    ClosureInputCommon in_common = ClosureInputCommon(1.0);
    ClosureInputGlossy in_Glossy_0 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureInputGlossy in_Glossy_1 = CLOSURE_INPUT_Glossy_DEFAULT;
    ClosureOutput in_Dummy_2 = ClosureOutput(vec3(0));
    ClosureOutput in_Dummy_3 = ClosureOutput(vec3(0));
    ClosureOutputGlossy out_Glossy_0;
    ClosureOutputGlossy out_Glossy_1;
    ClosureOutput out_Dummy_2;
    ClosureOutput out_Dummy_3;

  in_Glossy_0.N = reflection.N;
  in_Glossy_0.roughness = reflection.roughness;
  in_Glossy_1.N = clearcoat.N;
  in_Glossy_1.roughness = clearcoat.roughness;

    closure_PrincipledBSDFMetalClearCoat_eval(in_common, in_Glossy_0, in_Glossy_1, in_Dummy_2,
                                              in_Dummy_3, out_Glossy_0, out_Glossy_1, out_Dummy_2,
                                              out_Dummy_3);

  Closure closure = CLOSURE_DEFAULT;
  closure.radiance += out_Glossy_1.radiance * clearcoat.color * clearcoat.weight;
  if (!output_ssr(reflection)) {
    closure.radiance += out_Glossy_0.radiance * reflection.color * reflection.weight;
  }
  return closure;
#endif
}

/* Not supported for surface shaders. */
Closure closure_eval(ClosureVolumeScatter volume_scatter)
{
  return CLOSURE_DEFAULT;
}
Closure closure_eval(ClosureVolumeAbsorption volume_absorption)
{
  return CLOSURE_DEFAULT;
}
Closure closure_eval(ClosureVolumeScatter volume_scatter,
                     ClosureVolumeAbsorption volume_absorption,
                     ClosureEmission emission)
{
  return CLOSURE_DEFAULT;
}

/* Not implemented yet. */
Closure closure_eval(ClosureHair hair)
{
  return CLOSURE_DEFAULT;
}

vec4 closure_to_rgba(Closure closure)
{
  return vec4(closure.radiance, 1.0 - saturate(avg(closure.transmittance)));
}

Closure closure_add(inout Closure cl1, inout Closure cl2)
{
  Closure cl;
  cl.radiance = cl1.radiance + cl2.radiance;
  cl.transmittance = cl1.transmittance + cl2.transmittance;
  cl.holdout = cl1.holdout + cl2.holdout;
  /* Make sure each closure is only added once to the result. */
  cl1 = CLOSURE_DEFAULT;
  cl2 = CLOSURE_DEFAULT;
  return cl;
}

Closure closure_mix(inout Closure cl1, inout Closure cl2, float fac)
{
  /* Weights have already been applied. */
  return closure_add(cl1, cl2);
}

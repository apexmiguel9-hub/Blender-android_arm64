/* SPDX-License-Identifier: GPL-2.0-or-later
 * Copyright 2019 Blender Foundation. */

/** \file
 * \ingroup draw
 */

#include "DRW_render.h"

#include "gpencil_engine.h"

#include "BLI_smaa_textures.h"

#include <android/log.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>

static void gp_crash_log(const char *fmt, ...)
{
  static int gp_crash_fd = -2;
  if (gp_crash_fd == -2) {
    gp_crash_fd = open("/sdcard/com.epai.oblender/gp_crash.log",
                       O_WRONLY | O_CREAT | O_APPEND, 0644);
  }
  if (gp_crash_fd < 0) {
    return;
  }
  char buf[512];
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  if (n > 0) {
    write(gp_crash_fd, buf, n);
  }
  write(gp_crash_fd, "\n", 1);
  fsync(gp_crash_fd);
}

void GPENCIL_antialiasing_init(struct GPENCIL_Data *vedata)
{
  GPENCIL_PrivateData *pd = vedata->stl->pd;
  GPENCIL_FramebufferList *fbl = vedata->fbl;
  GPENCIL_TextureList *txl = vedata->txl;
  GPENCIL_PassList *psl = vedata->psl;
  DRWShadingGroup *grp;

  const float *size = DRW_viewport_size_get();
  const float *sizeinv = DRW_viewport_invert_size_get();
  const float metrics[4] = {sizeinv[0], sizeinv[1], size[0], size[1]};

  if (pd->simplify_antialias) {
    /* No AA fallback. */
    DRW_PASS_CREATE(psl->smaa_resolve_ps, DRW_STATE_WRITE_COLOR | DRW_STATE_BLEND_CUSTOM);

    GPUShader *sh = GPENCIL_shader_antialiasing(2);
    grp = DRW_shgroup_create(sh, psl->smaa_resolve_ps);
    DRW_shgroup_uniform_texture(grp, "blendTex", pd->color_tx);
    DRW_shgroup_uniform_texture(grp, "colorTex", pd->color_tx);
    DRW_shgroup_uniform_texture(grp, "revealTex", pd->reveal_tx);
    DRW_shgroup_uniform_bool_copy(grp, "doAntiAliasing", false);
    DRW_shgroup_uniform_bool_copy(grp, "onlyAlpha", pd->draw_wireframe);
    DRW_shgroup_uniform_vec4_copy(grp, "viewportMetrics", metrics);

    DRW_shgroup_call_procedural_triangles(grp, NULL, 1);
    return;
  }

  eGPUTextureUsage usage = GPU_TEXTURE_USAGE_SHADER_READ | GPU_TEXTURE_USAGE_ATTACHMENT;

  if (txl->smaa_search_tx == NULL) {

    txl->smaa_search_tx = GPU_texture_create_2d(
        "smaa_search", SEARCHTEX_WIDTH, SEARCHTEX_HEIGHT, 1, GPU_R8, usage, NULL);
    GPU_texture_update(txl->smaa_search_tx, GPU_DATA_UBYTE, searchTexBytes);

    txl->smaa_area_tx = GPU_texture_create_2d(
        "smaa_area", AREATEX_WIDTH, AREATEX_HEIGHT, 1, GPU_RG8, usage, NULL);
    GPU_texture_update(txl->smaa_area_tx, GPU_DATA_UBYTE, areaTexBytes);

    GPU_texture_filter_mode(txl->smaa_search_tx, true);
    GPU_texture_filter_mode(txl->smaa_area_tx, true);
  }

  {
    pd->smaa_edge_tx = DRW_texture_pool_query_2d_ex(
        size[0], size[1], GPU_RG8, usage, &draw_engine_gpencil_type);
    pd->smaa_weight_tx = DRW_texture_pool_query_2d_ex(
        size[0], size[1], GPU_RGBA8, usage, &draw_engine_gpencil_type);

    GPU_framebuffer_ensure_config(&fbl->smaa_edge_fb,
                                  {
                                      GPU_ATTACHMENT_NONE,
                                      GPU_ATTACHMENT_TEXTURE(pd->smaa_edge_tx),
                                  });

    GPU_framebuffer_ensure_config(&fbl->smaa_weight_fb,
                                  {
                                      GPU_ATTACHMENT_NONE,
                                      GPU_ATTACHMENT_TEXTURE(pd->smaa_weight_tx),
                                  });
  }

  {
    /* Stage 1: Edge detection. */
    DRW_PASS_CREATE(psl->smaa_edge_ps, DRW_STATE_WRITE_COLOR);

    GPUShader *sh = GPENCIL_shader_antialiasing(0);
    grp = DRW_shgroup_create(sh, psl->smaa_edge_ps);
    DRW_shgroup_uniform_texture(grp, "colorTex", pd->color_tx);
    DRW_shgroup_uniform_texture(grp, "revealTex", pd->reveal_tx);
    DRW_shgroup_uniform_vec4_copy(grp, "viewportMetrics", metrics);
    DRW_shgroup_uniform_float_copy(
        grp, "lumaWeight", pd->scene->grease_pencil_settings.smaa_threshold);

    DRW_shgroup_clear_framebuffer(grp, GPU_COLOR_BIT, 0, 0, 0, 0, 0.0f, 0x0);
    DRW_shgroup_call_procedural_triangles(grp, NULL, 1);
  }
  {
    /* Stage 2: Blend Weight/Coord. */
    DRW_PASS_CREATE(psl->smaa_weight_ps, DRW_STATE_WRITE_COLOR);

    GPUShader *sh = GPENCIL_shader_antialiasing(1);
    grp = DRW_shgroup_create(sh, psl->smaa_weight_ps);
    DRW_shgroup_uniform_texture(grp, "edgesTex", pd->smaa_edge_tx);
    DRW_shgroup_uniform_texture(grp, "areaTex", txl->smaa_area_tx);
    DRW_shgroup_uniform_texture(grp, "searchTex", txl->smaa_search_tx);
    DRW_shgroup_uniform_vec4_copy(grp, "viewportMetrics", metrics);

    DRW_shgroup_clear_framebuffer(grp, GPU_COLOR_BIT, 0, 0, 0, 0, 0.0f, 0x0);
    DRW_shgroup_call_procedural_triangles(grp, NULL, 1);
  }
  {
    /* Stage 3: Resolve. */
    DRW_PASS_CREATE(psl->smaa_resolve_ps, DRW_STATE_WRITE_COLOR | DRW_STATE_BLEND_CUSTOM);

    GPUShader *sh = GPENCIL_shader_antialiasing(2);
    grp = DRW_shgroup_create(sh, psl->smaa_resolve_ps);
    DRW_shgroup_uniform_texture(grp, "blendTex", pd->smaa_weight_tx);
    DRW_shgroup_uniform_texture(grp, "colorTex", pd->color_tx);
    DRW_shgroup_uniform_texture(grp, "revealTex", pd->reveal_tx);
    DRW_shgroup_uniform_bool_copy(grp, "doAntiAliasing", true);
    DRW_shgroup_uniform_bool_copy(grp, "onlyAlpha", pd->draw_wireframe);
    DRW_shgroup_uniform_vec4_copy(grp, "viewportMetrics", metrics);

    DRW_shgroup_call_procedural_triangles(grp, NULL, 1);
  }
}

void GPENCIL_antialiasing_draw(struct GPENCIL_Data *vedata)
{
  GPENCIL_FramebufferList *fbl = vedata->fbl;
  GPENCIL_PrivateData *pd = vedata->stl->pd;
  GPENCIL_PassList *psl = vedata->psl;

  __android_log_print(ANDROID_LOG_DEBUG, "Blender.GP",
      "  SMAA enter: simplify=%d", pd->simplify_antialias);

  if (!pd->simplify_antialias) {
    GPU_framebuffer_bind(fbl->smaa_edge_fb);
    gp_crash_log("ABOUT SMAA edge");
    __android_log_print(ANDROID_LOG_DEBUG, "Blender.GP", "  >> SMAA edge");
    DRW_draw_pass(psl->smaa_edge_ps);
    GPU_flush();
    gp_crash_log("DONE SMAA edge");
    GPU_memory_barrier(GPU_BARRIER_TEXTURE_FETCH);

    GPU_framebuffer_bind(fbl->smaa_weight_fb);
    gp_crash_log("ABOUT SMAA weight");
    __android_log_print(ANDROID_LOG_DEBUG, "Blender.GP", "  >> SMAA weight");
    DRW_draw_pass(psl->smaa_weight_ps);
    GPU_flush();
    gp_crash_log("DONE SMAA weight");
    GPU_memory_barrier(GPU_BARRIER_TEXTURE_FETCH);
  }

  GPU_framebuffer_bind(pd->scene_fb);
  GPU_memory_barrier(GPU_BARRIER_TEXTURE_FETCH | GPU_BARRIER_FRAMEBUFFER);
  gp_crash_log("ABOUT SMAA resolve");
  __android_log_print(ANDROID_LOG_DEBUG, "Blender.GP", "  >> SMAA resolve");
  DRW_draw_pass(psl->smaa_resolve_ps);
  GPU_flush();
  gp_crash_log("DONE SMAA resolve");
  __android_log_print(ANDROID_LOG_DEBUG, "Blender.GP", "  SMAA exit");
}

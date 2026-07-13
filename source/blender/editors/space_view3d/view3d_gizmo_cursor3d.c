/* SPDX-License-Identifier: GPL-2.0-or-later */

/** \file
 * \ingroup spview3d
 *
 * 3D Cursor gizmo: X/Y/Z axis arrows + XY/YZ/ZX planes + center dot.
 * Dragging an arrow moves the cursor along that axis.
 */

#include "BLI_math.h"
#include "BLI_utildefines.h"

#include "BKE_context.h"
#include "BKE_scene.h"

#include "DNA_scene_types.h"
#include "DNA_screen_types.h"
#include "DNA_view3d_types.h"
#include "DNA_windowmanager_types.h"

#include "ED_gizmo_library.h"
#include "ED_screen.h"

#include "UI_resources.h"

#include "MEM_guardedalloc.h"

#include "RNA_access.h"
#include "RNA_prototypes.h"

#include "WM_api.h"
#include "WM_types.h"

#include "view3d_intern.h"

/* -------------------------------------------------------------------- */
/** \name 3D Cursor Gizmo
 * \{ */

enum {
  CURSOR_AXIS_X = 0,
  CURSOR_AXIS_Y,
  CURSOR_AXIS_Z,
  CURSOR_AXIS_XY,
  CURSOR_AXIS_YZ,
  CURSOR_AXIS_ZX,
  CURSOR_AXIS_CENTER,
  CURSOR_AXIS_MAX,
};

typedef struct Cursor3DGizmoGroup {
  wmGizmo *gizmos[CURSOR_AXIS_MAX];
} Cursor3DGizmoGroup;

static void cursor3d_setup_arrow_matrix(wmGizmo *gz, const int axis_idx)
{
  float matrix[3][3];
  unit_m3(matrix);

  switch (axis_idx) {
    case CURSOR_AXIS_X:
      copy_v3_fl3(matrix[0], 1.0f, 0.0f, 0.0f);
      copy_v3_fl3(matrix[1], 0.0f, 0.0f, -1.0f);
      copy_v3_fl3(matrix[2], 0.0f, 1.0f, 0.0f);
      break;
    case CURSOR_AXIS_Y:
      copy_v3_fl3(matrix[0], 0.0f, 1.0f, 0.0f);
      copy_v3_fl3(matrix[1], 0.0f, 0.0f, -1.0f);
      copy_v3_fl3(matrix[2], -1.0f, 0.0f, 0.0f);
      break;
    case CURSOR_AXIS_Z:
      copy_v3_fl3(matrix[0], 1.0f, 0.0f, 0.0f);
      copy_v3_fl3(matrix[1], 0.0f, 1.0f, 0.0f);
      copy_v3_fl3(matrix[2], 0.0f, 0.0f, 1.0f);
      break;
    case CURSOR_AXIS_XY:
      copy_v3_fl3(matrix[0], M_SQRT1_2, M_SQRT1_2, 0.0f);
      copy_v3_fl3(matrix[1], 0.0f, 0.0f, 1.0f);
      copy_v3_fl3(matrix[2], M_SQRT1_2, -M_SQRT1_2, 0.0f);
      break;
    case CURSOR_AXIS_YZ:
      copy_v3_fl3(matrix[0], 0.0f, M_SQRT1_2, M_SQRT1_2);
      copy_v3_fl3(matrix[1], 1.0f, 0.0f, 0.0f);
      copy_v3_fl3(matrix[2], 0.0f, M_SQRT1_2, -M_SQRT1_2);
      break;
    case CURSOR_AXIS_ZX:
      copy_v3_fl3(matrix[0], M_SQRT1_2, 0.0f, M_SQRT1_2);
      copy_v3_fl3(matrix[1], 0.0f, 1.0f, 0.0f);
      copy_v3_fl3(matrix[2], M_SQRT1_2, 0.0f, -M_SQRT1_2);
      break;
    default:
      return;
  }

  copy_m4_m3(gz->matrix_offset, matrix);
}

static void cursor3d_setup_operator(wmGizmo *gz, const int axis_idx)
{
  wmOperatorType *ot = WM_operatortype_find("TRANSFORM_OT_translate", true);
  PointerRNA *ptr = WM_gizmo_operator_set(gz, 0, ot, NULL);

  RNA_boolean_set(ptr, "release_confirm", 1);
  RNA_boolean_set(ptr, "cursor_transform", 1);

  if (axis_idx != CURSOR_AXIS_CENTER) {
    bool constraint[3] = {false};
    switch (axis_idx) {
      case CURSOR_AXIS_X:
        constraint[0] = true;
        break;
      case CURSOR_AXIS_Y:
        constraint[1] = true;
        break;
      case CURSOR_AXIS_Z:
        constraint[2] = true;
        break;
      case CURSOR_AXIS_XY:
        constraint[0] = true;
        constraint[1] = true;
        break;
      case CURSOR_AXIS_YZ:
        constraint[1] = true;
        constraint[2] = true;
        break;
      case CURSOR_AXIS_ZX:
        constraint[2] = true;
        constraint[0] = true;
        break;
    }
    PropertyRNA *prop = RNA_struct_find_property(ptr, "constraint_axis");
    if (prop) {
      RNA_property_boolean_set_array(ptr, prop, constraint);
    }
  }
}

static bool WIDGETGROUP_cursor3d_poll(const bContext *C, wmGizmoGroupType *gzgt)
{
  return ED_gizmo_poll_or_unlink_delayed_from_tool(C, gzgt);
}

static void WIDGETGROUP_cursor3d_setup(const bContext *UNUSED(C), wmGizmoGroup *gzgroup)
{
  Cursor3DGizmoGroup *cgg = MEM_mallocN(sizeof(Cursor3DGizmoGroup), __func__);
  gzgroup->customdata = cgg;

  const wmGizmoType *gzt_arrow = WM_gizmotype_find("GIZMO_GT_arrow_3d", true);
  const wmGizmoType *gzt_prim = WM_gizmotype_find("GIZMO_GT_primitive_3d", true);

  /* Axis arrows (X, Y, Z). */
  for (int i = CURSOR_AXIS_X; i <= CURSOR_AXIS_Z; i++) {
    cgg->gizmos[i] = WM_gizmo_new_ptr(gzt_arrow, gzgroup, NULL);
    wmGizmo *gz = cgg->gizmos[i];
    RNA_enum_set(gz->ptr, "draw_style", ED_GIZMO_ARROW_STYLE_NORMAL);
    cursor3d_setup_arrow_matrix(gz, i);
    cursor3d_setup_operator(gz, i);
  }

  /* Plane arrows (XY, YZ, ZX). */
  for (int i = CURSOR_AXIS_XY; i <= CURSOR_AXIS_ZX; i++) {
    cgg->gizmos[i] = WM_gizmo_new_ptr(gzt_arrow, gzgroup, NULL);
    wmGizmo *gz = cgg->gizmos[i];
    RNA_enum_set(gz->ptr, "draw_style", ED_GIZMO_ARROW_STYLE_PLANE);
    cursor3d_setup_arrow_matrix(gz, i);
    cursor3d_setup_operator(gz, i);
  }

  /* Center primitive (free drag). */
  cgg->gizmos[CURSOR_AXIS_CENTER] = WM_gizmo_new_ptr(gzt_prim, gzgroup, NULL);
  wmGizmo *gz_center = cgg->gizmos[CURSOR_AXIS_CENTER];
  RNA_enum_set(gz_center->ptr, "draw_style", ED_GIZMO_PRIMITIVE_STYLE_CIRCLE);
  RNA_boolean_set(gz_center->ptr, "draw_inner", false);
  WM_gizmo_set_scale(gz_center, 0.2f);
  cursor3d_setup_operator(gz_center, CURSOR_AXIS_CENTER);

  /* Apply theme colors and common properties. */
  float color_primary[3], color_hi[3];
  UI_GetThemeColor3fv(TH_GIZMO_PRIMARY, color_primary);
  UI_GetThemeColor3fv(TH_GIZMO_HI, color_hi);

  for (int i = 0; i < CURSOR_AXIS_MAX; i++) {
    wmGizmo *gz = cgg->gizmos[i];
    copy_v3_v3(gz->color, color_primary);
    copy_v3_v3(gz->color_hi, color_hi);
    WM_gizmo_set_line_width(gz, 2.0f);
    gz->scale_basis = 0.8f;
  }
}

static void WIDGETGROUP_cursor3d_refresh(const bContext *C, wmGizmoGroup *gzgroup)
{
  Cursor3DGizmoGroup *cgg = gzgroup->customdata;
  const Scene *scene = CTX_data_scene(C);

  float cursor_loc[3];
  copy_v3_v3(cursor_loc, scene->cursor.location);

  for (int i = 0; i < CURSOR_AXIS_MAX; i++) {
    WM_gizmo_set_matrix_location(cgg->gizmos[i], cursor_loc);
  }
}

void VIEW3D_GGT_cursor3d(wmGizmoGroupType *gzgt)
{
  gzgt->name = "3D Cursor Gizmo";
  gzgt->idname = "VIEW3D_GGT_cursor3d";

  gzgt->flag |= (WM_GIZMOGROUPTYPE_3D | WM_GIZMOGROUPTYPE_SCALE |
                 WM_GIZMOGROUPTYPE_DEPTH_3D);

  gzgt->poll = WIDGETGROUP_cursor3d_poll;
  gzgt->setup = WIDGETGROUP_cursor3d_setup;
  gzgt->setup_keymap = WM_gizmogroup_setup_keymap_generic_maybe_drag;
  gzgt->refresh = WIDGETGROUP_cursor3d_refresh;
}

/** \} */

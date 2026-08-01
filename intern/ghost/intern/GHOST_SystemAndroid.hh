/* SPDX-FileCopyrightText: 2022-2023 Blender Foundation
 *
 * SPDX-License-Identifier: GPL-2.0-or-later */

/** \file
 * \ingroup GHOST
 * Declaration of GHOST_SystemAndroid class.
 */

#pragma once

#include "../GHOST_Types.h"
#include "GHOST_DisplayManagerNULL.hh"
#include "GHOST_System.hh"
#include "GHOST_WindowAndroid.hh"

#  include "GHOST_ContextEGL.hh"

#include <queue>

/* Centralized Android crash logger. Writes to logcat + device file. */
extern "C" void OBL_log(const char *tag, const char *fmt, ...);

class GHOST_WindowAndroid;

struct KeyEventStatus{
    int m_p_physical_keycode;
    int m_p_unicode;
    int m_p_key_label;
    bool m_p_pressed;
    bool m_p_echo;
};

struct android_app;
class GHOST_SystemAndroid : public GHOST_System {
private:
    void*m_nativeWindow=nullptr;
public:
    int32_t m_x=-1;
    int32_t m_y=-1;
    int32_t m_lastDownx=-1;
    int32_t m_lastDowny=-1;
    bool m_lastClickTopLeftBtn= false;
    uint64_t m_start_time;
    int m_lastButton=-1;
    bool isShiftPressed=false;
    bool isCtrlPressed=false;
    bool isAltPressed=false;
private:
    void showHidenKeyboard(bool show,
            std::string p_existing_text,
            int p_type,
            int p_max_input_length,
            int p_cursor_start,
            int p_cursor_end);
public:
    GHOST_SystemAndroid(void*nativeWindow);
    ~GHOST_SystemAndroid() override = default;

    void showKeyboard(std::string p_existing_text,
                      int p_type,
                      int p_max_input_length,
                      int p_cursor_start,
                      int p_cursor_end) override;
    void hidenKeyboard() override;

    bool processEvents(bool /*waitForEvent*/) override;
    bool setConsoleWindowState(GHOST_TConsoleWindowState /*action*/) override
    {
        return 0;
    }
    GHOST_TSuccess getModifierKeys(GHOST_ModifierKeys & /*keys*/) const override;

    GHOST_TSuccess getButtons(GHOST_Buttons & /*buttons*/) const override
    {
        return GHOST_kSuccess;
    }
    GHOST_TCapabilityFlag getCapabilities() const override;
    char *getClipboard(bool /*selection*/) const override;
    void putClipboard(const char * /*buffer*/, bool /*selection*/) const override;

    uint64_t getMilliSeconds() const override
    {
        timeval tv;
        if (gettimeofday(&tv, nullptr) == -1) {
            GHOST_ASSERT(false, "Could not compute time!");
        }

        /* Taking care not to overflow the tv.tv_sec * 1000 */
        return uint64_t(tv.tv_sec) * 1000 + tv.tv_usec / 1000 - m_start_time;
    }
    uint8_t getNumDisplays() const override
    {
        return uint8_t(1);
    }
    GHOST_TSuccess getCursorPosition(int32_t & x, int32_t & y) const override;
    bool isTouchDown() const override { return m_isTouchDown; }
    GHOST_TSuccess setCursorPosition(int32_t x, int32_t y) override;
    void getMainDisplayDimensions(uint32_t & width, uint32_t & height) const override;
    void getAllDisplayDimensions(uint32_t & width, uint32_t & height) const override;
    GHOST_IContext *createOffscreenContext(GHOST_GLSettings /*gpuSettings*/) override
    {
        GHOST_Context *context;
        for (int minor = 2; minor >= 0; --minor) {
            context = new GHOST_ContextEGL((GHOST_System *)this,
                                           false,
                                           EGLNativeWindowType(0),
                                           EGLNativeDisplayType(EGL_DEFAULT_DISPLAY),
                                           0,
                                           3,
                                           minor,
                                           GHOST_OPENGL_EGL_CONTEXT_FLAGS,
                                           GHOST_OPENGL_EGL_RESET_NOTIFICATION_STRATEGY,
                                           EGL_OPENGL_ES_API);

            if (context->initializeDrawingContext()) {
                return context;
            }
            delete context;
            context = nullptr;
        }

        return context;
    }
    GHOST_TSuccess disposeContext(GHOST_IContext *context) override
    {
        delete context;

        return GHOST_kSuccess;
    }

    GHOST_TSuccess init() override
    {
        GHOST_TSuccess success = GHOST_System::init();

        if (success) {
            m_displayManager = new GHOST_DisplayManagerNULL();

            if (m_displayManager) {
                return GHOST_kSuccess;
            }
        }

        return GHOST_kFailure;
    }

    GHOST_IWindow *createWindow(const char *title,
                                int32_t left,
                                int32_t top,
                                uint32_t width,
                                uint32_t height,
                                GHOST_TWindowState state,
                                GHOST_GLSettings gpuSettings,
                                int shape_type,
                                const bool /*exclusive*/,
                                const bool /*is_dialog*/,
                                const GHOST_IWindow *parentWindow) override;
    void closeWindow()override ;

    void setValue(int values[],int num)override ;
    void setValueOn(int values[],int num)override ;
    void setValueOff(int values[],int num)override ;
    void wmInitReInit()override ;
    void inputKey(int p_physical_keycode,
                          int p_unicode, int p_key_label, bool p_pressed,
                          bool p_echo)override ;
//    GHOST_IWindow *getWindowUnderCursor(int32_t /*x*/, int32_t /*y*/) override
//    {
//        return nullptr;
//    }
    void driveTrackpad();
    void processTrackpad();
    void dispatchEvents() override;

    bool
    generateWindowExposeEvents();
    /// The vector of windows that need to be updated.
    std::vector<GHOST_WindowAndroid *> m_dirty_windows;
    void addDirtyWindow(void*bad_wind);

    GHOST_Event *processWindowEvent(GHOST_TEventType type,
                                    GHOST_IWindow *window);

    bool m_hasOtherEvents= false;
    GHOST_IWindow*m_tobeClosedWindow=nullptr;

    static GHOST_TButton currentButton(android_app *app);

    std::queue<KeyEventStatus> m_keyEventStatus;

    /* Multi-touch gesture state (tracked across input events). */
    int m_mtFingerCount = 0;
    int m_mtPointerCount = 0;
    uint64_t m_mtStartTime = 0;
    float m_mtStartDist = 0.0f;
    float m_mtPrevDist = 0.0f;
    bool m_mtGestureHandled = false;
    bool m_mtActive = false;
    float m_mtPrevCenterX = 0.0f;
    float m_mtPrevCenterY = 0.0f;
    bool m_mtDragActive = false;
    bool m_mtCleanupDone = false;
    bool m_mtOrbitMode = false;
    uint64_t m_mtFirstFingerDownTime = 0;

  /* Scroll mode: single-finger drag sends wheel events instead of LEFT drag. */
  bool m_scrollMode = false;
  float m_scrollLastY = 0.0f;

  /* True while a finger/stylus is pressed on the screen (precision cursor lens). */
  bool m_isTouchDown = false;

  /* Viewport bounds (screen coords). Only the 3D viewport area; everything else is UI/menus. */
  int32_t m_viewportXMin = 0;
  int32_t m_viewportYMin = 0;
  int32_t m_viewportXMax = 600;
  int32_t m_viewportYMax = 800;

  void setViewportBounds(int32_t xmin, int32_t ymin, int32_t xmax, int32_t ymax);

  /* UI Scroll: single-finger drag outside viewport = wheel events. */
  bool m_uiScrollActive = false;
  bool m_uiScrollConsumed = false;
  float m_uiScrollStartX = 0;
  float m_uiScrollStartY = 0;
  float m_uiScrollLastY = 0;

  /* Pending modifier state (set before pushing key events, cleared after dispatchEvents). */
    bool m_pendingCtrl = false;
    bool m_pendingShift = false;

  /* Persistent toggle modifier state (set by setValueOn, cleared by setValueOff; NOT cleared by
   * dispatchEvents). Used by toggle-mode shortcuts (e.g. Shift held via grid). */
  bool m_heldShift = false;
  bool m_heldCtrl = false;
  bool m_heldAlt = false;
};

#include "GHOST_WindowAndroid.hh"
#include "GHOST_SystemAndroid.hh"
#include "android_native_app_glue.h"
#include "GHOST_WindowManager.hh"

GHOST_WindowAndroid::GHOST_WindowAndroid(int shapeType,void*pSystem,const char *title,
                 int32_t /*left*/,
                 int32_t /*top*/,
                 uint32_t width,
                 uint32_t height,
                 GHOST_TWindowState state,
                 const GHOST_IWindow * /*parentWindow*/,
                 GHOST_TDrawingContextType /*type*/,
                 const bool stereoVisual,
                 void *nativeWindow)
        : m_system((GHOST_SystemAndroid*)pSystem),GHOST_Window(width, height, state, stereoVisual, false) {
    m_shpeType=shapeType;
    m_nativeWindow = nativeWindow;
    setTitle(title);
    setDrawingContextType(GHOST_kDrawingContextTypeOpenGL);
    setSwapInterval(0);
}

GHOST_TSuccess GHOST_WindowAndroid::invalidate()
{
    if (!m_invalid_window) {
    m_system->addDirtyWindow(this);
    m_invalid_window = true;
    }
    return GHOST_kSuccess;
}

void GHOST_WindowAndroid::getClientBounds(GHOST_Rect &bounds) const { /* nothing */
//  修改 平板尺寸
//bounds.set(0, 0, 2000,1200);
//        bounds.set(0, 0, 2608, 1220);
//bounds.set(0, 0, 3200, 2136);
    uint32_t width=2000;
    uint32_t height=1200;
    m_system->getMainDisplayDimensions(width,height);
    bounds.set(0,0,width,height);
}

void GHOST_WindowAndroid::loadCursor(bool visible, GHOST_TStandardCursor shape) const
{
    if (!visible) {
        while (ShowCursor(false) >= 0)
            ;
    }
    else {
        while (ShowCursor(true) < 0)
            ;
    }

    long cursor = getStandardCursor(shape);
    if (cursor == NULL) {
        cursor = getStandardCursor(GHOST_kStandardCursorDefault);
    }
    SetCursor(cursor);
}

bool GHOST_WindowAndroid::IsCurrentWindow(){
    GHOST_WindowAndroid *window = (GHOST_WindowAndroid *) m_system->getWindowManager()->getActiveWindow();
    return window==this;
}

GHOST_TSuccess GHOST_WindowAndroid::setWindowCursorVisibility(bool visible)
{
    if (IsCurrentWindow()) {
        loadCursor(visible, getCursorShape());
    }

    return GHOST_kSuccess;
}

GHOST_TSuccess GHOST_WindowAndroid::setWindowCursorGrab(GHOST_TGrabCursorMode mode)
{
    if (mode != GHOST_kGrabDisable) {
        if (mode != GHOST_kGrabNormal) {
            m_system->getCursorPosition(m_cursorGrabInitPos[0], m_cursorGrabInitPos[1]);
            setCursorGrabAccum(0, 0);

            if (mode == GHOST_kGrabHide) {
                setWindowCursorVisibility(false);
            }
        }
//        updateMouseCapture(OperatorGrab);
    }
    else {
        if (m_cursorGrab == GHOST_kGrabHide) {
            m_system->setCursorPosition(m_cursorGrabInitPos[0], m_cursorGrabInitPos[1]);
            setWindowCursorVisibility(true);
        }
        if (m_cursorGrab != GHOST_kGrabNormal) {
            /* Use to generate a mouse move event, otherwise the last event
             * blender gets can be outside the screen causing menus not to show
             * properly unless the user moves the mouse. */
            int32_t pos[2];
            m_system->getCursorPosition(pos[0], pos[1]);
            m_system->setCursorPosition(pos[0], pos[1]);
        }

        /* Almost works without but important otherwise the mouse GHOST location
         * can be incorrect on exit. */
        setCursorGrabAccum(0, 0);
        m_cursorGrabBounds.m_l = m_cursorGrabBounds.m_r = -1; /* disable */
//        updateMouseCapture(OperatorUngrab);
    }

    return GHOST_kSuccess;
}

GHOST_TSuccess GHOST_WindowAndroid::setWindowCursorShape(GHOST_TStandardCursor cursorShape)
{
    if (IsCurrentWindow()) {
        loadCursor(getCursorVisibility(), cursorShape);
    }

    return GHOST_kSuccess;
}

GHOST_TSuccess GHOST_WindowAndroid::hasCursorShape(GHOST_TStandardCursor cursorShape)
{
    return (getStandardCursor(cursorShape)) ? GHOST_kSuccess : GHOST_kFailure;
}
/** Reverse the bits in a uint8_t */
static uint8_t uns8ReverseBits(uint8_t ch)
{
    ch = ((ch >> 1) & 0x55) | ((ch << 1) & 0xAA);
    ch = ((ch >> 2) & 0x33) | ((ch << 2) & 0xCC);
    ch = ((ch >> 4) & 0x0F) | ((ch << 4) & 0xF0);
    return ch;
}
GHOST_TSuccess GHOST_WindowAndroid::setWindowCustomCursorShape(uint8_t *bitmap,
                                                             uint8_t *mask,
                                                             int sizeX,
                                                             int sizeY,
                                                             int hotX,
                                                             int hotY,
                                                             bool /*canInvertColor*/)
{
    uint32_t andData[32];
    uint32_t xorData[32];
    uint32_t fullBitRow, fullMaskRow;
    int x, y, cols;

    cols = sizeX / 8; /* Number of whole bytes per row (width of bitmap/mask). */
    if (sizeX % 8) {
        cols++;
    }

    if (m_customCursor) {
        DestroyCursor(m_customCursor);
        m_customCursor = NULL;
    }

    memset(&andData, 0xFF, sizeof(andData));
    memset(&xorData, 0, sizeof(xorData));

    for (y = 0; y < sizeY; y++) {
        fullBitRow = 0;
        fullMaskRow = 0;
        for (x = cols - 1; x >= 0; x--) {
            fullBitRow <<= 8;
            fullMaskRow <<= 8;
            fullBitRow |= uns8ReverseBits(bitmap[cols * y + x]);
            fullMaskRow |= uns8ReverseBits(mask[cols * y + x]);
        }
        xorData[y] = fullBitRow & fullMaskRow;
        andData[y] = ~fullMaskRow;
    }

    m_customCursor = CreateCursor(0, hotX, hotY, 32, 32, andData, xorData);
    if (!m_customCursor) {
        return GHOST_kFailure;
    }

    if (IsCurrentWindow()) {
        loadCursor(getCursorVisibility(), GHOST_kStandardCursorCustom);
    }

    return GHOST_kSuccess;
}

long GHOST_WindowAndroid::getStandardCursor(GHOST_TStandardCursor shape)const{
    return 1;
}
void GHOST_WindowAndroid::SetCursor(long cursor)const{

}
bool GHOST_WindowAndroid::ShowCursor(bool visible)const{
    return true;
}
long GHOST_WindowAndroid::CreateCursor(int module,int hotX,int hotY,int width,int height,
        uint32_t andData[32], uint32_t xorData[32]){
    return 1;
}
void GHOST_WindowAndroid::DestroyCursor(long cursor){

}

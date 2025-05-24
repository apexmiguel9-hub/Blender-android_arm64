## SPDX-License-Identifier: BSD-3-Clause
## Copyright 2019 Blender Foundation.
#
## - Find Universal Scene Description (USD) library
## Find the native USD includes and libraries
## This module defines
##  USD_INCLUDE_DIRS, where to find USD headers, Set when
##                        USD_INCLUDE_DIR is found.
##  USD_LIBRARIES, libraries to link against to use USD.
##  USD_ROOT_DIR, The base directory to search for USD.
##                    This can also be an environment variable.
##  USD_FOUND, If false, do not try to use USD.
##
#
## If USD_ROOT_DIR was defined in the environment, use it.
#IF(NOT USD_ROOT_DIR AND NOT $ENV{USD_ROOT_DIR} STREQUAL "")
#  SET(USD_ROOT_DIR $ENV{USD_ROOT_DIR})
#ENDIF()
#
#SET(_usd_SEARCH_DIRS
#  ${USD_ROOT_DIR}
#  /opt/lib/usd
#)
#
#FIND_PATH(USD_INCLUDE_DIR
#  NAMES
#    pxr/usd/usd/api.h
#  HINTS
#    ${_usd_SEARCH_DIRS}
#  PATH_SUFFIXES
#    include
#  DOC "Universal Scene Description (USD) header files"
#)
#
## Since USD 21.11 the libraries are prefixed with "usd_", i.e.
## "libusd_m.a" became "libusd_usd_m.a".
## See https://github.com/PixarAnimationStudios/USD/blob/release/CHANGELOG.md#2111---2021-11-01
#FIND_LIBRARY(USD_LIBRARY
#  NAMES
#    usd_usd_m usd_usd_ms usd_m usd_ms
#    ${PXR_LIB_PREFIX}usd
#  NAMES_PER_DIR
#  HINTS
#    ${_usd_SEARCH_DIRS}
#  PATH_SUFFIXES
#    lib64 lib lib/static
#  DOC "Universal Scene Description (USD) monolithic library"
#)
#
#IF(${USD_LIBRARY_NOTFOUND})
#  set(USD_FOUND FALSE)
#ELSE()
#  # handle the QUIETLY and REQUIRED arguments and set USD_FOUND to TRUE if
#  # all listed variables are TRUE
#  INCLUDE(FindPackageHandleStandardArgs)
#  FIND_PACKAGE_HANDLE_STANDARD_ARGS(USD DEFAULT_MSG USD_LIBRARY USD_INCLUDE_DIR)
#
#  IF(USD_FOUND)
#    get_filename_component(USD_LIBRARY_DIR ${USD_LIBRARY} DIRECTORY)
#    SET(USD_INCLUDE_DIRS ${USD_INCLUDE_DIR})
#    set(USD_LIBRARIES ${USD_LIBRARY})
#    IF(EXISTS ${USD_INCLUDE_DIR}/pxr/base/tf/pyModule.h)
#      SET(USD_PYTHON_SUPPORT ON)
#    ENDIF()
#  ENDIF()
#ENDIF()
#
#MARK_AS_ADVANCED(
#  USD_INCLUDE_DIR
#  USD_LIBRARY_DIR
#  USD_LIBRARY
SET(USD_INCLUDE_DIRS
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/include/OpenUSD-23.02/
        )
SET(USD_LIBRARIES
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libhdTiny.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_ar.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_arch.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_cameraUtil.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_geomUtil.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_gf.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_hd.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_hdar.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_hdGp.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_hdsi.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_hf.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_hgi.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_hio.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_js.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_kind.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_ndr.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_pcp.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_plug.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_pxOsd.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_sdf.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_sdr.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_tf.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_trace.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usd.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdGeom.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdHydra.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdImaging.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdLux.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdMedia.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdPhysics.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdProc.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdProcImaging.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdRender.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdRi.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdRiImaging.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdShade.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdSkel.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdSkelImaging.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdUI.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdUtils.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdVol.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_usdVolImaging.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_vt.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusd_work.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libsdrGlslfx.so
        D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/lib/libusdShaders.so
        )
SET(USD_ROOT_DIR D:/FreeProjects/Blender/Blender/lib-android_arm64/OpenUSD/include/OpenUSD-23.02/)
SET(USD_FOUND ON)

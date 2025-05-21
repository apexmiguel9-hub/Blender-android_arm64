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
        F:/FreeProjects/android/OpenUSD/app/src/main/cpp/OpenUSD-23.02/
        )
SET(USD_LIBRARIES
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libhdTiny.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_ar.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_arch.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_cameraUtil.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_geomUtil.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_gf.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_hd.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_hdar.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_hdGp.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_hdsi.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_hf.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_hgi.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_hio.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_js.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_kind.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_ndr.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_pcp.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_plug.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_pxOsd.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_sdf.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_sdr.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_tf.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_trace.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usd.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdGeom.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdHydra.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdImaging.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdLux.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdMedia.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdPhysics.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdProc.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdProcImaging.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdRender.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdRi.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdRiImaging.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdShade.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdSkel.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdSkelImaging.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdUI.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdUtils.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdVol.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_usdVolImaging.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_vt.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusd_work.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libsdrGlslfx.so
        F:/FreeProjects/android/OpenUSD/app/build/intermediates/stripped_native_libs/release/out/lib/arm64-v8a/libusdShaders.so
        )
SET(USD_ROOT_DIR F:/FreeProjects/android/OpenUSD/app/src/main/cpp/OpenUSD-23.02/)
SET(USD_FOUND ON)

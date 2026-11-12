cmake_minimum_required(VERSION 3.16)

# Two targets:
#   equinox-gambatte  the Switch .nro (built with the devkitPro toolchain file)
#   eqx_tests       host unit tests, with -DEQX_HOST_TESTS=ON

project(equinox-gambatte LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(VERSION_MAJOR "1")
set(VERSION_MINOR "1")
set(VERSION_ALTER "0")
set(APP_TITLE "Equinox GBC")
set(APP_AUTHOR "Equinox")
set(APP_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_ALTER}")
set(APP_ICON ${CMAKE_CURRENT_SOURCE_DIR}/icon.jpg)

option(EQX_HOST_TESTS "Build the host unit tests" OFF)

file(GLOB_RECURSE EQX_ALL_SRC CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
set(EQX_LOGIC_SRC ${EQX_ALL_SRC})
list(FILTER EQX_LOGIC_SRC EXCLUDE REGEX "/src/platform/")
# core.cpp calls into the libretro core, which is only linked for the Switch.
list(FILTER EQX_LOGIC_SRC EXCLUDE REGEX "/src/core\\.cpp$")

# Vendored miniz (MIT): memory APIs only, and no zlib-name clashes with portlibs zlib.
add_compile_definitions(MINIZ_NO_STDIO MINIZ_NO_TIME MINIZ_NO_ZLIB_COMPATIBLE_NAMES)
set(EQX_MINIZ_SRC ${CMAKE_CURRENT_SOURCE_DIR}/extern/miniz/miniz.c)
# Vendored LZMA SDK (public domain): the .7z decoder.
file(GLOB EQX_LZMA_SRC CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/extern/lzma/*.c)

if (EQX_HOST_TESTS)
    enable_testing()
    file(GLOB EQX_TEST_SRC CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    add_executable(eqx_tests ${EQX_LOGIC_SRC} ${EQX_TEST_SRC} ${EQX_MINIZ_SRC} ${EQX_LZMA_SRC})
    target_include_directories(eqx_tests PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/extern
        ${CMAKE_CURRENT_SOURCE_DIR}/extern/lzma)
    find_package(Threads REQUIRED)
    target_link_libraries(eqx_tests PRIVATE Threads::Threads)
    add_test(NAME eqx_tests COMMAND eqx_tests)
endif ()

if (NINTENDO_SWITCH)

    set(PORTLIBS_SWITCH /opt/devkitpro/portlibs/switch)

    # The libnx core is built with STATIC_LINKING: the frontend supplies libretro-common.
    set(RC ${CMAKE_CURRENT_SOURCE_DIR}/extern/gambatte/libgambatte/libretro-common)
    set(EQX_LIBRETRO_COMMON_SRC
        ${RC}/compat/compat_posix_string.c
        ${RC}/compat/compat_strcasestr.c
        ${RC}/compat/compat_snprintf.c
        ${RC}/compat/compat_strl.c
        ${RC}/compat/fopen_utf8.c
        ${RC}/encodings/encoding_utf.c
        ${RC}/file/file_path.c
        ${RC}/file/file_path_io.c
        ${RC}/streams/file_stream.c
        ${RC}/streams/file_stream_transforms.c
        ${RC}/string/stdstring.c
        ${RC}/time/rtime.c
        ${RC}/vfs/vfs_implementation.c
    )

    add_executable(equinox-gambatte ${EQX_ALL_SRC} ${EQX_MINIZ_SRC} ${EQX_LZMA_SRC} ${EQX_LIBRETRO_COMMON_SRC})
    target_link_directories(equinox-gambatte PRIVATE ${PORTLIBS_SWITCH}/lib)
    target_include_directories(equinox-gambatte PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/extern
        ${CMAKE_CURRENT_SOURCE_DIR}/extern/lzma
        ${PORTLIBS_SWITCH}/include
        ${PORTLIBS_SWITCH}/include/SDL2
        ${CMAKE_CURRENT_SOURCE_DIR}/extern/gambatte/libgambatte/libretro-common/include)
    target_link_libraries(equinox-gambatte PRIVATE
        ${EQX_CORE_LIB} SDL2_ttf SDL2 freetype harfbuzz freetype png bz2 z EGL glapi drm_nouveau nx)

    nx_generate_nacp(equinox-gambatte.nacp NAME "${APP_TITLE}" AUTHOR "${APP_AUTHOR}" VERSION "${APP_VERSION}")
    nx_create_nro(equinox-gambatte NACP equinox-gambatte.nacp ICON ${APP_ICON})
endif ()

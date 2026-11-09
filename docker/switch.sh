#!/usr/bin/env bash
# Builds equinox-gambatte.nro inside the devkitPro container.
# The CMake build tree lives in a Docker volume (/build) because bind mounts on
# Windows are slow; only the final files are copied back to the repo.
set -euo pipefail

SRC=/src
BUILD=/build/switch
OUT="$SRC/build/docker"
JOBS="${JOBS:-$(nproc)}"
BUILD_TYPE="${BUILD_TYPE:-Release}"

git config --global --add safe.directory '*'

if [ ! -f "$SRC/extern/gambatte/Makefile.libretro" ]; then
    echo "Submodules are missing. Run: git submodule update --init --recursive" >&2
    exit 1
fi

# SDL2 and SDL2_ttf come from devkitPro portlibs.
for pkg in switch-sdl2 switch-sdl2_ttf switch-freetype switch-libpng switch-bzip2 switch-zlib; do
    dkp-pacman -Q "$pkg" >/dev/null 2>&1 || dkp-pacman -S --noconfirm "$pkg"
done

# Gambatte core as a static library.
make -C "$SRC/extern/gambatte" -f Makefile.libretro platform=libnx -j"$JOBS"
CORE_LIB="$SRC/extern/gambatte/gambatte_libretro_libnx.a"

cmake -S "$SRC" -B "$BUILD" \
    -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DEQX_CORE_LIB="$CORE_LIB"
cmake --build "$BUILD" --target equinox-gambatte_nro -j"$JOBS"

mkdir -p "$OUT"
cp "$BUILD/equinox-gambatte.nro" "$OUT/equinox-gambatte.nro"
cp "$BUILD/equinox-gambatte.elf" "$OUT/equinox-gambatte.elf"
echo "Done: build/docker/equinox-gambatte.nro"

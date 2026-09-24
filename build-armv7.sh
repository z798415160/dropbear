#!/usr/bin/env bash
set -euo pipefail

# 工具链路径
TOOLCHAIN_DIR="$(pwd)/armv7l-linux-musleabihf-cross"
TOOLCHAIN_BIN="${TOOLCHAIN_DIR}/bin"

export PATH="${TOOLCHAIN_BIN}:${PATH}"

# 交叉编译三元组
HOST=arm-linux-musleabihf
CC="${HOST}-gcc"
CXX="${HOST}-g++"
AR="${HOST}-ar"
RANLIB="${HOST}-ranlib"
STRIP="${HOST}-strip"

# 版本
ZLIB_VERSION="1.3.1"
DROPBEAR_VERSION="2024.85"

# 下载目录
DOWNLOAD_DIR="$(pwd)/downloads"
BUILD_DIR="$(pwd)/build"
INSTALL_ZLIB="${BUILD_DIR}/zlib-install"
INSTALL_DROPBEAR="${BUILD_DIR}/dropbear-install"
OUTPUT_DIR="$(pwd)/output/dropbear"

mkdir -p "${DOWNLOAD_DIR}" "${BUILD_DIR}" "${OUTPUT_DIR}"

# ---------- zlib ----------
if [ ! -f "${DOWNLOAD_DIR}/zlib-${ZLIB_VERSION}.tar.gz" ]; then
  wget -O "${DOWNLOAD_DIR}/zlib-${ZLIB_VERSION}.tar.gz" \
    "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz"
fi

tar -xzf "${DOWNLOAD_DIR}/zlib-${ZLIB_VERSION}.tar.gz" -C "${BUILD_DIR}"

pushd "${BUILD_DIR}/zlib-${ZLIB_VERSION}"

CC="${CC}" \
AR="${AR}" \
RANLIB="${RANLIB}" \
./configure \
  --prefix="${INSTALL_ZLIB}" \
  --static

make -j"$(nproc)"
make install

popd

# ---------- dropbear ----------
if [ ! -f "${DOWNLOAD_DIR}/dropbear-${DROPBEAR_VERSION}.tar.bz2" ]; then
  wget -O "${DOWNLOAD_DIR}/dropbear-${DROPBEAR_VERSION}.tar.bz2" \
    "https://github.com/mkj/dropbear/releases/download/DROPBEAR_${DROPBEAR_VERSION}/dropbear-${DROPBEAR_VERSION}.tar.bz2"
fi

tar -xjf "${DOWNLOAD_DIR}/dropbear-${DROPBEAR_VERSION}.tar.bz2" -C "${BUILD_DIR}"

pushd "${BUILD_DIR}/dropbear-${DROPBEAR_VERSION}"

./configure \
  --host="${HOST}" \
  --prefix=/usr \
  --with-zlib="${INSTALL_ZLIB}" \
  --enable-static \
  CC="${CC}" \
  CXX="${CXX}" \
  AR="${AR}" \
  RANLIB="${RANLIB}" \
  LDFLAGS="-static" \
  CFLAGS="-Os -ffunction-sections -fdata-sections" \
  LIBS="-lz"

make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" -j"$(nproc)"
make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" install DESTDIR="${INSTALL_DROPBEAR}"

popd

# ---------- 收集产物 ----------
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/bin" "${OUTPUT_DIR}/sbin"

cp "${INSTALL_DROPBEAR}/usr/sbin/dropbear" "${OUTPUT_DIR}/sbin/"
cp "${INSTALL_DROPBEAR}/usr/bin/dbclient" "${OUTPUT_DIR}/bin/"
cp "${INSTALL_DROPBEAR}/usr/bin/dropbearkey" "${OUTPUT_DIR}/bin/"
cp "${INSTALL_DROPBEAR}/usr/bin/dropbearconvert" "${OUTPUT_DIR}/bin/"
cp "${INSTALL_DROPBEAR}/usr/bin/scp" "${OUTPUT_DIR}/bin/" || true

"${STRIP}" "${OUTPUT_DIR}/sbin/dropbear" || true
"${STRIP}" "${OUTPUT_DIR}/bin/"* || true

echo "Build finished: ${OUTPUT_DIR}"

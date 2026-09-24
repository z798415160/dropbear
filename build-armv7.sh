#!/usr/bin/env sh
set -euo pipefail

# 交叉编译三元组（与 muslcc 镜像中的工具链前缀一致）
HOST=armv7l-linux-musleabihf
CC="${HOST}-gcc"
CXX="${HOST}-g++"
AR="${HOST}-ar"
RANLIB="${HOST}-ranlib"
STRIP="${HOST}-strip"

# 版本
ZLIB_VERSION="1.3.1"
DROPBEAR_VERSION="2024.85"

# 路径
BUILD_DIR="/build/build"
INSTALL_ZLIB="${BUILD_DIR}/zlib-install"
INSTALL_DROPBEAR="${BUILD_DIR}/dropbear-install"
OUTPUT_DIR="/build/output/dropbear"

mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

# ---------- zlib ----------
cd "${BUILD_DIR}"
wget -q "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz"
tar -xzf "zlib-${ZLIB_VERSION}.tar.gz"
cd "zlib-${ZLIB_VERSION}"

CC="${CC}" \
AR="${AR}" \
RANLIB="${RANLIB}" \
./configure \
  --prefix="${INSTALL_ZLIB}" \
  --static

make -j"$(nproc)"
make install

# ---------- dropbear ----------
cd "${BUILD_DIR}"
wget -q "https://github.com/mkj/dropbear/releases/download/DROPBEAR_${DROPBEAR_VERSION}/dropbear-${DROPBEAR_VERSION}.tar.bz2"
tar -xjf "dropbear-${DROPBEAR_VERSION}.tar.bz2"
cd "dropbear-${DROPBEAR_VERSION}"

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

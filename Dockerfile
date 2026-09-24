FROM alpine:latest

RUN apk add --no-cache \
    gcc \
    g++ \
    musl-dev \
    binutils \
    make \
    wget \
    bzip2 \
    linux-headers

# 安装 armv7 musl 交叉编译工具链
RUN apk add --no-cache \
    gcc-armv7 \
    g++-armv7 \
    musl-dev-armv7 \
    binutils-armv7

WORKDIR /build

COPY build.sh /build/build-armv7.sh
RUN chmod +x /build/build-armv7.sh

CMD ["/build/build.sh"]

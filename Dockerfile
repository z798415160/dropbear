FROM muslcc/x86_64:armv7l-linux-musleabihf

RUN apk add --no-cache \
    make \
    wget \
    bzip2

WORKDIR /build

COPY build-armv7.sh /build/build-armv7.sh
RUN chmod +x /build/build-armv7.sh

CMD ["/build/build.sh"]

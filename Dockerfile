FROM alpine:3.8

# show backtraces
ENV RUST_BACKTRACE 1

RUN addgroup -g 1000 parity \
  && adduser -u 1000 -G parity -s /bin/sh -D parity

RUN parityVersion='1.10.9' \
  && apk add --no-cache \
    eudev \
    rust \
  && apk add --no-cache --virtual /.build-deps \
    build-base \
    cargo \
    eudev-dev \
    file \
    linux-headers \
  && mkdir build \
  && cd build \
  && wget -O parity.tar.gz https://github.com/paritytech/parity/archive/v$parityVersion.tar.gz \
  && tar -xf parity.tar.gz \
  && cd parity-$parityVersion \
  && cargo build --color never --bin parity --release --verbose \
  && strip -o /home/parity/parity target/release/parity \
  && chown parity /home/parity/parity \
  && rm -rf \
    /build \
    /root/.cargo \
  && apk del /.build-deps

USER parity
ENTRYPOINT ["/home/parity/parity"]

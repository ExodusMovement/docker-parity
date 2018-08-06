FROM alpine:3.8 AS builder

# show backtraces
ENV RUST_BACKTRACE 1

RUN apk add --no-cache \
  build-base \
  cargo \
  cmake \
  eudev-dev \
  linux-headers \
  perl \
  rust

RUN wget -qO- https://github.com/paritytech/parity-ethereum/archive/v1.11.8.tar.gz | tar xz

WORKDIR /parity-ethereum-1.11.8
RUN cargo build --bin parity --release --target x86_64-alpine-linux-musl --verbose --color never
RUN strip target/x86_64-alpine-linux-musl/release/parity


FROM alpine:3.8

ENV RUST_BACKTRACE 1

RUN apk add --no-cache \
  libstdc++ \
  eudev-libs \
  libgcc

RUN addgroup -g 1000 parity \
  && adduser -u 1000 -G parity -s /bin/sh -D parity

USER parity

# UI & P2P & RPC & WS & IPFS & SECURE STORE & SECURE STORE HTTP & STRATUM
EXPOSE 8180 30303 8545 8546 5001 8083 8082 8008

WORKDIR /home/parity

RUN mkdir -p /home/parity/.local/share/io.parity.ethereum/
COPY --chown=parity:parity --from=builder /parity-ethereum-1.11.8/target/x86_64-alpine-linux-musl/release/parity ./

ENTRYPOINT ["./parity"]

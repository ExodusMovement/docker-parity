FROM alpine:3.8 AS builder

# show backtraces
ENV RUST_BACKTRACE 1
ENV BUILD_TAG v1.11.8

RUN apk add --no-cache \
  build-base \
  cargo \
  cmake \
  eudev-dev \
  git \
  linux-headers \
  perl \
  rust

RUN git clone https://github.com/paritytech/parity-ethereum.git

WORKDIR /parity-ethereum
RUN git checkout $BUILD_TAG
RUN cargo build --bin parity --release --features final --target x86_64-alpine-linux-musl --verbose --color never
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

RUN mkdir -p /home/parity/.local/share/io.parity.ethereum/

WORKDIR /home/parity
COPY --chown=parity:parity --from=builder /parity-ethereum/target/x86_64-alpine-linux-musl/release/parity ./

# UI & P2P & RPC & WS & IPFS & SECURE STORE & SECURE STORE HTTP & STRATUM
EXPOSE 8180 30303 8545 8546 5001 8083 8082 8008

ENV \
  PARITY_MODE=last \
  PARITY_CHAIN=foundation \
  PARITY_PORTS_SHIFT=0 \
  PARITY_JSONRPC_PORT=8545 \
  PARITY_JSONRPC_INTERFACE=local \
  PARITY_JSONRPC_THREADS=4 \
  PARITY_JSONRPC_SERVER_THREADS=1 \
  PARITY_ARGUMENTS=""

CMD exec ./parity \
  --mode $PARITY_MODE \
  --chain $PARITY_CHAIN \
  --ports-shift=$PARITY_PORTS_SHIFT \
  --jsonrpc-port=$PARITY_JSONRPC_PORT \
  --jsonrpc-interface=$PARITY_JSONRPC_INTERFACE \
  --jsonrpc-threads=$PARITY_JSONRPC_THREADS \
  --jsonrpc-server-threads=$PARITY_JSONRPC_SERVER_THREADS \
  $PARITY_ARGUMENTS

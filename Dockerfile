FROM alpine:3.8 AS builder

# show backtraces
ENV RUST_BACKTRACE 1
ENV BUILD_TAG 2.0.8

RUN apk add --no-cache \
  build-base \
  cargo \
  cmake \
  eudev-dev \
  git \
  linux-headers \
  perl \
  rust

RUN wget -O- https://github.com/paritytech/parity-ethereum/archive/v$BUILD_TAG.tar.gz | tar xz && mv /parity-ethereum-$BUILD_TAG /parity
WORKDIR /parity
RUN cargo build --bin parity --release --features final --target x86_64-alpine-linux-musl --verbose --color never
RUN strip target/x86_64-alpine-linux-musl/release/parity


FROM alpine:3.8

ENV RUST_BACKTRACE 1

RUN apk add --no-cache \
  libstdc++ \
  eudev-libs \
  libgcc

COPY --from=builder /parity/target/x86_64-alpine-linux-musl/release/parity /usr/local/bin/parity

RUN addgroup -g 1000 parity \
  && adduser -u 1000 -G parity -s /bin/sh -D parity

USER parity
RUN mkdir -p /home/parity/.local/share/io.parity.ethereum/

# P2P & RPC & WS & IPFS & SECURE STORE & SECURE STORE HTTP & STRATUM
EXPOSE 30303 8545 8546 5001 8083 8082 8008

ENV \
  PARITY_MODE=last \
  PARITY_AUTO_UPDATE=critical \
  PARITY_CHAIN=foundation \
  PARITY_PORTS_SHIFT=0 \
  PARITY_MAX_PENDING_PEERS=64 \
  PARITY_JSONRPC_PORT=8545 \
  PARITY_JSONRPC_INTERFACE=local \
  PARITY_JSONRPC_THREADS=4 \
  PARITY_JSONRPC_SERVER_THREADS=1 \
  PARITY_TX_QUEUE_MEM_LIMIT=4 \
  PARITY_TX_QUEUE_SIZE=8192 \
  PARITY_PRUNING=auto \
  PARITY_PRUNING_HISTORY=64 \
  PARITY_ARGUMENTS=""

CMD exec parity \
  --mode $PARITY_MODE \
  --auto-update=$PARITY_AUTO_UPDATE \
  --chain $PARITY_CHAIN \
  --ports-shift=$PARITY_PORTS_SHIFT \
  --max-pending-peers=$PARITY_MAX_PENDING_PEERS \
  --jsonrpc-port=$PARITY_JSONRPC_PORT \
  --jsonrpc-interface=$PARITY_JSONRPC_INTERFACE \
  --jsonrpc-threads=$PARITY_JSONRPC_THREADS \
  --jsonrpc-server-threads=$PARITY_JSONRPC_SERVER_THREADS \
  --tx-queue-mem-limit=$PARITY_TX_QUEUE_MEM_LIMIT \
  --tx-queue-size=$PARITY_TX_QUEUE_SIZE \
  --pruning=$PARITY_PRUNING \
  --pruning-history=$PARITY_PRUNING_HISTORY \
  $PARITY_ARGUMENTS

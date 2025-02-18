FROM debian:bookworm-slim AS base

FROM base AS builder
WORKDIR /wd
RUN apt-get update && apt-get install -y build-essential libssl-dev zlib1g-dev
COPY ./common ./common
COPY ./crypto ./crypto
COPY ./engine ./engine
COPY ./jobs ./jobs
COPY ./mtproto ./mtproto
COPY ./net ./net
COPY ./vv ./vv
COPY Makefile .
ARG COMMIT
ENV COMMIT="${COMMIT}"
RUN make

FROM base AS release
RUN apt-get update && apt-get install -y curl libssl3 zlib1g iproute2 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /wd/objs/bin/mtproto-proxy /usr/local/bin/mtproto-proxy
COPY ./meta/docker/_/bin/mtproxy-cli /usr/local/bin/mtproxy-cli
CMD ["mtproxy-cli", "start"]

FROM debian:bookworm-slim AS builder
WORKDIR /wd
RUN apt-get update && apt-get install -y git curl build-essential libssl-dev zlib1g-dev
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

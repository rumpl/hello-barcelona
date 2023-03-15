# syntax=docker/dockerfile:1

ARG XX_VERSION=1.2.1

FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM --platform=$BUILDPLATFORM debian:bullseye AS base
COPY --from=xx / /
RUN apt-get update && apt-get install -y curl ca-certificates
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --no-modify-path --profile minimal
ENV PATH="/root/.cargo/bin:$PATH"

FROM base as build
RUN apt-get update -y && apt-get install --no-install-recommends -y clang lld
ARG TARGETPLATFORM
RUN xx-apt-get install -y libc6-dev zlib1g-dev
WORKDIR /app
ENV RUSTFLAGS "-C target-feature=+crt-static"
RUN --mount=target=. \
    xx-cargo build --target-dir /build/app --release && \
    xx-verify --static /build/app/$(xx-cargo --print-target-triple)/release/hello-barcelona && \
    cp /build/app/$(xx-cargo --print-target-triple)/release/hello-barcelona /hello-barcelona

FROM scratch
COPY --from=build /hello-barcelona /hello-barcelona
ENTRYPOINT  ["/hello-barcelona"]

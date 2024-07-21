VERSION 0.8
FROM ghcr.io/gleam-lang/gleam:v1.2.1-erlang-alpine
RUN apk add just
WORKDIR /source
VOLUME docker_gleam_build $WORKDIR/build

deps:
    COPY gleam.toml ./
    COPY manifest.toml ./
    COPY Justfile ./
    COPY src src
    COPY test test
    RUN gleam build

test:
    FROM +deps
    RUN just test

all:
    BUILD +test

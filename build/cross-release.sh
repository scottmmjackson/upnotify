#!/usr/bin/env bash

compile() {
  local target=$1
  local binname=$2
  cargo build --release --target "${target}" || return
  mkdir -p "dist/${binname}" && cp "target/${target}/release/upnotify" "dist/${binname}/"
}

# compile x86_64-unknown-linux-gnu linux_amd64
compile x86_64-apple-darwin darwin_amd64
compile aarch64-apple-darwin darwin_arm64
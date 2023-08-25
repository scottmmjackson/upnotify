#!/usr/bin/env bash

compile() {
  local cargo_target=$1
  local goos=$2
  cargo build --release --target "${cargo_target}" || return
  cp "target/${cargo_target}/release/upnotify" "dist/${goos}/"
}

# compile x86_64-unknown-linux-gnu linux_amd64
compile x86_64-apple-darwin darwin_amd64
compile aarch64-apple-darwin darwin_arm64
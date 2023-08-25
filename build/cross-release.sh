#!/usr/bin/env bash

compile() {
  local cargo_target=$1
  local goos=$2
  cargo build --release --target "${cargo_target}" || return
  cp "target/${cargo_target}/release/upnotify" "dist/upnotify_${goos}/"
}

target=$1
os=$2
arch=$3

case $os in
  darwin) case $arch in
    arm64) cargo_target=aarch64-apple-darwin
      ;;
    amd64) cargo_target=x86_64-apple-darwin
      ;;
  esac
  ;;
  linux) case $arch in
    arm64)
      ;;
    amd64)
      ;;
  esac
  ;;
  windows)
    case $arch in
        arm64)
          ;;
        amd64)
          ;;
    esac
    ;;
esac

# compile x86_64-unknown-linux-gnu linux_amd64
compile x86_64-apple-darwin "${target}"
compile aarch64-apple-darwin darwin_arm64
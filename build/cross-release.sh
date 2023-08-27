#!/usr/bin/env bash

die() {
  echo "FAILED TO COMPILE"
  exit 1
}

compile() {
  local cargo_target=$1
  local goos=$2
#  docker run --rm --name "upnotify-release-${cargo_target}" --user "$(id -u)":"$(id -g)" -v "$PWD":/usr/src/myapp \
#   -w /usr/src/myapp rust:1.70 sh -c \
#   "rustup target add $cargo_target && cargo build --release --target ${cargo_target}" || die
  cargo build --release "${cargo_target}" || die
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
    arm64) cargo_target=aarch64-unknown-linux-gnu
      ;;
    amd64) cargo_target=x86_64-unknown-linux-gnu
      ;;
  esac
  ;;
  windows)
    case $arch in
        arm64) cargo_target=aarch64-pc-windows-msvc
          ;;
        amd64) cargo_target=x86_64-pc-windows-gnu
          ;;
    esac
    ;;
esac

compile "${cargo_target}" "${target}"
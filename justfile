target:=`rustc -vV | sed -n 's|host: ||p'`

default: build

build:
    cargo build --release --target {{target}}
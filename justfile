target:=`rustc -vV | sed -n 's|host: ||p'`
os_family:=os_family()
archive_type:=if os_family == "windows" { "zip" } else { "tarball" }
package_type:="none"
os:=os()
arch:=arch()
version:=`toml get Cargo.toml package.version --raw`
archive_name:="upnotify-{{version}}-{{target}}"
msg:="Unknown error"

default: build

die:
    @echo "Error: {{msg}}"

assert-darwin-host:
    @{{ if os == "macos" { "true" } else { "just msg=\"Not a darwin host\" die" } }}

clean:
    rm -rf target dist

build:
    cargo build --release --target {{target}}

build-mac-m1:
    just target=aarch64-apple-darwin assert-darwin-host archive

build-linux-amd64:
    docker run --rm --platform linux/amd64 --user "$(id -u)":"$(id -g)" -v "$PWD":/usr/src/myapp -w /usr/src/myapp \
        rust:1.70.0 sh -c "cargo install just toml-cli && just archive"

build-linux-arm64:
    docker run --rm --platform linux/arm64 --user "$(id -u)":"$(id -g)" -v "$PWD":/usr/src/myapp -w /usr/src/myapp \
        rust:1.70.0 sh -c "cargo install just toml-cli && just archive"

archive-tarball:
    tar czf dist/{{target}}/{{archive_name}}.tar.gz target/{{target}}/release/upnotify

archive-zip:
    zip dist/{{target}}/{{archive_name}}.zip target/{{target}}/release/upnotify

archive-all:
    just archive-tarball archive-zip

archive: build
    just archive-{{archive_type}}

package-none:
    @echo "Nothing to do; specify a package_type"

package-rpm:
    #!/usr/bin/env bash
    mkdir -p dist/{{target}}
    source build/{{target}}.env
    nfpm package -p rpm -f <(VERSION={{version}} envsubst < build/nfpm.yaml.tmpl) --target dist/{{target}}/

package-deb:
    #!/usr/bin/env bash
    mkdir -p dist/{{target}}
    source build/{{target}}.env
    nfpm package -p deb -f <(VERSION={{version}} envsubst < build/nfpm.yaml.tmpl) --target dist/{{target}}/

linux-packages:
    just target=x86_64-unknown-linux-gnu package-deb package-rpm
    just target=aarch64-unknown-linux-gnu package-deb package-rpm

package:
    just package-{{package_type}}

homebrew-program:


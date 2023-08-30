target:=`rustc -vV | sed -n 's|host: ||p'`
os_family:=os_family()
archive_type:=if os_family == "windows" { "zip" } else { "tarball" }
package_type:="none"
os:=os()
arch:=arch()
version:=`toml get Cargo.toml package.version --raw`
archive_name:="upnotify-" + version + "-" + target
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

build-all: build-mac-m1 build-mac-x86 build-linux-amd64 build-linux-arm64

build-mac-m1:
    just target=aarch64-apple-darwin assert-darwin-host archive

build-mac-x86:
    just target=x86_64-apple-darwin assert-darwin-host archive

build-linux-amd64:
    docker run --rm --platform linux/amd64 --user "$(id -u)":"$(id -g)" -v "$PWD":/usr/src/myapp -w /usr/src/myapp \
        rust:1.70.0 sh -c "cargo install just toml-cli && just archive"

build-linux-arm64:
    docker run --rm --platform linux/arm64 --user "$(id -u)":"$(id -g)" -v "$PWD":/usr/src/myapp -w /usr/src/myapp \
        rust:1.70.0 sh -c "cargo install just toml-cli && just archive"

archive-tarball:
    mkdir -p dist/{{target}}
    tar czf dist/{{target}}/{{archive_name}}.tar.gz -C target/{{target}}/release/ upnotify

archive-zip:
    zip dist/{{target}}/{{archive_name}}.zip target/{{target}}/release/upnotify

archive-all:
    just archive-tarball archive-zip

archive: build
    just target={{target}} archive-{{archive_type}}

package:
    #!/usr/bin/env bash
    mkdir -p dist/{{target}}
    source build/{{target}}.env
    nfpm package -p {{package_type}} \
      -f <(VERSION={{version}} BIND_FILE=/usr/bin/upnotify envsubst < build/nfpm.yaml.tmpl) --target dist/{{target}}/

package-termux:
    #!/usr/bin/env bash
    mkdir -p dist/{{target}}
    mkdir -p dist/tmp/
    source build/{{target}}.env
    nfpm package -p {{package_type}} \
      -f <(VERSION={{version}} BIND_FILE=/data/data/com.termux/files envsubst < build/nfpm.yaml.tmpl) \
      --target dist/tmp/
    export DEBARCH="{{if target =~ '^x86_64' { "amd64" } else { "arm64" } }}"
    mv dist/tmp/upnotify_{{version}}_${DEBARCH}.deb dist/{{target}}/upnotify_{{version}}_${DEBARCH}.termux.deb
    rmdir dist/tmp

linux-packages:
    just target=x86_64-unknown-linux-gnu package_type=deb package
    just target=x86_64-unknown-linux-gnu package_type=rpm package
    just target=x86_64-unknown-linux-gnu package_type=deb package-termux
    just target=aarch64-unknown-linux-gnu package_type=deb package
    just target=aarch64-unknown-linux-gnu package_type=rpm package
    just target=aarch64-unknown-linux-gnu package_type=deb package-termux

create-release:
    gh release create {{version}}

upload-to-release:
    gh release view {{version}} || just msg="Release does not exist" die
    gh release upload {{version}} \
        dist/aarch64-apple-darwin/upnotify-{{version}}-aarch64-apple-darwin.tar.gz \
        dist/x86_64-apple-darwin/upnotify-{{version}}-x86_64-apple-darwin.tar.gz \
        dist/aarch64-unknown-linux-gnu/upnotify-{{version}}-aarch64-unknown-linux-gnu.tar.gz \
        dist/aarch64-unknown-linux-gnu/upnotify-{{version}}.aarch64.rpm \
        dist/aarch64-unknown-linux-gnu/upnotify_{{version}}_arm64.deb \
        dist/x86_64-unknown-linux-gnu/upnotify-{{version}}-x86_64-unknown-linux-gnu.tar.gz \
        dist/x86_64-unknown-linux-gnu/upnotify-{{version}}.x86_64.rpm \
        dist/x86_64-unknown-linux-gnu/upnotify_{{version}}_amd64.deb \
        --clobber


homebrew-program:
    #!/usr/bin/env bash
    export VERSION={{version}}
    export X86_DARWIN_RELEASE_URL=$(gh release view {{version}} --json assets --jq \
      '.assets[] | select(.name=="upnotify-{{version}}-x86_64-apple-darwin.tar.gz") | .url')
    export X86_DARWIN_RELEASE_SHA=$(shasum -a 256 \
      dist/x86_64-apple-darwin/upnotify-{{version}}-x86_64-apple-darwin.tar.gz | awk '{print $1}')
    export ARM64_DARWIN_RELEASE_URL=$(gh release view {{version}} --json assets --jq \
      '.assets[] | select(.name=="upnotify-{{version}}-aarch64-apple-darwin.tar.gz") | .url')
    export ARM64_DARWIN_RELEASE_SHA=$(shasum -a 256 \
      dist/aarch64-apple-darwin/upnotify-{{version}}-aarch64-apple-darwin.tar.gz | awk '{print $1}')
    export X86_LINUX_RELEASE_URL=$(gh release view {{version}} --json assets --jq \
      '.assets[] | select(.name=="upnotify-{{version}}-x86_64-unknown-linux-gnu.tar.gz") | .url')
    export X86_LINUX_RELEASE_SHA=$(shasum -a 256 \
      dist/x86_64-unknown-linux-gnu/upnotify-{{version}}-x86_64-unknown-linux-gnu.tar.gz | awk '{print $1}')
    export ARM64_LINUX_RELEASE_URL=$(gh release view {{version}} --json assets --jq \
      '.assets[] | select(.name=="upnotify-{{version}}-aarch64-unknown-linux-gnu.tar.gz") | .url')
    export ARM64_LINUX_RELEASE_SHA=$(shasum -a 256 \
      dist/aarch64-unknown-linux-gnu/upnotify-{{version}}-aarch64-unknown-linux-gnu.tar.gz | awk '{print $1}')
    envsubst < build/program.rb.tmpl > dist/program.rb

homebrew-update: homebrew-program
    #!/usr/bin/env bash
    git clone https://github.com/scottmmjackson/homebrew-sj dist/tap
    cd dist/tap
    git checkout -b upnotify-{{version}}
    cp ../program.rb Formula/upnotify.rb
    git add Formula/upnotify.rb
    git commit -m "Added formula for upnotify {{version}}"
    git push origin HEAD
    gh pr create --title "Added formula for upnotify {{version}}" --body "Added formula for upnotify {{version}}"

do-release-build: build-all

do-release-package-preflight:
    @stat dist/aarch64-apple-darwin/upnotify-{{version}}-aarch64-apple-darwin.tar.gz > /dev/null
    @stat dist/x86_64-apple-darwin/upnotify-{{version}}-x86_64-apple-darwin.tar.gz > /dev/null
    @stat dist/aarch64-unknown-linux-gnu/upnotify-{{version}}-aarch64-unknown-linux-gnu.tar.gz > /dev/null
    @stat dist/x86_64-unknown-linux-gnu/upnotify-{{version}}-x86_64-unknown-linux-gnu.tar.gz > /dev/null
    # For linux packages
    @stat target/x86_64-unknown-linux-gnu/release/upnotify > /dev/null
    @stat target/aarch64-unknown-linux-gnu/release/upnotify > /dev/null

do-release-package: do-release-package-preflight linux-packages create-release upload-to-release homebrew-update

do-release: do-release-build do-release-package

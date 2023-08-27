target:=`rustc -vV | sed -n 's|host: ||p'`
os_family:=os_family()
archive_type:=if os_family == "windows" { "zip" } else { "tarball" }
os:=os()
arch:=arch()
version:=`git tag`

default: build

sys-info:
    @echo "os_family {{os_family()}}"
    @echo "os {{os()}}"
    @echo "arch: {{arch()}}"

clean:
    rm -rf target

build:
    cargo build --release --target {{target}}

build-mac-m1:
    just target=aarch64-apple-darwin archive

archive-tarball:
    tar czf target/{{target}}/release/upnotify-{{version}}-{{target}}.tar.gz target/{{target}}/release/upnotify

archive-zip:
    zip target/{{target}}/release/upnotify-{{version}}-{{target}}.zip target/{{target}}/release/upnotify

archive: build
    just archive-{{archive_type}}
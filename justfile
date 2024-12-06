set shell := ["C:\\Program Files\\Git\\bin\\bash.exe", "-c"]

default: clean

gen:
    rm -rf lib/rust/* rust/src/frb_generated*
    flutter_rust_bridge_codegen generate

lint:
    cd rust && cargo fmt

clean:
    flutter clean && flutter pub get

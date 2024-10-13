zig build
cp zig-out/bin/game.wasm .
# zig build-exe src/game.zig -target wasm32-freestanding -fno-entry -rdynamic

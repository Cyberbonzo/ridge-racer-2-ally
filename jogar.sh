#!/bin/sh
set -eu
cd "$(dirname "$(readlink -f "$0")")"
if ! grep -qx 'terms_version=1' "${XDG_CONFIG_HOME:-$HOME/.config}/nimbus/terms-accepted.txt" 2>/dev/null; then
    exec ./Nimbus.run
fi
mkdir -p profile logs
game=$$
export SDL_GAMECONTROLLERCONFIG="030010f85e040000000b000001000000,Xbox One Elite 2 Controller,a:b0,a:a5,b:b1,x:b2,x:a2,y:b3,back:b6,guide:b8,start:b7,leftstick:b9,rightstick:b10,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,misc1:b19,paddle1:b15,paddle2:b17,paddle3:b16,paddle4:b18,leftx:a0,lefty:a1,rightx:a3,righty:a4,"
if [ -n "${DISPLAY:-}" ] && command -v xdotool >/dev/null; then
    (
        for _ in $(seq 1 100); do
            kill -0 "$game" 2>/dev/null || exit 0
            window=$(xdotool search --onlyvisible --all --pid "$game" --name '^Nimbus - Ridge Racer 2$' 2>/dev/null | head -1)
            if [ -n "$window" ]; then
                xdotool windowsize "$window" 1920 1080
                exit 0
            fi
            sleep 0.2
        done
    ) &
fi
export NIMBUS_PSP_AT3P_ME="$PWD/runtime/at3p_me.so"
exec ./runtime/nimbushost-psp --core "$PWD/runtime/UCES00422.so" \
    --iso "$PWD/media/disc.iso" --exe-from-iso --work "$PWD/profile" \
    --gfx "$PWD/runtime/renderer.so" --api vulkan --scale 4 \
    --stop-field 2147483647 --lang en "$@" >logs/game.log 2>&1

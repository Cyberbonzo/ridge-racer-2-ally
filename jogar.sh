#!/bin/sh
set -eu
cd "$(dirname "$(readlink -f "$0")")"
if ! grep -qx 'terms_version=1' "${XDG_CONFIG_HOME:-$HOME/.config}/nimbus/terms-accepted.txt" 2>/dev/null; then
    exec ./Nimbus.run
fi
mkdir -p profile/user logs
if [ ! -e profile/user/performance.ini ]; then
    cp performance.ini profile/user/performance.ini
fi
automatic=1
for arg in "$@"; do
    case "$arg" in
        --np-host|--np-join|--load-state|--save-state-on-exit|--save-state-at) automatic=0;;
    esac
done
if [ "$automatic" = 1 ]; then
    mkdir -p progress
    exec 9>progress/session.lock
    flock -n 9 || { echo "Já existe uma sessão offline de Ridge Racer 2." >&2; exit 1; }
    resume=$(python3 progresso.py prepare)
    if [ -n "$resume" ]; then
        set -- "$@" --load-state "$resume"
    fi
    set -- "$@" --save-state-on-exit "$PWD/progress/saida.state"
    python3 progresso.py watch "$$" 9>&- >logs/progresso.log 2>&1 &
fi
game=$$
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
core="$PWD/runtime/rr2-nitro.so"
for arg in "$@"; do
    case "$arg" in --np-host|--np-join) core="$PWD/runtime/UCES00422.so";; esac
done
exec ./runtime/nimbushost-psp --core "$core" \
    --iso "$PWD/media/disc.iso" --exe-from-iso --work "$PWD/profile" \
    --gfx "$PWD/runtime/renderer.so" --api vulkan --scale 4 \
    --stop-field 2147483647 --lang en "$@" >logs/game.log 2>&1

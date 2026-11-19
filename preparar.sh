#!/bin/sh
set -eu
cd "$(dirname "$(readlink -f "$0")")"
printf '%s\n' '91acc19a2c7637c80512727a803ab22b948fc2585cf2087413fc32b71f05d2ab  Nimbus.run' \
    'e47a7ca79d04cc342531e5c180306c7cea5e0dcfd448190e2474995527b3ef7c  media/disc.iso' | sha256sum -c -
cache="${XDG_CACHE_HOME:-$HOME/.cache}/nimbus-native"
mkdir -p runtime
while read -r digest name; do
    if (cd runtime && printf '%s  %s\n' "$digest" "$name" | sha256sum --status -c -); then
        continue
    fi
    found=0
    for file in "$cache"/*/"$name"; do
        [ -f "$file" ] || continue
        if printf '%s  %s\n' "$digest" "$file" | sha256sum --status -c -; then
            tmp=$(mktemp "runtime/.$name.XXXXXX")
            install -m 755 "$file" "$tmp" && mv -f "$tmp" "runtime/$name"
            found=1
            break
        fi
    done
    if [ "$found" = 0 ]; then
        echo "Inicie UCES00422 no Nimbus para extrair $name e execute este script novamente." >&2
        exit 1
    fi
done <runtime.sha256
(cd runtime && sha256sum -c ../runtime.sha256)

#!/bin/bash
set -e
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

SRC=~/agents/football-gf/data/media
DST=~/agents/football-godot/assets

mkdir -p "$DST/textures" "$DST/sounds" "$DST/data"

# Dokular
cp -r "$SRC/textures/"* "$DST/textures/"
echo "Dokular kopyalandı: $(find "$DST/textures" -name '*.png' -o -name '*.jpg' | wc -l) dosya"

# Sesler
cp "$SRC/sounds/"*.wav "$DST/sounds/"
echo "Sesler kopyalandı: $(ls "$DST/sounds/"*.wav | wc -l) dosya"

# Veritabanı
cp ~/agents/football-gf/data/databases/default/database.sqlite "$DST/data/"
echo "Veritabanı kopyalandı"

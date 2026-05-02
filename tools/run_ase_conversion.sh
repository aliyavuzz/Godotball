#!/bin/bash
set -e
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

ASE_DIR="${1:-$HOME/agents/football-gf/data/media/objects}"
OUT_DIR="${2:-$HOME/agents/football-godot/assets/models}"

blender --background --python "$(dirname "$0")/ase_to_gltf.py" -- "$ASE_DIR" "$OUT_DIR"

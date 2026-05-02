# Blender Python ortamında çalışır:
# blender --background --python ase_to_gltf.py -- <ase_dir> <out_dir>
import bpy
import sys
import os
from pathlib import Path


def clear_scene():
    bpy.ops.wm.read_homefile(use_empty=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()


def convert_ase_to_gltf(ase_path: Path, out_dir: Path) -> bool:
    clear_scene()
    try:
        bpy.ops.import_scene.ase(filepath=str(ase_path))
    except Exception as e:
        print(f"ASE import failed for {ase_path}: {e}")
        return False

    out_path = out_dir / ase_path.with_suffix('.glb').name
    out_dir.mkdir(parents=True, exist_ok=True)

    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format='GLB',
        export_animations=True,
        export_skins=True,
        export_materials='EXPORT'
    )
    print(f"Exported: {out_path}")
    return True


if __name__ == '__main__':
    argv = sys.argv
    if '--' in argv:
        argv = argv[argv.index('--') + 1:]
    ase_dir = Path(argv[0])
    out_dir = Path(argv[1])

    ase_files = list(ase_dir.rglob('*.ase'))
    print(f"{len(ase_files)} .ase dosya bulundu")
    success = 0
    for f in ase_files:
        rel = f.relative_to(ase_dir)
        target_dir = out_dir / rel.parent
        if convert_ase_to_gltf(f, target_dir):
            success += 1

    print(f"Dönüştürüldü: {success}/{len(ase_files)}")

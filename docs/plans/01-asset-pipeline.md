# Asset Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:test-driven-development` for converter scripts and `superpowers:verification-before-completion` before marking done.

**Goal:** GameplayFootball'ın tüm varlıklarını (.ase, .object, .anim, textures, sounds) Godot 4 uyumlu formatlara dönüştürmek.

**Architecture:** Python scriptleri `.object` XML ve `.anim` CSV formatlarını parse ederek Godot `.tres` animasyonlarına ve GLTF skeleton tanımlarına dönüştürür. `.ase` mesh dosyaları Blender Python API ile GLTF'e çevrilir. Dokular ve sesler doğrudan kopyalanır.

**Tech Stack:** Python 3.12, Blender 3.x/4.x (headless), xml.etree, json, pathlib

---

## Başlamadan Önce

```bash
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
cd ~/agents/football-godot
cat docs/PROJECT.md   # Genel bağlamı anla
ls ~/agents/football-gf/data/media/  # Kaynak varlıkları gör
```

**Kaynak dizinler:**
- Animasyonlar: `~/agents/football-gf/data/media/animations/`
- Modeller: `~/agents/football-gf/data/media/objects/`
- Dokular: `~/agents/football-gf/data/media/textures/`
- Sesler: `~/agents/football-gf/data/media/sounds/`

**Hedef dizinler:**
- `~/agents/football-godot/assets/animations/`  → Godot AnimationLibrary (.tres)
- `~/agents/football-godot/assets/models/`      → GLTF/GLB dosyaları
- `~/agents/football-godot/assets/textures/`    → PNG/JPG (kopyala)
- `~/agents/football-godot/assets/sounds/`      → WAV (kopyala)

---

## Task 1: .anim → Godot AnimationLibrary Dönüştürücü

**Files:**
- Create: `tools/anim_converter.py`
- Create: `tools/test_anim_converter.py`

### .anim Format Referansı

```
bone_name,frame,qx,qy,qz,qw,frame,qx,qy,qz,qw,...
player,0,0.0,0.0,-0.16,frame2,...   ← pozisyon satırı (4 sayı = xyz+unused)
body,0,-0.12,0.0,0.0,0.99,...       ← rotasyon satırı (4 sayı = quaternion xyzw)
<steps>2</steps>
<type>movement</type>
```

**Kural:** `player` satırı pozisyon (x,y,z + fazladan), diğer satırlar quaternion rotasyon.

- [ ] **Step 1: Test yaz**

```python
# tools/test_anim_converter.py
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from tools.anim_converter import parse_anim_file, AnimKeyframe, AnimBone

def test_parse_simple_anim():
    content = """player,0,0.0,0.0,-0.16,6,0.02,-0.20,-0.19
body,0,-0.125,0.0,0.0,0.992
<steps>
\t2
</steps>
<type>
\tmovement
</type>"""
    result = parse_anim_file(content)
    assert result['type'] == 'movement'
    assert result['steps'] == 2
    assert 'player' in result['bones']
    assert len(result['bones']['player']) == 2  # 2 keyframe
    assert result['bones']['player'][0].frame == 0
    assert abs(result['bones']['player'][0].z + 0.16) < 0.001
    assert 'body' in result['bones']
    assert abs(result['bones']['body'][0].qw - 0.992) < 0.001

def test_parse_real_anim_file():
    path = os.path.expanduser(
        '~/agents/football-gf/data/media/animations/movement/dribble/135.anim'
    )
    with open(path) as f:
        content = f.read()
    result = parse_anim_file(content)
    assert result['type'] == 'movement'
    assert 'body' in result['bones']
    assert 'left_thigh' in result['bones']
    assert 'right_thigh' in result['bones']
    assert len(result['bones']['body']) > 1

if __name__ == '__main__':
    test_parse_simple_anim()
    test_parse_real_anim_file()
    print('ALL TESTS PASSED')
```

- [ ] **Step 2: Testi çalıştır, FAIL bekliyoruz**

```bash
cd ~/agents/football-godot
python3 tools/test_anim_converter.py
# Beklenen: ModuleNotFoundError veya ImportError
```

- [ ] **Step 3: Parser yaz**

```python
# tools/anim_converter.py
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

@dataclass
class AnimKeyframe:
    frame: int
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0
    qw: float = 1.0  # rotasyon için

@dataclass
class AnimBone:
    name: str
    keyframes: List[AnimKeyframe] = field(default_factory=list)

def parse_anim_file(content: str) -> dict:
    """Parse .anim dosyasını dict'e çevirir."""
    result = {'type': 'unknown', 'steps': 1, 'bones': {}}

    # XML meta verileri çıkar
    type_match = re.search(r'<type>\s*(\w+)\s*</type>', content)
    if type_match:
        result['type'] = type_match.group(1)

    steps_match = re.search(r'<steps>\s*(\d+)\s*</steps>', content)
    if steps_match:
        result['steps'] = int(steps_match.group(1))

    # Kemik satırlarını işle
    for line in content.split('\n'):
        line = line.strip()
        if not line or line.startswith('<'):
            continue
        parts = line.split(',')
        if len(parts) < 2:
            continue

        bone_name = parts[0]
        values = parts[1:]
        keyframes = []

        is_position = (bone_name == 'player')

        i = 0
        while i < len(values):
            try:
                frame = int(values[i])
                i += 1
                if is_position:
                    # player: frame, x, y, z (+ bazen 4. değer var)
                    x = float(values[i]) if i < len(values) else 0.0
                    y = float(values[i+1]) if i+1 < len(values) else 0.0
                    z = float(values[i+2]) if i+2 < len(values) else 0.0
                    keyframes.append(AnimKeyframe(frame=frame, x=x, y=y, z=z))
                    i += 3
                    # Bazen 4. değer var (skip)
                    if i < len(values):
                        try:
                            int(values[i])  # sonraki frame sayısı mı?
                        except ValueError:
                            i += 1  # fazladan float, atla
                else:
                    # Rotasyon: frame, qx, qy, qz, qw
                    qx = float(values[i]) if i < len(values) else 0.0
                    qy = float(values[i+1]) if i+1 < len(values) else 0.0
                    qz = float(values[i+2]) if i+2 < len(values) else 0.0
                    qw = float(values[i+3]) if i+3 < len(values) else 1.0
                    keyframes.append(AnimKeyframe(frame=frame, x=qx, y=qy, z=qz, qw=qw))
                    i += 4
            except (ValueError, IndexError):
                i += 1

        if keyframes:
            result['bones'][bone_name] = keyframes

    return result


def convert_anim_to_tres(anim_path: Path, output_path: Path,
                          fps: float = 30.0) -> bool:
    """Tek .anim dosyasını Godot .tres AnimationLibrary'ye çevirir."""
    with open(anim_path) as f:
        content = f.read()

    data = parse_anim_file(content)
    anim_name = anim_path.stem

    # Godot .tres formatı (text resource)
    lines = [
        '[gd_resource type="Animation" format=3]',
        '',
        '[resource]',
        f'resource_name = "{anim_name}"',
        f'length = {data["steps"] / fps:.4f}',
        'loop_mode = 1',
        'step = 0.1',
        '',
    ]

    track_idx = 0
    for bone_name, keyframes in data['bones'].items():
        if not keyframes:
            continue

        if bone_name == 'player':
            # Pozisyon track'i
            lines.append(f'tracks/{track_idx}/type = "position_3d"')
            lines.append(f'tracks/{track_idx}/imported = false')
            lines.append(f'tracks/{track_idx}/enabled = true')
            lines.append(f'tracks/{track_idx}/path = NodePath("Skeleton3D:{bone_name}")')
            lines.append(f'tracks/{track_idx}/interp = 1')
            lines.append(f'tracks/{track_idx}/loop_wrap = true')
            keys = []
            for kf in keyframes:
                t = kf.frame / fps
                keys.extend([t, 1.0, kf.x, kf.y, kf.z])
            lines.append(f'tracks/{track_idx}/keys = PackedFloat32Array({", ".join(str(v) for v in keys)})')
        else:
            # Rotasyon track'i (quaternion)
            lines.append(f'tracks/{track_idx}/type = "rotation_3d"')
            lines.append(f'tracks/{track_idx}/imported = false')
            lines.append(f'tracks/{track_idx}/enabled = true')
            lines.append(f'tracks/{track_idx}/path = NodePath("Skeleton3D:{bone_name}")')
            lines.append(f'tracks/{track_idx}/interp = 1')
            lines.append(f'tracks/{track_idx}/loop_wrap = true')
            keys = []
            for kf in keyframes:
                t = kf.frame / fps
                keys.extend([t, 1.0, kf.x, kf.y, kf.z, kf.qw])
            lines.append(f'tracks/{track_idx}/keys = PackedFloat32Array({", ".join(str(v) for v in keys)})')

        lines.append('')
        track_idx += 1

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text('\n'.join(lines))
    return True


def batch_convert_animations(source_dir: Path, output_dir: Path) -> dict:
    """Tüm .anim dosyalarını toplu dönüştür."""
    stats = {'converted': 0, 'failed': 0, 'skipped': 0}
    anim_files = list(source_dir.rglob('*.anim'))

    for anim_path in anim_files:
        rel = anim_path.relative_to(source_dir)
        out_path = output_dir / rel.with_suffix('.tres')
        try:
            if convert_anim_to_tres(anim_path, out_path):
                stats['converted'] += 1
        except Exception as e:
            print(f'FAIL {anim_path}: {e}')
            stats['failed'] += 1

    return stats
```

- [ ] **Step 4: Testleri çalıştır, PASS bekliyoruz**

```bash
cd ~/agents/football-godot
python3 tools/test_anim_converter.py
# Beklenen: ALL TESTS PASSED
```

- [ ] **Step 5: Tüm animasyonları dönüştür ve sonucu doğrula**

```bash
python3 -c "
from pathlib import Path
from tools.anim_converter import batch_convert_animations
stats = batch_convert_animations(
    Path('$HOME/agents/football-gf/data/media/animations'),
    Path('$HOME/agents/football-godot/assets/animations')
)
print(stats)
# Beklenen: converted 290+, failed 0-5
"
ls ~/agents/football-godot/assets/animations/ | head -10
find ~/agents/football-godot/assets/animations -name "*.tres" | wc -l
```

- [ ] **Step 6: Commit**

```bash
cd ~/agents/football-godot
git init
git add tools/anim_converter.py tools/test_anim_converter.py
git commit -m "feat: .anim to Godot tres animation converter"
```

---

## Task 2: .object XML → Skeleton Tanımı Çıkarıcı

**Files:**
- Create: `tools/object_parser.py`
- Create: `tools/test_object_parser.py`

- [ ] **Step 1: Test yaz**

```python
# tools/test_object_parser.py
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from tools.object_parser import parse_object_file, SkeletonBone

def test_parse_player_object():
    path = os.path.expanduser(
        '~/agents/football-gf/data/media/objects/players/player.object'
    )
    skeleton = parse_object_file(path)
    # Temel kemikler mevcut olmalı
    bone_names = [b.name for b in skeleton]
    assert 'body' in bone_names
    assert 'neck' in bone_names
    assert 'left_thigh' in bone_names or 'left thigh' in bone_names
    # Her kemiğin parent'ı var mı kontrol et (kök hariç)
    for bone in skeleton[1:]:
        assert bone.parent is not None, f"{bone.name} parent yok"

def test_bone_positions():
    path = os.path.expanduser(
        '~/agents/football-gf/data/media/objects/players/player.object'
    )
    skeleton = parse_object_file(path)
    body = next(b for b in skeleton if b.name == 'body')
    assert body.position[2] > 0  # Z pozitif (yukarı)

if __name__ == '__main__':
    test_parse_player_object()
    test_bone_positions()
    print('ALL TESTS PASSED')
```

- [ ] **Step 2: Testi çalıştır, FAIL bekliyoruz**

```bash
python3 tools/test_object_parser.py
```

- [ ] **Step 3: Parser yaz**

```python
# tools/object_parser.py
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Tuple

@dataclass
class SkeletonBone:
    name: str
    position: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    rotation: Tuple[float, float, float, float] = (0.0, 0.0, 0.0, 0.0)
    mesh_file: Optional[str] = None
    parent: Optional[str] = None
    children: List[str] = field(default_factory=list)

def _parse_vec3(text: str) -> Tuple[float, float, float]:
    parts = [float(x.strip()) for x in text.split(',')]
    return (parts[0], parts[1], parts[2])

def _parse_vec4(text: str) -> Tuple[float, float, float, float]:
    parts = [float(x.strip()) for x in text.split(',')]
    return (parts[0], parts[1], parts[2], parts[3])

def _parse_node(node_elem, parent_name: Optional[str], bones: List[SkeletonBone]):
    name_elem = node_elem.find('name')
    if name_elem is None:
        return
    name = name_elem.text.strip()

    pos = (0.0, 0.0, 0.0)
    pos_elem = node_elem.find('position')
    if pos_elem is not None and pos_elem.text:
        pos = _parse_vec3(pos_elem.text)

    rot = (0.0, 0.0, 0.0, 0.0)
    rot_elem = node_elem.find('rotation')
    if rot_elem is not None and rot_elem.text:
        rot = _parse_vec4(rot_elem.text)

    mesh_file = None
    geom = node_elem.find('geometry')
    if geom is not None:
        fn = geom.find('filename')
        if fn is not None and fn.text:
            mesh_file = fn.text.strip()

    bone = SkeletonBone(
        name=name,
        position=pos,
        rotation=rot,
        mesh_file=mesh_file,
        parent=parent_name
    )
    bones.append(bone)

    if parent_name:
        parent = next((b for b in bones if b.name == parent_name), None)
        if parent:
            parent.children.append(name)

    for child_node in node_elem.findall('node'):
        _parse_node(child_node, name, bones)

def parse_object_file(path: str) -> List[SkeletonBone]:
    """XML .object dosyasını SkeletonBone listesine parse eder."""
    with open(path) as f:
        content = f.read()
    # XML'de loose text olabilir, temizle
    content = content.strip()
    if not content.startswith('<'):
        return []
    root = ET.fromstring(content)
    bones = []
    for node_elem in root.findall('node'):
        _parse_node(node_elem, None, bones)
    return bones

def export_skeleton_json(skeleton: List[SkeletonBone], output_path: str):
    """Skeleton'ı JSON'a yaz (Godot import için referans)."""
    import json
    data = []
    for bone in skeleton:
        data.append({
            'name': bone.name,
            'parent': bone.parent,
            'position': list(bone.position),
            'rotation': list(bone.rotation),
            'mesh_file': bone.mesh_file,
            'children': bone.children
        })
    with open(output_path, 'w') as f:
        json.dump(data, f, indent=2)
```

- [ ] **Step 4: Testleri çalıştır**

```bash
python3 tools/test_object_parser.py
# Beklenen: ALL TESTS PASSED
```

- [ ] **Step 5: Skeleton JSON export et ve doğrula**

```bash
python3 -c "
from tools.object_parser import parse_object_file, export_skeleton_json
import os
path = os.path.expanduser('~/agents/football-gf/data/media/objects/players/player.object')
skeleton = parse_object_file(path)
print(f'Toplam kemik: {len(skeleton)}')
for b in skeleton:
    indent = '  ' * (1 if b.parent else 0)
    print(f'{indent}{b.name} -> mesh: {b.mesh_file}')
export_skeleton_json(skeleton, 'assets/models/player_skeleton.json')
print('JSON yazildi: assets/models/player_skeleton.json')
"
```

- [ ] **Step 6: Commit**

```bash
git add tools/object_parser.py tools/test_object_parser.py assets/models/player_skeleton.json
git commit -m "feat: .object XML skeleton parser with JSON export"
```

---

## Task 3: .ase Mesh → GLTF Dönüşümü (Blender Headless)

**Files:**
- Create: `tools/ase_to_gltf.py` (Blender Python script)
- Create: `tools/run_ase_conversion.sh`

**Not:** Blender kurulu değilse bu task atlanır ve modeller Mixamo/Kenney'den temin edilir.

- [ ] **Step 1: Blender kurulumunu kontrol et**

```bash
blender --version 2>/dev/null || echo "Blender kurulu değil"
# Kurulu değilse:
wget -q "https://download.blender.org/release/Blender4.2/blender-4.2.0-linux-x64.tar.xz" \
  -O /tmp/blender.tar.xz
tar -xf /tmp/blender.tar.xz -C ~/bin/
mv ~/bin/blender-4.2.0-linux-x64 ~/bin/blender-4.2
ln -sf ~/bin/blender-4.2/blender ~/bin/blender
blender --version
```

- [ ] **Step 2: Blender ASE dönüşüm scripti yaz**

```python
# tools/ase_to_gltf.py
# Bu script Blender Python ortamında çalışır: blender --background --python ase_to_gltf.py -- <ase_dir> <out_dir>
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
```

- [ ] **Step 3: Dönüşümü çalıştır**

```bash
blender --background --python tools/ase_to_gltf.py -- \
  ~/agents/football-gf/data/media/objects \
  ~/agents/football-godot/assets/models
find ~/agents/football-godot/assets/models -name "*.glb" | wc -l
# Beklenen: 25+ GLB dosyası
```

- [ ] **Step 4: Blender yoksa Kenney placeholder kullan**

```bash
# Kenney football pack indir (CC0 lisanslı placeholder)
mkdir -p ~/agents/football-godot/assets/models/placeholder
wget -q "https://kenney.nl/assets/football-kit" -O /tmp/placeholder_note.txt || true
echo "Blender yoksa: manuel olarak https://kenney.nl/assets/football-kit indir" \
  > ~/agents/football-godot/assets/models/PLACEHOLDER_NOTE.md
```

- [ ] **Step 5: Commit**

```bash
git add tools/ase_to_gltf.py tools/run_ase_conversion.sh assets/models/
git commit -m "feat: ASE to GLTF conversion pipeline"
```

---

## Task 4: Dokümanlar ve Sesler Kopyala

**Files:**
- Create: `tools/copy_assets.sh`

- [ ] **Step 1: Kopyalama scripti yaz ve çalıştır**

```bash
# tools/copy_assets.sh
#!/bin/bash
set -e
SRC=~/agents/football-gf/data/media
DST=~/agents/football-godot/assets

# Dokular
cp -r "$SRC/textures/"* "$DST/textures/"
echo "Dokular kopyalandı: $(find $DST/textures -name '*.png' -o -name '*.jpg' | wc -l) dosya"

# Sesler
cp "$SRC/sounds/"*.wav "$DST/sounds/"
echo "Sesler kopyalandı: $(ls $DST/sounds/*.wav | wc -l) dosya"

# Veritabanı
mkdir -p "$DST/data"
cp ~/agents/football-gf/data/databases/default/database.sqlite "$DST/data/"
echo "Veritabanı kopyalandı"
```

```bash
chmod +x tools/copy_assets.sh
./tools/copy_assets.sh
```

- [ ] **Step 2: Doğrula**

```bash
echo "=== Dokular ===" && find assets/textures -name "*.png" -o -name "*.jpg" | wc -l
echo "=== Sesler ===" && ls assets/sounds/*.wav | wc -l
echo "=== DB ===" && ls -lh assets/data/database.sqlite
echo "=== Animasyonlar ===" && find assets/animations -name "*.tres" | wc -l
echo "=== Modeller ===" && find assets/models -name "*.glb" | wc -l
```

- [ ] **Step 3: Durum dosyasını güncelle**

```bash
cat > ~/agents/shared/status/football-01-asset-pipeline.md << 'EOF'
# Football Asset Pipeline Status
**Status:** done
**Progress:** 100%
**Tamamlanan:**
- .anim converter (293 animasyon -> .tres)
- .object XML parser (skeleton JSON)
- .ase -> GLTF (Blender ile veya placeholder)
- Dokular, sesler, DB kopyalandı
**Sonraki faz:** 02-gdextension-foundation
EOF
```

- [ ] **Step 4: Final commit**

```bash
cd ~/agents/football-godot
git add assets/ tools/copy_assets.sh
git commit -m "feat: complete asset pipeline - all GF assets converted"
```

---

## Doğrulama Kriterleri (Tamamlandı sayılma şartları)

```bash
# Tüm bu kontroller geçmeli:
python3 tools/test_anim_converter.py  # ALL TESTS PASSED
python3 tools/test_object_parser.py   # ALL TESTS PASSED
find assets/animations -name "*.tres" | wc -l  # 280+
find assets/textures -name "*.png" | wc -l      # 10+
ls assets/sounds/*.wav | wc -l                  # 6
ls assets/data/database.sqlite                  # mevcut
ls assets/models/player_skeleton.json           # mevcut
```

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

    type_match = re.search(r'<type>\s*(\w+)\s*</type>', content)
    if type_match:
        result['type'] = type_match.group(1)

    steps_match = re.search(r'<steps>\s*(\d+)\s*</steps>', content)
    if steps_match:
        result['steps'] = int(steps_match.group(1))

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
                    x = float(values[i]) if i < len(values) else 0.0
                    y = float(values[i+1]) if i+1 < len(values) else 0.0
                    z = float(values[i+2]) if i+2 < len(values) else 0.0
                    keyframes.append(AnimKeyframe(frame=frame, x=x, y=y, z=z))
                    i += 3
                    if i < len(values):
                        try:
                            int(values[i])
                        except ValueError:
                            i += 1
                else:
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
    """Tek .anim dosyasını Godot .tres Animation'a çevirir."""
    with open(anim_path) as f:
        content = f.read()

    data = parse_anim_file(content)
    anim_name = anim_path.stem

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

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

import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from tools.object_parser import parse_object_file, SkeletonBone

def test_parse_player_object():
    path = os.path.expanduser(
        '~/agents/football-gf/data/media/objects/players/player.object'
    )
    skeleton = parse_object_file(path)
    bone_names = [b.name for b in skeleton]
    assert 'body' in bone_names
    assert 'neck' in bone_names
    assert 'left_thigh' in bone_names or 'left thigh' in bone_names
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

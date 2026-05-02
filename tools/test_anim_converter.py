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

extends SceneTree

func _init():
    print("=== Match + Referee Test ===")
    
    var scene_p = load("res://scenes/StadiumScene.tscn")
    var scene = scene_p.instantiate()
    get_root().add_child(scene)
    
    var match_logic = scene.get_node("GFMatch")
    var referee = scene.get_node("GFReferee")
    var ball = scene.get_node("BallNode/GFBall")
    
    # Wait a few frames for ready
    for i in range(5):
        await process_frame

    ball.set_ball_position(Vector3(53, 0.11, 0))
    referee.step(0.016)
    
    print("Score check: ", match_logic.get_score_home())
    assert(match_logic.get_score_home() == 1, "Home score should be 1")
    print("PASS: Goal detected")
    
    ball.set_ball_position(Vector3(0, 0.11, 35))
    referee.step(0.016)
    print("PASS: Out of bounds check done")
    
    print("=== ALL MATCH + REFEREE TESTS PASSED ===")
    quit()

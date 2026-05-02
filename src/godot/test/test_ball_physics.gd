extends SceneTree

func _init():
    print("=== Ball Physics Test ===")
    
    var root = Node3D.new()
    get_root().add_child(root)
    
    var ball = GFBall.new()
    root.add_child(ball)
    
    assert(ball != null, "GFBall could not be instantiated")
    print("PASS: GFBall instantiated")
    
    var pos_start = ball.position
    ball.set_momentum(Vector3(10, 0, 0))
    ball.step(0.016)
    var pos_end = ball.position
    
    assert(pos_start != pos_end, "Ball did not move after step")
    print("PASS: Ball moved. Start: ", pos_start, " End: ", pos_end)
    
    # Test gravity
    ball.set_ball_position(Vector3(0, 10, 0))
    ball.set_momentum(Vector3(0, 0, 0))
    ball.step(0.1) 
    var pos_after_gravity = ball.position
    assert(pos_after_gravity.y < 10.0, "Gravity not working")
    print("PASS: Gravity working. Y after 0.1s: ", pos_after_gravity.y)
    
    # Test predictions
    var preds = ball.get_all_predictions()
    assert(preds.size() == 100, "Expected 100 predictions")
    print("PASS: Got 100 predictions")
    
    print("=== ALL BALL PHYSICS TESTS PASSED ===")
    quit()

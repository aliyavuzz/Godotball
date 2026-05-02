extends SceneTree

func _init():
    print("=== Player + AI Test ===")
    
    var root = Node3D.new()
    get_root().add_child(root)
    
    var player = GFPlayer.new()
    root.add_child(player)
    
    assert(player != null, "GFPlayer could not be instantiated")
    print("PASS: GFPlayer instantiated")
    
    player.position = Vector3(0, 0, 0)
    player.set_target_position(Vector3(10, 0, 10))
    
    # Need to wait for physics frames
    for i in range(20):
        await process_frame
        player.step(0.016)
        
    var end_pos = player.position
    print("End position: ", end_pos)
    assert(end_pos.length() > 0.1, "Player did not move toward target")
    print("PASS: Player moved. End position: ", end_pos)
    
    print("=== ALL PLAYER + AI TESTS PASSED ===")
    quit()

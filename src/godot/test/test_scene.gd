extends SceneTree

func _init():
	print("=== Scene Test ===")

	var scene = load("res://scenes/StadiumScene.tscn")
	assert(scene != null, "StadiumScene.tscn yuklenemedi")
	print("PASS: StadiumScene.tscn loaded")

	var instance = scene.instantiate()
	assert(instance != null, "StadiumScene instantiate basarisiz")
	print("PASS: StadiumScene instantiated")

	var players = instance.get_node("Players")
	assert(players != null, "Players node bulunamadi")
	assert(players.get_child_count() == 22, "22 oyuncu bekleniyor, " + str(players.get_child_count()) + " bulundu")
	print("PASS: 22 oyuncu node mevcut")

	var ball = instance.get_node("BallNode")
	assert(ball != null, "BallNode bulunamadi")
	print("PASS: BallNode mevcut")

	var gs = instance.get_node("GFGameState")
	assert(gs != null, "GFGameState bulunamadi")
	print("PASS: GFGameState node mevcut")

	var pitch = instance.get_node("Pitch")
	assert(pitch != null, "Pitch bulunamadi")
	print("PASS: Pitch mevcut")

	instance.free()
	print("=== ALL SCENE TESTS PASSED ===")
	quit()

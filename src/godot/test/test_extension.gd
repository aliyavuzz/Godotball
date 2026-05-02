extends SceneTree

func _init():
	print("=== GDExtension Test ===")

	var gs = GFGameState.new()
	assert(gs != null, "GFGameState olusturulamadi")
	print("PASS: GFGameState instantiated")

	gs.start_match()
	assert(gs.is_in_play(), "Mac baslamadi")
	print("PASS: start_match()")

	var ball = gs.get_ball_state()
	assert(ball.has("x"), "ball state x yok")
	assert(ball.has("y"), "ball state y yok")
	print("PASS: get_ball_state() = ", ball)

	var players = gs.get_players_state()
	assert(players.size() == 22, "22 oyuncu bekleniyor, " + str(players.size()) + " geldi")
	print("PASS: get_players_state() = 22 oyuncu")

	gs.step(0.016)
	print("PASS: step(0.016)")

	gs.stop_match()
	assert(!gs.is_in_play(), "Mac durdurulamadi")
	print("PASS: stop_match()")

	print("=== ALL TESTS PASSED ===")
	quit()

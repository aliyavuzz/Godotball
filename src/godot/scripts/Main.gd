extends Node3D

@onready var game_state: GFGameState = $GFGameState
@onready var match_logic: GFMatch = $GFMatch
@onready var referee: GFReferee = $GFReferee
@onready var team_home: GFTeam = $TeamHome
@onready var team_away: GFTeam = $TeamAway
@onready var ball_node = $BallNode
@onready var players_container = $Players

var player_nodes: Array = []

func _ready():
    referee.set_ball(ball_node.physics)
    referee.set_match(match_logic)

    for i in range(players_container.get_child_count()):
        var p = players_container.get_child(i)
        player_nodes.append(p)
        
        # Assign teams (first 11 home, next 11 away)
        if i < 11:
            p.set_team_id(0)
            team_home.add_player(p)
        else:
            p.set_team_id(1)
            team_away.add_player(p)
        
        p.set_player_id(i)
    
    # Connect signals
    referee.goal_scored.connect(_on_goal_scored)
    referee.ball_out.connect(_on_ball_out)
    match_logic.score_changed.connect(_on_score_changed)

    game_state.start_match()

func _physics_process(delta: float):
    game_state.step(delta)
    match_logic.step(delta)
    referee.step(delta)
    
    # AI: Simple "Follow the Ball" for all players
    var ball_pos = ball_node.physics.position
    for p in player_nodes:
        # Move players toward ball but keep some distance/spread
        var target = ball_pos
        p.set_target_position(target)
    
    team_home.step(delta)
    team_away.step(delta)

func _on_goal_scored(team: int):
    print("REFEREE: GOAL! Team ", team)
    ball_node.physics.set_ball_position(Vector3(0, 0.11, 0))
    ball_node.physics.set_momentum(Vector3(0, 0, 0))

func _on_ball_out(pos: Vector3):
    print("REFEREE: Ball out at ", pos)

func _on_score_changed(home: int, away: int):
    print("SCORE: ", home, " - ", away)

extends Node3D

@onready var physics: GFBall = $GFBall

func _ready():
    # Initial kick for testing
    physics.set_momentum(Vector3(5, 8, 2))

func _physics_process(delta):
    physics.step(delta)

func touch(force: Vector3):
    physics.touch(force)

func sync_from_state(_state: Dictionary):
    # Future: sync from global match state if needed
    pass

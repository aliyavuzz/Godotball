extends GFPlayer

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready():
    pass

func _physics_process(_delta):
    update_animations()

func update_animations():
    var vel = get_velocity()
    if vel.length() > 0.1:
        if anim_player.has_animation("gf/run"):
            anim_player.play("gf/run")
    else:
        if anim_player.has_animation("gf/idle"):
            anim_player.play("gf/idle")

func sync_from_state(_state: Dictionary):
    # Backward compatibility for old Main.gd calls if any
    pass

extends GFPlayer
##
## PlayerNode — Faz 2 (animasyon entegrasyonu)
##
## - X Bot mesh+iskelet'i child olarak instance edilir.
## - 17 ayrı GLB'den animasyonları runtime'da çıkarıp tek paylaşımlı AnimationLibrary
##   (static cache) içine toplar; 22 oyuncuda da aynı library reuse edilir.
## - Velocity büyüklüğüne göre idle/walk/jog/run state'lerini seçer.
## - Action animasyonları (kick/pass/tackle/header/receive) play_action() ile tetiklenir.
##
## Sonraki adım: AnimationTree + BlendSpace2D ile yön bazlı blend.
##

const ANIM_BASE := "res://characters/xbot/animations"

## Locomotion ve action animasyonları. Anahtar = library içindeki çağrı adı.
const ANIM_FILES := {
	# locomotion
	"idle":         "/locomotion/idle.glb",
	"walking":      "/locomotion/walking.glb",
	"jog_fwd":      "/locomotion/jog_forward.glb",
	"jog_bwd":      "/locomotion/jog_backward_diagonal.glb",
	"jog_left":     "/locomotion/jog_strafe_left.glb",
	"jog_right":    "/locomotion/jog_strafe_right.glb",
	"run_fwd":      "/locomotion/run_forward.glb",
	# ball actions
	"dribble":      "/ball_actions/dribble.glb",
	"pass":         "/ball_actions/pass.glb",
	"kick":         "/ball_actions/kick.glb",
	"kick_alt":     "/ball_actions/kick_alt.glb",
	"header":       "/ball_actions/header.glb",
	"receive":      "/ball_actions/receive.glb",
	"tackle":       "/ball_actions/tackle.glb",
	"tackle_slide": "/ball_actions/tackle_alt.glb",
	# extras
	"cheering":     "/celebration/cheering.glb",
	"goalie_idle":  "/goalkeeper/goalkeeper_idle.glb",
}

const LOOPING_ANIMS := [
	"idle", "walking", "jog_fwd", "jog_bwd", "jog_left", "jog_right",
	"run_fwd", "dribble", "goalie_idle"
]

## Hız eşiği eşik değerleri (m/s). GF'in idle/dribble/walk/sprint quadrant'larına benzer.
const SPEED_WALK := 0.3
const SPEED_JOG  := 4.5
const SPEED_RUN  := 7.0

# Tüm oyuncular tek bir AnimationLibrary instance'ını paylaşır (22 player × 50MB önler).
static var _shared_library: AnimationLibrary = null

var xbot: Node3D
var anim_player: AnimationPlayer
var _action_locked := false
var _current_state := ""


func _ready() -> void:
	xbot = get_node_or_null("XBot")
	if xbot == null:
		push_error("PlayerNode: XBot child node not found")
		return
	anim_player = xbot.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		push_error("PlayerNode: XBot/AnimationPlayer not found")
		return

	_load_animation_library(anim_player)

	# Mixamo karakterleri model-space içinde +Z'ye bakar.
	# Godot Node3D::look_at() -Z eksenini hedefe çevirir. Mismatch'i kapatmak için
	# X Bot child'ını 180° Y ekseninde döndürüyoruz.
	xbot.rotation.y = PI

	_play_state("idle")


func _physics_process(_delta: float) -> void:
	if _action_locked:
		return
	_update_locomotion()


# ─────────────────────────────────────────────────────────────────────────
# Animation library yükleme (paylaşımlı cache)
# ─────────────────────────────────────────────────────────────────────────

func _load_animation_library(target: AnimationPlayer) -> void:
	if _shared_library == null:
		_shared_library = _build_library()
	if not target.has_animation_library("xbot"):
		target.add_animation_library("xbot", _shared_library)


static func _build_library() -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	for key in ANIM_FILES.keys():
		var anim := _extract_animation(ANIM_BASE + ANIM_FILES[key])
		if anim:
			if key in LOOPING_ANIMS:
				anim.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation(key, anim)
		else:
			push_warning("PlayerNode: animation '%s' yüklenemedi (%s)" % [key, ANIM_FILES[key]])
	return lib


# Bir GLB dosyasından gerçek animasyonu çıkarır.
# FBX2glTF her GLB'ye iki anim koyar: "Take 001" (boş) ve "mixamo.com" (asıl).
static func _extract_animation(glb_path: String) -> Animation:
	if not ResourceLoader.exists(glb_path):
		push_warning("PlayerNode: GLB bulunamadı: " + glb_path)
		return null
	var packed := load(glb_path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	var ap := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var picked: Animation = null
	if ap:
		for nm in ap.get_animation_list():
			if nm in ["RESET", "Take 001"]:
				continue
			var anim := ap.get_animation(nm)
			if anim and anim.length > 0.1:
				picked = anim.duplicate(true) as Animation
				break
	instance.queue_free()
	return picked


# ─────────────────────────────────────────────────────────────────────────
# State seçimi
# ─────────────────────────────────────────────────────────────────────────

func _update_locomotion() -> void:
	var v := get_velocity()
	var speed := Vector2(v.x, v.z).length()
	var target_state := "idle"
	if speed > SPEED_RUN:
		target_state = "run_fwd"
	elif speed > SPEED_JOG:
		target_state = "jog_fwd"
	elif speed > SPEED_WALK:
		target_state = "walking"
	_play_state(target_state)


func _play_state(state: String) -> void:
	if state == _current_state:
		return
	_current_state = state
	if anim_player:
		anim_player.play("xbot/" + state, 0.18)


# ─────────────────────────────────────────────────────────────────────────
# Action API (top etkileşimi)
# ─────────────────────────────────────────────────────────────────────────

## Kick/pass/tackle gibi tek seferlik aksiyonları oynat. Bittiğinde locomotion'a döner.
func play_action(action: String) -> void:
	if anim_player == null:
		return
	var full := "xbot/" + action
	if not anim_player.has_animation(full):
		push_warning("Action yok: " + full)
		return
	_action_locked = true
	anim_player.play(full, 0.10)
	if not anim_player.animation_finished.is_connected(_on_action_finished):
		anim_player.animation_finished.connect(_on_action_finished, CONNECT_ONE_SHOT)


func _on_action_finished(_name: StringName) -> void:
	_action_locked = false
	_current_state = "" # _update_locomotion'ı tekrar tetikler


# ─────────────────────────────────────────────────────────────────────────

func sync_from_state(_state: Dictionary) -> void:
	pass

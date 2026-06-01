extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

const ANIM_IDLE    = "mixamo_com"
const ANIM_WALK    = "Walking/mixamo_com"
const ANIM_RUN     = "Running/mixamo_com"
const ANIM_VICTORY = "Victory Idle/mixamo_com"

var current_anim := ""

func _ready():
	_play_anim(ANIM_IDLE)

func trigger_victory():
	_play_anim(ANIM_VICTORY)

func _play_anim(anim_name: String) -> void:
	if current_anim == anim_name:
		return
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		current_anim = anim_name
	else:
		push_warning("Animation not found: " + anim_name)

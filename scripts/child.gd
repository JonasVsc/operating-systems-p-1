extends Node2D

var data: Dictionary
@onready var _id_label: Label = $Label  # id gerado automaticamente

var _last_anim = ""
@onready var _anim = $Animation

@onready var _soccer_ball = $SoccerBall

@onready var _sleeping = $Sleeping


func _ready() -> void:
	_id_label.text = "%d" % data["id"] 
	# Fade-in: começa invisível e vai para opaco em 0.8s
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)\
		 .set_ease(Tween.EASE_OUT)\
		 .set_trans(Tween.TRANS_QUAD)


func _process(_delta):
	if data.is_empty():
		return
		
	Simulation.ui_mutex.lock()
	var px: float      = data["px"]
	var py: float      = data["py"]
	Simulation.ui_mutex.unlock()
	
	position = Vector2(px, py);
	
	var status: String = data["status"]
	
	if status == "BRINCANDO" || status == "BLOQUEADO_AGUARDANDO_CESTO" || status == "AG_ESPACO":
		_soccer_ball.visible = true
	else:
		_soccer_ball.visible = false
		
	if status == "BLOQUEADO_AGUARDANDO_BOLA" || status == "BLOQUEADO_AGUARDANDO_CESTO":
		_sleeping.visible = true
	else:
		_sleeping.visible = false

	var target_anim: String
	match status:
		"BRINCANDO":
			target_anim = "running"
		"DESCANSANDO":
			target_anim = "idle"
		"AG_ESPACO":
			target_anim = "running_left" 
		"AG_CESTO":
			target_anim = "running_right"
		"BLOQUEADO_AGUARDANDO_CESTO":
			target_anim = "RESET"
		"BLOQUEADO_AGUARDANDO_BOLA":
			target_anim = "RESET"

	if target_anim != _last_anim:
		_anim.play(target_anim)
		_last_anim = target_anim

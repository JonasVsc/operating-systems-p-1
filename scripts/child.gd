extends Node2D

var data: Dictionary

func _ready() -> void:
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

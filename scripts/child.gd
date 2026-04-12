extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var label  = $Label

var sim_data: Dictionary
var target_pos: Vector2

const ANIM_MAP = {
	"BRINCANDO":  "play",
	"AG_CESTO":   "wait",
	"AG_ESPACO":  "wait",
	"DESCANSANDO": "rest",
	"IDLE":       "idle"
}

const TARGET_MAP = {
	"BRINCANDO":   Vector2(400, 300),  # campo aberto — randomize
	"AG_CESTO":    Vector2(600, 300),  # fila no cesto
	"AG_ESPACO":   Vector2(620, 340),
	"DESCANSANDO": Vector2(50,  450),  # banco de reservas
}

func _process(delta):
	if sim_data.is_empty(): return

	# Lê status de forma thread-safe
	var status: String
	Simulation.ui_mutex.lock()
	status = sim_data.status
	Simulation.ui_mutex.unlock()

	# Atualiza animação
	var anim = ANIM_MAP.get(status, "idle")
	if sprite.animation != anim:
		sprite.play(anim)

	# Flip horizontal ao mover para esquerda
	var t = TARGET_MAP.get(status, position + Vector2(randf_range(-50,50), 0))
	if status == "BRINCANDO":
		t = _random_wander()

	sprite.flip_h = (t.x < position.x)

	# Steering seek simples
	position = position.move_toward(t, 80 * delta)

	# Sombra (desenhada no _draw do parent)
	label.text = sim_data.name
	
	
func _random_wander() -> Vector2:
	# Muda alvo aleatório a cada ~2s
	if not has_meta("wander_timer"):
		set_meta("wander_timer", 0.0)
		set_meta("wander_target", position)
	var t = get_meta("wander_timer") + get_process_delta_time()
	set_meta("wander_timer", t)
	if t > 2.0:
		set_meta("wander_timer", 0.0)
		set_meta("wander_target", Vector2(
			randf_range(100, 700), randf_range(150, 400)
		))
	return get_meta("wander_target")

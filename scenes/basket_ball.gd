extends AnimatedSprite2D

@onready var count_label: Label = $CountLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Simulation or not Simulation.available_balls_semaphore:
		return

	Simulation.ui_mutex.lock()
	var current: int  = Simulation.basket_count
	var capacity: int = Simulation.basket_capacity
	Simulation.ui_mutex.unlock()

	var fill_ratio: float = float(current) / float(max(capacity, 1))
	frame = clamp(int(fill_ratio * 5), 0, 4)

	count_label.text = "%d / %d" % [current, capacity]

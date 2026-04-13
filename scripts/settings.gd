extends Control

@onready var available_balls_input = $CenterContainer/VBoxContainer/HBallsContainer/BallsInput
@onready var basket_capacity_input = $CenterContainer/VBoxContainer/HBasketContainer/BasketInput

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if available_balls_input.value > basket_capacity_input.value:
		basket_capacity_input.value = available_balls_input.value;
	
func _on_start_button_pressed() -> void:
	Simulation.initialize(basket_capacity_input.value, available_balls_input.value);
	get_tree().change_scene_to_file("res://scenes/main.tscn");

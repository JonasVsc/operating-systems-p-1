extends Window

@onready var child_name_input = $PanelContainer/VBoxContainer/FormContainer/ChildName/ChildNameInput
@onready var child_tb_input = $PanelContainer/VBoxContainer/FormContainer/ChildTb/ChildTbInput
@onready var child_td_input = $PanelContainer/VBoxContainer/FormContainer/ChildTd/ChildTdInput
@onready var child_has_ball_input = $PanelContainer/VBoxContainer/FormContainer/ChildHasBall/ChildHasBallCheckbox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_cancel_button_pressed() -> void:
	self.visible = false;


func _on_submit_button_pressed() -> void:
	
	var child_name = child_name_input.text;
	var child_tb = child_tb_input.value * 1000;
	var child_td = child_td_input.value * 1000;
	var child_has_ball = child_has_ball_input.button_pressed;
	
	Simulation.create_child(child_name, child_has_ball, child_tb, child_td);
	
	self.visible = false;

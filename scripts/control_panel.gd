extends Window

@onready var child_form = $ChildForm;
@onready var child_quantity_label = $PanelContainer/VBoxContainer/ChildQuantityLabel;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Simulation.new_children.connect(_on_new_children);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_create_child_button_pressed() -> void:
	child_form.visible = true


func _on_new_children(child_id: int):
	child_quantity_label.text = "Child: %d" % [child_id];

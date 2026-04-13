extends Window

@onready var label = $PanelContainer/ScrollContainer/VBoxContainer/RichTextLabel
@onready var scroll = $PanelContainer/ScrollContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SimLogger.new_log.connect(_on_receive_new_log);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_receive_new_log(text: String):
	label.append_text(text + "\n");
	await get_tree().process_frame;
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value;
	
	pass

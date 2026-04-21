extends Node

signal new_log(msg);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func log(msg: String):
	var time = Time.get_time_dict_from_system();
	var timestamp = "[%02d:%02d:%02d]" % [time.hour, time.minute, time.second];
	var display_msg = timestamp + " " + msg;
	new_log.emit.call_deferred(display_msg);
	pass
